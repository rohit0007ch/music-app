import 'package:flutter/material.dart' hide RepeatMode;
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Previous / Play-Pause / Next controls + Shuffle & Repeat.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.playerState});
  final MeloraPlayerState playerState;

  void _showMessageIfAny(BuildContext context) {
    final message = playerState.takeUserMessage();
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        final playable = playerState.isCurrentPlayable;
        final buffering = playerState.isBuffering;
        final canPrev =
            playable &&
            (playerState.position.inSeconds > 3 || playerState.canSkipPrevious);
        final canNext = playable && playerState.canSkipNext;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: playerState.isShuffle ? 'Shuffle on' : 'Shuffle off',
              icon: Icon(
                Icons.shuffle_rounded,
                color: playerState.isShuffle
                    ? AppColors.accentViolet
                    : AppColors.textDisabled,
              ),
              iconSize: 24,
              onPressed: playerState.toggleShuffle,
            ),
            IconButton(
              tooltip: 'Previous',
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 40,
              color: canPrev ? AppColors.textPrimary : AppColors.textDisabled,
              onPressed: !canPrev
                  ? null
                  : () async {
                      await playerState.skipPrevious();
                      if (context.mounted) _showMessageIfAny(context);
                    },
            ),
            Semantics(
              button: true,
              label: buffering
                  ? 'Loading'
                  : playerState.isPlaying
                  ? 'Pause'
                  : 'Play',
              child: GestureDetector(
                onTap: !playable || buffering
                    ? null
                    : () async {
                        await playerState.togglePlayPause();
                        if (context.mounted) _showMessageIfAny(context);
                      },
                child: Opacity(
                  opacity: playable ? 1 : 0.45,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.accentVioletLight,
                          AppColors.accentViolet,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentViolet.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: buffering
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next',
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 40,
              color: canNext ? AppColors.textPrimary : AppColors.textDisabled,
              onPressed: !canNext
                  ? null
                  : () async {
                      await playerState.skipNext();
                      if (context.mounted) _showMessageIfAny(context);
                    },
            ),
            IconButton(
              tooltip: switch (playerState.repeatMode) {
                RepeatMode.none => 'Repeat off',
                RepeatMode.all => 'Repeat all',
                RepeatMode.one => 'Repeat one',
              },
              icon: Icon(
                playerState.repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: playerState.repeatMode != RepeatMode.none
                    ? AppColors.accentViolet
                    : AppColors.textDisabled,
              ),
              iconSize: 24,
              onPressed: playerState.cycleRepeat,
            ),
          ],
        );
      },
    );
  }
}
