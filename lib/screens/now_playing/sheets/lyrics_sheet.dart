import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Bottom sheet with scrollable mock lyrics, current line highlighted.
class LyricsSheet extends StatelessWidget {
  const LyricsSheet({super.key, required this.playerState});
  final PlayerState playerState;

  @override
  Widget build(BuildContext context) {
    const lyrics = MockData.mockLyrics;
    const highlightLine = 3;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text('Lyrics', style: AppTextStyles.headlineMedium),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: playerState,
                      builder: (context, _) => Text(
                        playerState.currentTrack?.title ?? '',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final isHighlighted = index == highlightLine;
                    if (line.isEmpty) {
                      return const SizedBox(height: AppSpacing.md);
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        line,
                        style: isHighlighted
                            ? AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.accentVioletLight,
                              )
                            : AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textDisabled,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
