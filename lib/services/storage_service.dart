import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';
import 'signature_image_store.dart';

/// Local Hive persistence for signatures and documents (no backend).
class StorageService {
  StorageService._();

  static const _signaturesBoxName = 'signatures';
  static const _documentsBoxName = 'documents';
  static const _settingsBoxName = 'settings';
  static const _onboardingCompleteKey = 'onboarding_complete';

  /// Bump this when the Privacy Policy / agree-screen terms change in a way
  /// that needs fresh consent — existing users will see the Agree screen
  /// once more on their next launch (an app update alone never triggers
  /// this; only a version bump here does).
  static const currentPolicyVersion = 1;

  static late Box<SignatureModel> _signatures;
  static late Box<DocumentModel> _documents;
  static late Box _settings;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SignatureModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DocumentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SignatureStyleAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DocumentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(DocumentFileTypeAdapter());
    }

    _signatures = await Hive.openBox<SignatureModel>(_signaturesBoxName);
    _documents = await Hive.openBox<DocumentModel>(_documentsBoxName);
    _settings = await Hive.openBox(_settingsBoxName);
  }

  // ── App settings ────────────────────────────────────────────────────────

  /// Whether onboarding + the agree-to-terms step has been completed for
  /// the *current* [currentPolicyVersion]. New installs and reinstalls
  /// start with nothing stored (Android wipes app data on uninstall), so
  /// both read as "not agreed" the same as a fresh install.
  static bool get hasCompletedOnboarding {
    final stored = _settings.get(_onboardingCompleteKey);
    if (stored is int) return stored >= currentPolicyVersion;
    return false;
  }

  static Future<void> setOnboardingComplete() =>
      _settings.put(_onboardingCompleteKey, currentPolicyVersion);

  // ── Signatures ──────────────────────────────────────────────────────────

  static List<SignatureModel> getAllSignatures() {
    final list = _signatures.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> saveSignature(SignatureModel signature) async {
    await _signatures.put(signature.id, signature);
  }

  /// Notifies listeners whenever a signature is added, changed or removed.
  static ValueListenable<Box<SignatureModel>> get signaturesListenable =>
      _signatures.listenable();

  /// Removes the record; pass [keepFile] when the delete may still be undone.
  static Future<void> deleteSignature(String id, {bool keepFile = false}) async {
    final removed = _signatures.get(id);
    await _signatures.delete(id);
    if (!keepFile) await deleteSignatureFile(removed?.imagePath);
    if (removed?.isDefault ?? false) {
      final remaining = getAllSignatures();
      if (remaining.isNotEmpty) {
        await setDefaultSignature(remaining.first.id);
      }
    }
  }

  /// Puts back a signature removed with `keepFile: true` (undo).
  static Future<void> restoreSignature(SignatureModel signature) async {
    await _signatures.put(signature.id, signature);
    if (signature.isDefault) await setDefaultSignature(signature.id);
  }

  /// Deletes a signature PNG unless a saved signature still points at it.
  static Future<void> deleteSignatureFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final inUse = _signatures.values.any((s) => s.imagePath == path);
    if (inUse) return;
    await SignatureImageStore.delete(path);
  }

  static Future<void> setDefaultSignature(String id) async {
    for (final sig in _signatures.values) {
      final shouldBeDefault = sig.id == id;
      if (sig.isDefault != shouldBeDefault) {
        await _signatures.put(
          sig.id,
          sig.copyWith(isDefault: shouldBeDefault),
        );
      }
    }
  }

  static SignatureModel? getDefaultSignature() {
    for (final sig in _signatures.values) {
      if (sig.isDefault) return sig;
    }
    final all = getAllSignatures();
    return all.isEmpty ? null : all.first;
  }

  static SignatureModel? getSignatureById(String id) => _signatures.get(id);

  // ── Documents ───────────────────────────────────────────────────────────

  static List<DocumentModel> getAllDocuments() {
    final list = _documents.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static Future<void> saveDocument(DocumentModel document) async {
    await _documents.put(document.id, document);
  }

  static Future<void> deleteDocument(String id) async {
    final removed = _documents.get(id);
    await _documents.delete(id);
    await _deleteDocumentFileIfUnused(removed?.filePath);
  }

  static DocumentModel? getDocumentById(String id) => _documents.get(id);

  /// Notifies listeners whenever a document is added, changed or removed.
  static ValueListenable<Box<DocumentModel>> get documentsListenable =>
      _documents.listenable();

  static Future<void> _deleteDocumentFileIfUnused(String? path) async {
    if (path == null || path.isEmpty) return;
    final inUse = _documents.values.any((d) => d.filePath == path);
    if (inUse) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort — a leftover file is harmless.
    }
  }

  /// Clears all local signatures and documents (Settings → Clear data),
  /// including the PNG/PDF files on disk — not just the Hive records.
  static Future<void> clearAll() async {
    await _signatures.clear();
    await _documents.clear();
    await _deleteAppFolder('signatures');
    await _deleteAppFolder('signed');
    await _deleteAppFolder('documents');
  }

  static Future<void> _deleteAppFolder(String name) async {
    if (kIsWeb) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$name');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best effort — leftover files are harmless, just wasted space.
    }
  }
}
