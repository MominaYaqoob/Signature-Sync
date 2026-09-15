import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _homeSignatures = <SignatureModel>[
    SignatureModel(
      id: 'sig_aliza',
      name: 'Aliza',
      style: SignatureStyle.drawn,
      createdAt: DateTime(2026, 9, 1),
      isDefault: true,
    ),
    SignatureModel(
      id: 'sig_yaqoob',
      name: 'M. Yaqoob',
      style: SignatureStyle.typed,
      createdAt: DateTime(2026, 9, 3),
    ),
  ];

  static final _homeDocuments = <DocumentModel>[
    DocumentModel(
      id: 'doc_rent',
      title: 'Rent agreement.pdf',
      status: DocumentStatus.signed,
      updatedAt: DateTime(2026, 9, 10),
    ),
    DocumentModel(
      id: 'doc_offer',
      title: 'Offer letter.pdf',
      status: DocumentStatus.signed,
      updatedAt: DateTime(2026, 9, 8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      onSettings: () => context.go('/settings'),
                    ),
                    const SizedBox(height: 22),
                    const _QuickActionsGrid(),
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: 'My signatures',
                      onSeeAll: () => context.go('/signatures'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _homeSignatures.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == _homeSignatures.length) {
                      return const _AddSignatureCard();
                    }
                    final sig = _homeSignatures[index];
                    final color = index.isEven
                        ? AppColors.accentPink
                        : AppColors.accentOrange;
                    return _SignaturePreviewCard(
                      name: sig.name,
                      color: color,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
                child: _SectionTitle(
                  title: 'Recent documents',
                  onSeeAll: () => context.go('/documents'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList.separated(
                itemCount: _homeDocuments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = _homeDocuments[index];
                  return _DocumentCard(
                    title: doc.title,
                    subtitle: 'Signed · ${_shortDate(doc.updatedAt)}',
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share coming soon')),
                      );
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AccentTitle(
            title: 'Sign smart',
            subtitle: 'Welcome back',
            accent: AppColors.accentPink,
            barWidth: 48,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 24,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.softPink,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.accentPink, width: 1.2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onSettings,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.settings_rounded,
                color: AppColors.accentPink,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return AccentSectionHeader(
      title: title,
      actionLabel: 'See all',
      onAction: onSeeAll,
      accent: title.toLowerCase().contains('document')
          ? AppColors.accentBlue
          : AppColors.accentPurple,
    );
  }
}

enum _ActionHighlight { none, brand }

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tileColor,
    this.highlight = _ActionHighlight.none,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color tileColor;
  final _ActionHighlight highlight;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = <_QuickAction>[
    _QuickAction(
      label: 'Draw',
      icon: Icons.draw_rounded,
      iconColor: AppColors.accentPink,
      tileColor: AppColors.softPink,
    ),
    _QuickAction(
      label: 'Scan',
      icon: Icons.photo_camera_outlined,
      iconColor: AppColors.accentOrange,
      tileColor: AppColors.softOrange,
    ),
    _QuickAction(
      label: 'Auto',
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.accentBlue,
      tileColor: AppColors.softBlue,
    ),
    _QuickAction(
      label: 'Templates',
      icon: Icons.grid_view_rounded,
      iconColor: AppColors.accentMintGreen,
      tileColor: AppColors.softGreen,
    ),
    _QuickAction(
      label: 'Sign doc',
      icon: Icons.upload_file_outlined,
      iconColor: AppColors.accentPurple,
      tileColor: AppColors.softPurple,
    ),
    _QuickAction(
      label: 'Share',
      icon: Icons.send_rounded,
      iconColor: AppColors.textOnAccent,
      tileColor: AppColors.accentPink,
      highlight: _ActionHighlight.brand,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        return _QuickActionCard(action: _actions[index]);
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final highlighted = action.highlight != _ActionHighlight.none;
    final navyLabel = highlighted;

    final decoration = switch (action.highlight) {
      _ActionHighlight.brand => AppDecorations.card(
          radius: 19,
          gradient: AppColors.purpleGradient,
        ).copyWith(
          boxShadow: AppShadows.tinted(color: AppColors.accentPurple),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
      _ActionHighlight.none => BoxDecoration(
          color: action.tileColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: action.iconColor.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: AppShadows.card,
        ),
    };

    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (action.label == 'Draw') {
              context.push('/draw-signature');
              return;
            }
            if (action.label == 'Scan') {
              context.push('/scan-signature');
              return;
            }
            if (action.label == 'Auto') {
              context.push('/auto-signature');
              return;
            }
            if (action.label == 'Sign doc') {
              context.push('/sign-document');
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${action.label} coming soon')),
            );
          },
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.iconColor, size: 26),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tileLabel.copyWith(
                    color: navyLabel ? Colors.white : action.iconColor,
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

class _SignaturePreviewCard extends StatelessWidget {
  const _SignaturePreviewCard({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color == AppColors.accentPink
            ? AppColors.softPink
            : AppColors.softOrange,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.signaturePreview(color: color),
        ),
      ),
    );
  }
}

class _AddSignatureCard extends StatelessWidget {
  const _AddSignatureCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: AppColors.accentPurple.withValues(alpha: 0.35),
        radius: 19,
      ),
      child: SizedBox(
        width: 88,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/signatures'),
            borderRadius: BorderRadius.circular(19),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
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
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.subtitle,
    required this.onShare,
  });

  final String title;
  final String subtitle;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(
        radius: 19,
        borderColor: AppColors.accentPurple.withValues(alpha: 0.16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.accentPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tileLabel.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accentMintGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onShare,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
