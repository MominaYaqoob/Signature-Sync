import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_visual.dart';

class SignatureDetailScreen extends StatefulWidget {
  const SignatureDetailScreen({
    super.key,
    required this.signature,
  });

  final SignatureModel signature;

  @override
  State<SignatureDetailScreen> createState() => _SignatureDetailScreenState();
}

class _SignatureDetailScreenState extends State<SignatureDetailScreen> {
  late SignatureModel _signature;

  @override
  void initState() {
    super.initState();
    _signature = widget.signature;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _signature.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          title: Text(
            'Rename signature',
            style: AppTextStyles.titleMedium,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(hintText: 'Signature name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.secondary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(
                'Save',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    final updated = _signature.copyWith(name: result);
    await StorageService.saveSignature(updated);
    if (!mounted) return;
    setState(() => _signature = updated);
  }

  Future<void> _setDefault() async {
    await StorageService.setDefaultSignature(_signature.id);
    final updated = StorageService.getSignatureById(_signature.id);
    if (!mounted) return;
    if (updated != null) setState(() => _signature = updated);
    _toast('Set as default');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          title: Text(
            'Delete signature?',
            style: AppTextStyles.titleMedium,
          ),
          content: Text(
            'Remove “${_signature.name}” from this device. This can’t be undone.',
            style: AppTextStyles.secondary.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.secondary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await StorageService.deleteSignature(_signature.id);
    if (!mounted) return;
    _toast('Signature deleted');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                title: 'Signature',
                onBack: () => context.pop(),
                fontSize: 18,
                trailing: _signature.isDefault
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Default',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppDecorations.card(
                    radius: AppRadii.lg,
                    prominent: true,
                    color: AppColors.softBlue,
                    borderColor: AppColors.accentBlue.withValues(alpha: 0.22),
                  ),
                  child: Center(
                    child: SignatureVisual.fromModel(
                      _signature,
                      color: AppColors.accentBlue,
                      fontSize: 56,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _signature.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${_signature.styleLabel} signature',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary,
              ),
              const SizedBox(height: 24),
              _ActionRow(
                icon: Icons.edit_outlined,
                label: 'Rename',
                color: AppColors.accentPurple,
                onTap: _rename,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionRow(
                icon: Icons.star_outline_rounded,
                label: 'Set as default',
                          color: AppColors.accentBlue,
                onTap: _setDefault,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.danger,
                onTap: _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          radius: AppRadii.md,
          borderColor: color.withValues(alpha: 0.18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
