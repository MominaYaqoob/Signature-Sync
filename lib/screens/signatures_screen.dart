import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({super.key});

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  late List<SignatureModel> _signatures;

  @override
  void initState() {
    super.initState();
    _signatures = List<SignatureModel>.from(DummySignatures.seed());
  }

  Future<void> _showCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    context.push('/draw-signature');
                  },
                ),
                const SizedBox(height: 10),
                _CreateOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Scan',
                  subtitle: 'Capture with the camera',
                  color: AppColors.accentMintGreen,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/scan-signature');
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
                    context.push('/auto-signature');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setDefault(String id) {
    setState(() {
      _signatures = _signatures
          .map((s) => s.copyWith(isDefault: s.id == id))
          .toList();
    });
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
            borderRadius: BorderRadius.circular(18),
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
                  color: AppColors.accentMintGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    setState(() {
      _signatures = _signatures
          .map((s) => s.id == signature.id ? s.copyWith(name: result) : s)
          .toList();
    });
  }

  void _delete(SignatureModel signature) {
    setState(() {
      _signatures = _signatures.where((s) => s.id != signature.id).toList();
      if (_signatures.isNotEmpty && !_signatures.any((s) => s.isDefault)) {
        _signatures[0] = _signatures[0].copyWith(isDefault: true);
      }
    });
    _toast('Signature deleted');
  }

  Future<void> _openMenu(SignatureModel signature) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.star_outline_rounded,
                    color: AppColors.accentMintGreen,
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
        _setDefault(signature.id);
      case 'rename':
        await _rename(signature);
      case 'delete':
        _delete(signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _signatures.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: AccentTitle(
                title: 'My Signatures',
                accent: AppColors.accentPurple,
                barWidth: 44,
                style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
              ),
            ),
            Expanded(
              child: isEmpty
                  ? _EmptySignatures(onCreate: _showCreateSheet)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: _signatures.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == _signatures.length) {
                          return _NewSignatureCard(onTap: _showCreateSheet);
                        }
                        final signature = _signatures[index];
                        final color = index.isEven
                            ? AppColors.accentPurple
                            : AppColors.accentMintGreen;
                        return _SignatureCard(
                          signature: signature,
                          color: color,
                          onMenu: () => _openMenu(signature),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.signature,
    required this.color,
    required this.onMenu,
  });

  final SignatureModel signature;
  final Color color;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: AppDecorations.card(
        radius: 19,
        borderColor: color.withValues(alpha: 0.22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
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
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentMintGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Default',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentMintGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onMenu,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
        radius: 19,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_rounded,
                  color: AppColors.accentPurple,
                  size: 22,
                ),
                const SizedBox(width: 8),
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
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.gesture_rounded,
                color: AppColors.accentPurple,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No signatures yet',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first signature to start signing documents.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: Material(
                color: AppColors.accentPurple,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(14),
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
    return Material(
      color: AppColors.altCardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
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
