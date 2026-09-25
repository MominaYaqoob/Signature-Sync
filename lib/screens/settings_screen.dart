import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';
import '../widgets/pressable_scale.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openStoreListing() async {
    // Package id from android/app/build.gradle.kts; the Play Store page
    // only exists once the app is published, so a launch failure (not
    // yet listed, no store app installed, etc.) falls back to a message
    // instead of a silent no-op.
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.signaturesync.signature_sync',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _toast('Could not open the Play Store on this device.');
    }
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          title: Text(
            'Clear all data?',
            style: AppTextStyles.titleMedium,
          ),
          content: Text(
            'This will remove saved signatures and document history from this device. This action can’t be undone.',
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
                'Clear data',
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
      await StorageService.clearAll();
      _toast('All local data cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            child: AccentTitle(
              title: 'Settings',
              accent: AppColors.navy,
              style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
            _SettingsCard(
              onTap: () => context.go('/signatures'),
              child: const _SettingsRow(
                icon: Icons.gesture_rounded,
                label: 'Default signature',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              onTap: _openStoreListing,
              child: const _SettingsRow(
                icon: Icons.star_outline_rounded,
                label: 'Rate the app',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              onTap: () => context.push('/privacy'),
              child: const _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              onTap: () => context.push('/about'),
              child: const _SettingsRow(
                icon: Icons.info_outline_rounded,
                label: 'About / App version',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              onTap: _confirmClearData,
              child: const _SettingsRow(
                icon: Icons.delete_forever_outlined,
                label: 'Clear all data',
                iconColor: AppColors.danger,
                labelColor: AppColors.danger,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.danger,
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: AppSpacing.cardPadding,
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        borderColor: AppColors.accentPurple.withValues(alpha: 0.16),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: content,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.iconColor = AppColors.accentPurple,
    this.labelColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(color: labelColor),
          ),
        ),
        trailing,
      ],
    );
  }
}
