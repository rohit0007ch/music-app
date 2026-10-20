import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Slider + timestamp row for the Now Playing screen.
class ProgressBarWidget extends StatelessWidget {
  const ProgressBarWidget({super.key, required this.playerState});
  final PlayerState playerState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: playerState.progress,
                onChanged: playerState.isCurrentPlayable
                    ? playerState.seekTo
                    : null,
                activeColor: AppColors.accentViolet,
                inactiveColor: AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    playerState.elapsedLabel,
                    style: AppTextStyles.labelMedium,
                  ),
                  Text(
                    playerState.remainingLabel,
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
