import 'package:flutter/material.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Persistent mini-player bar shown above the bottom navigation.
class MeloraMiniPlayer extends StatelessWidget {
  const MeloraMiniPlayer({
    super.key,
    required this.playerState,
    required this.onTap,
    this.onControlMessage,
  });

  final PlayerState playerState;
  final VoidCallback onTap;

  /// Called after a control action that may set [PlayerState.userMessage].
  final VoidCallback? onControlMessage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        final track = playerState.currentTrack;
        if (track == null) return const SizedBox.shrink();
        final playable = track.isPlayable;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: AppSpacing.miniPlayerHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                MeloraArtwork(
                  paletteIndex: track.paletteIndex,
                  size: 48,
                  borderRadius: AppSpacing.radiusSm,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        playable ? track.artist : 'Demo · not playable',
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 22),
                  color: AppColors.textSecondary,
                  onPressed: () async {
                    await playerState.skipPrevious();
                    onControlMessage?.call();
                  },
                ),
                IconButton(
                  icon: Icon(
                    playerState.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                  color: playable
                      ? AppColors.accentViolet
                      : AppColors.textDisabled,
                  onPressed: () async {
                    await playerState.togglePlayPause();
                    onControlMessage?.call();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 22),
                  color: AppColors.textSecondary,
                  onPressed: () async {
                    await playerState.skipNext();
                    onControlMessage?.call();
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
          ),
        );
      },
    );
  }
}
