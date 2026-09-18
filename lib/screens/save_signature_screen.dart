import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

class SaveSignatureScreen extends StatefulWidget {
  const SaveSignatureScreen({
    super.key,
    this.initialName,
    this.styleLabel,
    this.source,
    this.imagePath,
    this.id,
  });

  final String? initialName;
  final String? styleLabel;
  final String? source;
  final String? imagePath;
  final String? id;

  @override
  State<SaveSignatureScreen> createState() => _SaveSignatureScreenState();
}

class _SaveSignatureScreenState extends State<SaveSignatureScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Label field starts empty (or with a pre-filled label if one was passed).
    // Auto/template "name" is signature text for the preview, not the label.
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, String> _readData() {
    final data = GoRouterState.of(context).extra as Map<String, String>? ?? {};
    if (data.isNotEmpty) return data;

    // Fallback if extras were only forwarded via constructor.
    return <String, String>{
      if (widget.initialName != null) 'name': widget.initialName!,
      if (widget.styleLabel != null) 'style': widget.styleLabel!,
      if (widget.source != null) 'source': widget.source!,
      if (widget.imagePath != null) 'imagePath': widget.imagePath!,
      if (widget.id != null) 'id': widget.id!,
    };
  }

  SignatureStyle _parseStyle(Map<String, String> data) {
    final style = (data['style'] ?? '').toLowerCase();
    final source = (data['source'] ?? '').toLowerCase();
    final combined = '$style $source';

    if (combined.contains('scan')) return SignatureStyle.scanned;
    if (combined.contains('upload')) return SignatureStyle.uploaded;
    if (combined.contains('type') ||
        combined.contains('auto') ||
        combined.contains('template')) {
      return SignatureStyle.typed;
    }
    if (combined.contains('drawn') || combined.contains('draw')) {
      return SignatureStyle.drawn;
    }
    // Fancy template/auto style labels without an explicit source still count as typed.
    if (style.isNotEmpty &&
        style != 'drawn' &&
        style != 'scanned' &&
        style != 'uploaded') {
      return SignatureStyle.typed;
    }
    return SignatureStyle.drawn;
  }

  bool _hasValidPayload(Map<String, String> data) {
    final imagePath = data['imagePath'] ?? '';
    if (imagePath.isNotEmpty) return true;

    final name = data['name'] ?? '';
    final style = data['style'] ?? '';
    final source = data['source'] ?? '';
    return name.isNotEmpty || style.isNotEmpty || source.isNotEmpty;
  }

  String _defaultLabel() {
    final count = StorageService.getAllSignatures().length + 1;
    return 'Signature $count';
  }

  Future<void> _save() async {
    final data = _readData();

    if (!_hasValidPayload(data)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save — go back and create a signature')),
      );
      return;
    }

    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty ? _defaultLabel() : typedName;

    final imagePathRaw = data['imagePath'] ?? '';
    final imagePath = imagePathRaw.isEmpty ? null : imagePathRaw;

    final idRaw = data['id'] ?? '';
    final id = idRaw.isNotEmpty
        ? idRaw
        : 'sig_${DateTime.now().millisecondsSinceEpoch}';

    final existing = StorageService.getAllSignatures();
    final signature = SignatureModel(
      id: id,
      name: name,
      style: _parseStyle(data),
      createdAt: DateTime.now(),
      isDefault: existing.isEmpty,
      imagePath: imagePath,
    );
    await StorageService.saveSignature(signature);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$name” saved')),
    );
    context.go('/signatures');
  }

  @override
  Widget build(BuildContext context) {
    final data = _readData();
    final style = data['style']?.isNotEmpty == true
        ? data['style']!
        : (widget.styleLabel ?? 'Custom');
    final source = data['source']?.isNotEmpty == true
        ? data['source']!
        : (widget.source ?? 'drawn');

    final imagePath = data['imagePath'] ?? '';
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    // Auto/template cursive preview uses the incoming signature name, not the label field.
    final previewName = () {
      final fromData = (data['name'] ?? '').trim();
      if (fromData.isNotEmpty) return fromData;
      final fromField = _nameController.text.trim();
      return fromField.isEmpty ? 'Your name' : fromField;
    }();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'Save Signature',
                onBack: () => context.pop(),
                fontSize: 18,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 140,
                padding: AppSpacing.cardPadding,
                decoration: AppDecorations.card(
                  radius: AppRadii.md,
                  prominent: true,
                  color: AppColors.softBlue,
                  borderColor: AppColors.accentBlue.withValues(alpha: 0.22),
                ),
                child: Center(
                  child: hasImage
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        )
                      : Text(
                          previewName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.signaturePreview(
                            color: AppColors.accentBlue,
                            size: 36,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$style · $source',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 22),
              Text(
                'Signature name',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.accentPurple,
                decoration: const InputDecoration(
                  hintText: 'e.g. Work signature',
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: PressableScale(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: DecoratedBox(
                    decoration: AppDecorations.purpleButton(
                      radius: AppRadii.sm,
                    ),
                    child: Center(
                      child: Text(
                        'Save Signature',
                        style: AppTextStyles.onAccentLabel.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
