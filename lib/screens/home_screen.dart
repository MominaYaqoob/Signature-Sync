import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';
import '../widgets/pressable_scale.dart';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: RefreshIndicator(
        color: AppColors.accentPurple,
        backgroundColor: AppColors.cardBackground,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      onSettings: () => context.go('/settings'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _QuickActionsGrid(),
                    const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
                    _SectionTitle(
                      title: 'My signatures',
                      onSeeAll: () => context.go('/signatures'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    AppSpacing.xs,
                  ),
                  itemCount: _homeSignatures.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl + AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: _SectionTitle(
                  title: 'Recent documents',
                  onSeeAll: () => context.go('/documents'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList.separated(
                itemCount: _homeDocuments.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final doc = _homeDocuments[index];
                  return _DocumentCard(
                    title: doc.title,
                    subtitle: 'Signed · ${_shortDate(doc.updatedAt)}',
                    onShare: () {
                      context.push('/quick-share');
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
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
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 24,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        PressableScale(
          onTap: onSettings,
          borderRadius: BorderRadius.circular(999),
          child: Material(
            color: AppColors.primaryBackground,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.accentPurple, width: 1.4),
            ),
            elevation: 0,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.settings_rounded,
                color: AppColors.accentPurple,
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

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = <_QuickAction>[
    _QuickAction(
      label: 'Draw',
      icon: Icons.draw_rounded,
      gradient: AppColors.pinkGradient,
      shadowColor: AppColors.accentPink,
    ),
    _QuickAction(
      label: 'Scan',
      icon: Icons.photo_camera_outlined,
      gradient: AppColors.orangeGradient,
      shadowColor: AppColors.accentOrange,
    ),
    _QuickAction(
      label: 'Auto',
      icon: Icons.auto_awesome_rounded,
      gradient: AppColors.blueGradient,
      shadowColor: AppColors.accentBlue,
    ),
    _QuickAction(
      label: 'Templates',
      icon: Icons.grid_view_rounded,
      gradient: AppColors.greenGradient,
      shadowColor: AppColors.accentMintGreen,
    ),
    _QuickAction(
      label: 'Sign doc',
      icon: Icons.upload_file_outlined,
      gradient: AppColors.violetGradient,
      shadowColor: AppColors.accentPurple,
    ),
    _QuickAction(
      label: 'Share',
      icon: Icons.send_rounded,
      gradient: AppColors.purpleGradient,
      shadowColor: AppColors.accentPink,
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
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        return _StaggeredEntrance(
          index: index,
          child: _QuickActionCard(action: _actions[index]),
        );
      },
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);

    final decoration = AppDecorations.card(
      radius: AppRadii.md,
      sheen: false,
      prominent: true,
      gradient: action.gradient,
    ).copyWith(
      boxShadow: AppShadows.tinted(color: action.shadowColor),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.28),
        width: 1.2,
      ),
    );

    return PressableScale(
      borderRadius: radius,
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
        if (action.label == 'Templates') {
          context.push('/templates');
          return;
        }
        if (action.label == 'Share') {
          context.push('/quick-share');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.label} coming soon')),
        );
      },
      child: Container(
        decoration: decoration,
        padding: AppSpacing.tilePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: AppColors.textOnAccent, size: 26),
            const SizedBox(height: 10),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.tileLabel.copyWith(
                color: AppColors.textOnAccent,
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: AppDecorations.card(
        color: color == AppColors.accentPink
            ? AppColors.softPink
            : AppColors.softOrange,
        radius: AppRadii.md,
        prominent: true,
        borderColor: color.withValues(alpha: 0.28),
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

class _AddSignatureCard extends StatefulWidget {
  const _AddSignatureCard();

  @override
  State<_AddSignatureCard> createState() => _AddSignatureCardState();
}

class _AddSignatureCardState extends State<_AddSignatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final scale = 1 + (t * 0.03);
        final opacity = 0.7 + (t * 0.3);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.7, 1.0),
            child: child,
          ),
        );
      },
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
          radius: AppRadii.md,
        ),
        child: SizedBox(
          width: 88,
          height: 100,
          child: PressableScale(
            onTap: () => context.go('/signatures'),
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: const Center(
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
      padding: AppSpacing.cardPadding,
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        borderColor: AppColors.accentPurple.withValues(alpha: 0.16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.accentPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
          PressableScale(
            onTap: onShare,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.ios_share_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
