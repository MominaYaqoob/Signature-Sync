import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../widgets/pressable_scale.dart';

class SaveSignatureScreen extends StatefulWidget {
  const SaveSignatureScreen({
    super.key,
    this.initialName,
    this.styleLabel,
    this.source,
  });

  final String? initialName;
  final String? styleLabel;
  final String? source;

  @override
  State<SaveSignatureScreen> createState() => _SaveSignatureScreenState();
}

class _SaveSignatureScreenState extends State<SaveSignatureScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? 'Momina Yaqoob',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a signature name')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“$name” saved')),
    );
    context.go('/signatures');
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.styleLabel ?? 'Custom';
    final source = widget.source ?? 'drawn';

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
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Save Signature',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 140,
                padding: AppSpacing.cardPadding,
                decoration: AppDecorations.card(
                  radius: AppRadii.md,
                  prominent: true,
                  color: AppColors.softPink,
                  borderColor: AppColors.accentPink.withValues(alpha: 0.22),
                ),
                child: Center(
                  child: Text(
                    _nameController.text.trim().isEmpty
                        ? 'Your name'
                        : _nameController.text.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.signaturePreview(
                      color: AppColors.accentPink,
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
