import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _amoledTheme = false;
  bool _highQuality = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text('Profile', style: AppTextStyles.displayMedium),
          ),
        ),

        // Avatar + name
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentViolet,
                        AppColors.accentVioletDark,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Music Lover', style: AppTextStyles.headlineLarge),
                      Text(
                        'melora@example.com',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile — coming soon')),
                  ),
                ),
              ],
            ),
          ),
        ),

        _section('Account'),
        _tile(icon: Icons.manage_accounts_rounded, title: 'Account Details'),
        _tile(icon: Icons.lock_rounded, title: 'Privacy & Security'),
        _tile(
          icon: Icons.subscriptions_rounded,
          title: 'Subscription',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              'Free',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentVioletLight,
              ),
            ),
          ),
        ),

        _section('Playback'),
        SliverToBoxAdapter(
          child: _SwitchTile(
            icon: Icons.high_quality_rounded,
            title: 'High Quality Audio',
            subtitle: 'Stream at 320 kbps',
            value: _highQuality,
            onChanged: (v) => setState(() => _highQuality = v),
          ),
        ),
        _tile(icon: Icons.graphic_eq_rounded, title: 'Equalizer'),
        _tile(
          icon: Icons.queue_music_rounded,
          title: 'Crossfade',
          trailing: Text('3s', style: AppTextStyles.labelMedium),
        ),

        _section('Appearance'),
        SliverToBoxAdapter(
          child: _SwitchTile(
            icon: Icons.brightness_2_rounded,
            title: 'AMOLED Black',
            subtitle: 'Pure black backgrounds',
            value: _amoledTheme,
            onChanged: (v) => setState(() => _amoledTheme = v),
          ),
        ),

        _section('Notifications'),
        SliverToBoxAdapter(
          child: _SwitchTile(
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            subtitle: 'New releases and updates',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
        ),

        _section('About'),
        _tile(
          icon: Icons.info_rounded,
          title: 'App Version',
          trailing: Text('1.0.0', style: AppTextStyles.labelMedium),
        ),
        _tile(icon: Icons.description_rounded, title: 'Terms of Service'),
        _tile(icon: Icons.privacy_tip_rounded, title: 'Privacy Policy'),
        _tile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          titleColor: AppColors.error,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  Widget _section(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.accentVioletLight,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
  }) => SliverToBoxAdapter(
    child: ListTile(
      leading: Icon(
        icon,
        color: titleColor ?? AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textDisabled,
            size: 20,
          ),
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title — coming soon'))),
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodyMedium)
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentViolet,
      ),
    );
  }
}
