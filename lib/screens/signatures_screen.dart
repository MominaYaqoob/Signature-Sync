import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';
import '../widgets/pressable_scale.dart';
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

  Future<void> _confirmDelete(SignatureModel signature) async {
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
            'Remove “${signature.name}” from this device. This can’t be undone.',
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
    if (confirmed == true && mounted) {
      await StorageService.deleteSignature(signature.id);
      _reload();
      _toast('Signature deleted');
    }
  }

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
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'Delete',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.danger,
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
        await _confirmDelete(signature);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: signatures.length + 2,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == signatures.length) {
                        return _NewSignatureCard(onTap: _showCreateSheet);
                      }
                      if (index == signatures.length + 1) {
                        return const _ListFooterHint(
                          icon: Icons.auto_awesome_outlined,
                          message:
                              'Tip: set a default signature for faster signing.',
                        );
                      }
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
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: signature.hasImage
                        ? SizedBox(
                            height: 36,
                            child: SignatureVisual.fromModel(
                              signature,
                              color: color,
                              fontSize: 30,
                            ),
                          )
                        : Text(
                            signature.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.signaturePreview(
                              color: color,
                              size: 30,
                            ),
                          ),
                  ),
                  if (signature.isDefault) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.accentBlue.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Default',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ],
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
      ),
    );
  }
}

class _NewSignatureCard extends StatelessWidget {
  const _NewSignatureCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.accentPurple.withValues(alpha: 0.35),
        radius: AppRadii.md,
      ),
      child: PressableScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                color: AppColors.accentPurple,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'New signature',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
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

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ListFooterHint extends StatelessWidget {
  const _ListFooterHint({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          radius: AppRadii.md,
          elevated: false,
          sheen: false,
          color: AppColors.softSurface,
          borderColor: AppColors.borderSoft,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
