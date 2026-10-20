import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Dialog for choosing a sleep timer duration.
class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key, required this.playerState});
  final PlayerState playerState;

  static const _options = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sleep Timer', style: AppTextStyles.headlineMedium),
      content: ListenableBuilder(
        listenable: playerState,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stop playback after:', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ..._options.map((mins) {
                    final isSelected = playerState.sleepTimerMinutes == mins;
                    return ChoiceChip(
                      label: Text('$mins min'),
                      selected: isSelected,
                      onSelected: (_) =>
                          playerState.setSleepTimer(isSelected ? null : mins),
                      selectedColor: AppColors.accentViolet.withValues(
                        alpha: 0.3,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.accentVioletLight
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                  ChoiceChip(
                    label: const Text('Off'),
                    selected: playerState.sleepTimerMinutes == null,
                    onSelected: (_) => playerState.setSleepTimer(null),
                    selectedColor: AppColors.accentViolet.withValues(
                      alpha: 0.3,
                    ),
                    labelStyle: TextStyle(
                      color: playerState.sleepTimerMinutes == null
                          ? AppColors.accentVioletLight
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (playerState.sleepTimerMinutes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: AppColors.accentViolet,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stopping in ${playerState.sleepTimerMinutes} minutes',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.accentVioletLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
