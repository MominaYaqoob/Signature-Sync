import 'package:hive_flutter/hive_flutter.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';

/// Local Hive persistence for signatures and documents (no backend).
class StorageService {
  StorageService._();

  static const _signaturesBoxName = 'signatures';
  static const _documentsBoxName = 'documents';

  static late Box<SignatureModel> _signatures;
  static late Box<DocumentModel> _documents;

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
  }

  // ── Signatures ──────────────────────────────────────────────────────────

  static List<SignatureModel> getAllSignatures() {
    final list = _signatures.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> saveSignature(SignatureModel signature) async {
    await _signatures.put(signature.id, signature);
  }

  static Future<void> deleteSignature(String id) async {
    final wasDefault = _signatures.get(id)?.isDefault ?? false;
    await _signatures.delete(id);
    if (wasDefault) {
      final remaining = getAllSignatures();
      if (remaining.isNotEmpty) {
        await setDefaultSignature(remaining.first.id);
      }
    }
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
    await _documents.delete(id);
  }

  static DocumentModel? getDocumentById(String id) => _documents.get(id);

  /// Clears all local signatures and documents (Settings → Clear data).
  static Future<void> clearAll() async {
    await _signatures.clear();
    await _documents.clear();
  }
}
