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
        final buffering = playerState.isBuffering;
        final canPrev =
            playable &&
            (playerState.position.inSeconds > 3 || playerState.canSkipPrevious);
        final canNext = playable && playerState.canSkipNext;
        final subtitle = !playable
            ? 'Demo · not playable'
            : playerState.error != null
            ? playerState.error!
            : buffering
            ? 'Loading…'
            : track.artist;

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
                  imageUrl: track.artworkUri,
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
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: playerState.error != null
                              ? AppColors.error
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Previous',
                  icon: const Icon(Icons.skip_previous_rounded, size: 22),
                  color: canPrev
                      ? AppColors.textSecondary
                      : AppColors.textDisabled,
                  onPressed: !canPrev
                      ? null
                      : () async {
                          await playerState.skipPrevious();
                          onControlMessage?.call();
                        },
                ),
                IconButton(
                  tooltip: buffering
                      ? 'Loading'
                      : playerState.isPlaying
                      ? 'Pause'
                      : 'Play',
                  icon: buffering
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                  color: playable && !buffering
                      ? AppColors.accentViolet
                      : AppColors.textDisabled,
                  onPressed: !playable || buffering
                      ? null
                      : () async {
                          await playerState.togglePlayPause();
                          onControlMessage?.call();
                        },
                ),
                IconButton(
                  tooltip: 'Next',
                  icon: const Icon(Icons.skip_next_rounded, size: 22),
                  color: canNext
                      ? AppColors.textSecondary
                      : AppColors.textDisabled,
                  onPressed: !canNext
                      ? null
                      : () async {
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
