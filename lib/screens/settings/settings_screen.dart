import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/settings_state.dart';

/// Full-page Settings screen pushed from the Profile tab.
///
/// Contains functional settings (playback speed) and informational sections
/// (about, attributions). All displayed controls are genuinely wired — no
/// fake toggles are presented as functional.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settingsState});

  final SettingsState settingsState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settingsState,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _SectionHeader('Playback'),
                _PlaybackSpeedTile(settingsState: settingsState),

                _SectionHeader('Audio Engine'),
                _InfoTile(
                  icon: Icons.music_note_rounded,
                  title: 'Background Playback',
                  subtitle:
                      'Playback continues when the app is backgrounded via the '
                      'system media notification and lock-screen controls.',
                ),
                _InfoTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Equalizer — Not Yet Available',
                  subtitle:
                      'A real equalizer requires platform-native audio '
                      'processing (e.g. Android AudioEffect / iOS AVAudioUnit). '
                      'Planned for a future release.',
                  muted: true,
                ),

                _SectionHeader('About'),
                _AboutTile(),

                _SectionHeader('Attributions'),
                _InfoTile(
                  icon: Icons.library_music_rounded,
                  title: 'Music — Jamendo',
                  subtitle:
                      'Free and open licensed music via the Jamendo API.\n'
                      'jamendo.com',
                ),
                _InfoTile(
                  icon: Icons.lyrics_rounded,
                  title: 'Lyrics — LRCLIB',
                  subtitle:
                      'Timed and plain lyrics provided by LRCLIB, a free and '
                      'open lyrics database.\nlrclib.net',
                ),
                _InfoTile(
                  icon: Icons.headphones_rounded,
                  title: 'Audio — just_audio',
                  subtitle:
                      'Cross-platform audio playback by Ryan Heise, licensed '
                      'under Apache 2.0.\npub.dev/packages/just_audio',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

// ── Playback speed tile ───────────────────────────────────────────────────────

class _PlaybackSpeedTile extends StatelessWidget {
  const _PlaybackSpeedTile({required this.settingsState});

  final SettingsState settingsState;

  static const _steps = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  String _label(double v) {
    if (v == 1.0) return '1× (Normal)';
    final s = v.toStringAsFixed(2);
    // Trim trailing zero: 0.50 → 0.5, 1.25 → 1.25
    final trimmed = s.contains('.') ? s.replaceAll(RegExp(r'0+$'), '') : s;
    final clean = trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return '$clean×';
  }

  @override
  Widget build(BuildContext context) {
    final speed = settingsState.playbackSpeed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(
            Icons.speed_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          title: Text('Playback Speed', style: AppTextStyles.titleMedium),
          subtitle: Text(
            'Adjusts how fast audio plays. Applies immediately.',
            style: AppTextStyles.bodyMedium,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              _label(speed),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentVioletLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Slider(
            value: speed,
            min: SettingsState.minSpeed,
            max: SettingsState.maxSpeed,
            divisions: 6, // 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
            label: _label(speed),
            onChanged: (v) {
              // Snap to nearest step for clean values.
              final snapped = _steps.reduce(
                (a, b) => (v - a).abs() < (v - b).abs() ? a : b,
              );
              settingsState.setPlaybackSpeed(snapped);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _steps
                .map(
                  (s) => Text(
                    _label(s).replaceAll('(Normal)', '').trim(),
                    style: AppTextStyles.caption,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Informational tile ────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: muted ? AppColors.textDisabled : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: muted ? AppColors.textDisabled : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(
          color: muted ? AppColors.textDisabled : AppColors.textSecondary,
        ),
      ),
      isThreeLine: subtitle.length > 60,
    );
  }
}

// ── About tile ────────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accentViolet,
                        AppColors.accentVioletDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Melora', style: AppTextStyles.headlineMedium),
                    Text(
                      'Version 1.0.0 (build 1)',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Premium hybrid music player for local and streaming audio. '
              'Enjoy your personal library alongside Jamendo\'s catalogue of '
              'free and openly licensed music.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
