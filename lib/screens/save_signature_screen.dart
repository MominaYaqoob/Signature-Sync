import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/signature_model.dart';
import '../services/ads_service.dart';
import '../services/signature_image_store.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_visual.dart';

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
  bool _saving = false;
  bool _saved = false;
  bool _makeDefault = false;
  String? _pendingImagePath;

  static const _nameSuggestions = [
    'My signature',
    'Initials',
    'Work',
    'Personal',
  ];

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
    if (combined.contains('generat')) return SignatureStyle.generated;
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

  Color? get _inkColor {
    final value = int.tryParse(_readData()['ink'] ?? '');
    return value == null ? null : Color(value);
  }

  /// Leaving without saving: drop the PNG the draw/scan screen wrote for us.
  void _discardUnsavedImage() {
    if (_saved) return;
    StorageService.deleteSignatureFile(_pendingImagePath);
  }

  String _styleDisplay(SignatureStyle style) => switch (style) {
        SignatureStyle.drawn => 'Hand-drawn',
        SignatureStyle.scanned => 'Scanned from paper',
        SignatureStyle.generated => 'Generated autograph',
        SignatureStyle.uploaded => 'Uploaded image',
        SignatureStyle.typed => 'Typed',
      };

  IconData _styleIcon(SignatureStyle style) => switch (style) {
        SignatureStyle.drawn => Icons.draw_rounded,
        SignatureStyle.scanned => Icons.document_scanner_outlined,
        SignatureStyle.generated => Icons.auto_fix_high_rounded,
        SignatureStyle.uploaded => Icons.image_outlined,
        SignatureStyle.typed => Icons.text_fields_rounded,
      };

  void _showError(String message) {
    if (!mounted) return;
    debugPrint('[SaveSignature] ERROR: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final data = _readData();
    debugPrint('[SaveSignature] save started data=$data');

    if (!_hasValidPayload(data)) {
      _showError('Nothing to save — go back and create a signature');
      return;
    }

    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty ? _defaultLabel() : typedName;

    final imagePathRaw = data['imagePath'] ?? '';
    final imagePath = imagePathRaw.isEmpty ? null : imagePathRaw;
    if (imagePath != null && !SignatureImageStore.exists(imagePath)) {
      _showError('Signature image is missing — go back and try again');
      return;
    }

    final idRaw = data['id'] ?? '';
    final id = idRaw.isNotEmpty
        ? idRaw
        : 'sig_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _saving = true);
    try {
      final isFirst = StorageService.getAllSignatures().isEmpty;
      final style = _parseStyle(data);
      final isTyped = style == SignatureStyle.typed;
      final signatureText = (data['name'] ?? '').trim();
      final signature = SignatureModel(
        id: id,
        name: name,
        style: style,
        createdAt: DateTime.now(),
        isDefault: isFirst,
        imagePath: imagePath,
        signatureText:
            isTyped && signatureText.isNotEmpty ? signatureText : null,
        fontLabel: isTyped ? data['style'] : null,
        inkColor: isTyped ? int.tryParse(data['ink'] ?? '') : null,
      );
      debugPrint(
        '[SaveSignature] writing Hive id=$id name=$name '
        'style=${signature.style} imagePath=$imagePath',
      );
      await StorageService.saveSignature(signature);
      if (_makeDefault && !isFirst) {
        await StorageService.setDefaultSignature(id);
      }
      _saved = true;
      debugPrint('[SaveSignature] Hive write confirmed');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“$name” saved')),
      );
      debugPrint('[SaveSignature] navigating to /signatures');
      // Save is the "done with this feature" point for Draw/Scan/Auto/
      // Generate alike — the one ad plan placement that covers all four.
      AdsService.instance.showInterstitial(
        onComplete: () {
          if (context.mounted) context.go('/signatures');
        },
      );
    } catch (e, st) {
      debugPrint('[SaveSignature] save failed: $e\n$st');
      _showError('Could not save signature: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _readData();
    final style = _parseStyle(data);
    final fontLabel = data['style'];

    final imagePath = data['imagePath'] ?? '';
    final hasImagePath = imagePath.isNotEmpty;
    final hasImageFile = hasImagePath && SignatureImageStore.exists(imagePath);
    _pendingImagePath = imagePath;

    // Auto/template cursive preview uses the incoming signature name, not the label field.
    final previewName = () {
      final fromData = (data['name'] ?? '').trim();
      if (fromData.isNotEmpty) return fromData;
      final fromField = _nameController.text.trim();
      return fromField.isEmpty ? 'Your name' : fromField;
    }();

    // The first signature always becomes default, so the toggle is locked on.
    final isFirst = StorageService.getAllSignatures().isEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _discardUnsavedImage();
      },
      child: Scaffold(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPreview(
                          hasImagePath: hasImagePath,
                          hasImageFile: hasImageFile,
                          imagePath: imagePath,
                          previewName: previewName,
                          fontLabel: fontLabel,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(child: _buildTypeChip(style, fontLabel)),
                        const SizedBox(height: 22),
                        Text(
                          'Signature name',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.bodyLarge,
                          cursorColor: AppColors.accentPurple,
                          maxLength: 30,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: _defaultLabel(),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final suggestion in _nameSuggestions)
                              _SuggestionChip(
                                label: suggestion,
                                selected:
                                    _nameController.text.trim() == suggestion,
                                onTap: () => setState(() {
                                  _nameController.text = suggestion;
                                  _nameController.selection =
                                      TextSelection.collapsed(
                                    offset: suggestion.length,
                                  );
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDefaultToggle(isFirst),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: PressableScale(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: DecoratedBox(
                      decoration: AppDecorations.purpleButton(
                        radius: AppRadii.sm,
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.textOnAccent,
                                ),
                              )
                            : Text(
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
      ),
    );
  }

  Widget _buildPreview({
    required bool hasImagePath,
    required bool hasImageFile,
    required String imagePath,
    required String previewName,
    required String? fontLabel,
  }) {
    Widget child;
    if (hasImageFile) {
      child = SignatureImageStore.image(
        imagePath,
        errorBuilder:(context, error, stackTrace) {
          debugPrint('[SaveSignature] Image.file error: $error');
          return _previewMessage('Could not load signature image');
        },
      );
    } else if (hasImagePath) {
      child = _previewMessage(
        'Signature image not found — go back and try again',
      );
    } else {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          previewName,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: signatureFontStyle(
            fontLabel,
            fontSize: 40,
            color: _inkColor ?? AppColors.accentBlue,
          ),
        ),
      );
    }

    // White "paper" so the preview matches how it will look on a document.
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        prominent: true,
        color: Colors.white,
        borderColor: AppColors.divider,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  Widget _previewMessage(String message) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildTypeChip(SignatureStyle style, String? fontLabel) {
    final isTyped = style == SignatureStyle.typed;
    final font = (fontLabel ?? '').trim();
    final label = isTyped && font.isNotEmpty
        ? '${_styleDisplay(style)} · $font'
        : _styleDisplay(style);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_styleIcon(style), size: 14, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultToggle(bool isFirst) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, 8, 6),
      decoration: AppDecorations.card(
        radius: AppRadii.sm,
        elevated: false,
        sheen: false,
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accentBlue, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as default',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isFirst
                      ? 'Your first signature is used by default'
                      : 'Use this signature first when signing',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isFirst || _makeDefault,
            activeTrackColor: AppColors.accentBlue,
            onChanged: isFirst
                ? null
                : (value) => setState(() => _makeDefault = value),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPurple.withValues(alpha: 0.12)
              : AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accentPurple : AppColors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.accentPurpleDark : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
