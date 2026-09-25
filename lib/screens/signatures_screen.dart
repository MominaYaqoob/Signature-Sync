import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_actions.dart';
import '../widgets/signature_visual.dart';

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({super.key});

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _reload() {
    if (mounted) setState(() {});
  }

  Future<void> _showCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, AppSpacing.sm, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'New signature',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to create it',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                _CreateOption(
                  icon: Icons.draw_rounded,
                  label: 'Draw',
                  subtitle: 'Sign with your finger',
                  color: AppColors.accentPurple,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/draw-signature').then((_) {
                      if (mounted) _reload();
                    });
                  },
                ),
                const SizedBox(height: 10),
                _CreateOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Scan',
                  subtitle: 'Capture with the camera',
                  color: AppColors.accentBlue,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/scan-signature').then((_) {
                      if (mounted) _reload();
                    });
                  },
                ),
                const SizedBox(height: 10),
                _CreateOption(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Auto',
                  subtitle: 'Generate from your name',
                  color: AppColors.accentPurple,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/auto-signature').then((_) {
                      if (mounted) _reload();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
    if (mounted) _reload();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setDefault(String id) async {
    await StorageService.setDefaultSignature(id);
    _reload();
    _toast('Set as default');
  }

  Future<void> _rename(SignatureModel signature) async {
    final controller = TextEditingController(text: signature.name);
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
    await StorageService.saveSignature(signature.copyWith(name: result));
    if (mounted) _reload();
  }

  Future<void> _delete(SignatureModel signature) =>
      deleteSignatureWithUndo(ScaffoldMessenger.of(context), signature);

  Future<void> _openMenu(SignatureModel signature) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, AppSpacing.sm, 8, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signature.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              signatureMeta(signature),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (!signature.isDefault)
                  ListTile(
                    leading: const Icon(
                      Icons.star_outline_rounded,
                      color: AppColors.accentBlue,
                    ),
                    title: Text(
                      'Set as default',
                      style: AppTextStyles.bodyMedium,
                    ),
                    onTap: () => Navigator.pop(context, 'default'),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.accentPurple,
                  ),
                  title: Text(
                    'Rename',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () => Navigator.pop(context, 'rename'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: kDeleteRed,
                  ),
                  title: Text(
                    'Delete',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: kDeleteRed,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'default':
        await _setDefault(signature.id);
      case 'rename':
        await _rename(signature);
      case 'delete':
        await _delete(signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on any Hive change (save, rename, delete, undo from any screen).
    return ValueListenableBuilder(
      valueListenable: StorageService.signaturesListenable,
      builder: (context, _, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final signatures = StorageService.getAllSignatures();
    final isEmpty = signatures.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: AccentTitle(
              title: 'My Signatures',
              accent: AppColors.navy,
              style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
            ),
          ),
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl + 4,
                0,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      signatures.length == 1
                          ? '1 saved signature'
                          : '${signatures.length} saved signatures',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  _NewSignatureButton(onTap: _showCreateSheet),
                ],
              ),
            ),
          Expanded(
            child: isEmpty
                ? _EmptySignatures(onCreate: _showCreateSheet)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    itemCount: signatures.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final signature = signatures[index];
                      final color = index.isEven
                          ? AppColors.accentPurple
                          : AppColors.accentBlue;
                      return _SignatureCard(
                        signature: signature,
                        color: color,
                        onTap: () => context
                            .push(
                          '/signature-detail',
                          extra: signature,
                        )
                            .then((_) {
                          if (mounted) _reload();
                        }),
                        onMenu: () => _openMenu(signature),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.signature,
    required this.color,
    required this.onTap,
    required this.onMenu,
  });

  final SignatureModel signature;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          radius: AppRadii.md,
          prominent: true,
          borderColor: color.withValues(alpha: 0.22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Signature preview on white so ink colours look as they will on paper.
            Container(
              height: 92,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: SignatureVisual.fromModel(
                  signature,
                  color: color,
                  fontSize: 38,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              signature.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (signature.isDefault) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const _DefaultBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        signatureMeta(signature),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                PressableScale(
                  onTap: onMenu,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.accentBlue),
          const SizedBox(width: 3),
          Text(
            'Default',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewSignatureButton extends StatelessWidget {
  const _NewSignatureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 16,
              color: AppColors.accentPurple,
            ),
            const SizedBox(width: 4),
            Text(
              'New signature',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySignatures extends StatelessWidget {
  const _EmptySignatures({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: AppDecorations.card(
                radius: AppRadii.lg,
                prominent: true,
              ),
              child: const Icon(
                Icons.gesture_rounded,
                color: AppColors.accentPurple,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No signatures yet',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create your first signature to start signing documents.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: PressableScale(
                onTap: onCreate,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: DecoratedBox(
                  decoration: AppDecorations.purpleButton(radius: AppRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Center(
                      child: Text(
                        'Create signature',
                        style: AppTextStyles.onAccentLabel.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          color: AppColors.altCardBackground,
          radius: AppRadii.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelMedium.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
