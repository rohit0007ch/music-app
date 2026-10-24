import 'package:flutter/material.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Bottom sheet showing the current playback queue.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key, required this.playerState});
  final PlayerState playerState;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
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
          child: ListenableBuilder(
            listenable: playerState,
            builder: (context, _) {
              final queue = playerState.queue;
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Text('Up Next', style: AppTextStyles.headlineMedium),
                        const Spacer(),
                        Text(
                          '${queue.length} tracks',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: queue.isEmpty
                        ? Center(
                            child: Text(
                              'Queue is empty',
                              style: AppTextStyles.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            controller: scroll,
                            itemCount: queue.length,
                            itemBuilder: (context, index) {
                              final track = queue[index];
                              return MeloraTrackTile(
                                track: track,
                                isPlaying:
                                    track.id == playerState.currentTrack?.id,
                                onTap: () async {
                                  await playerState.playTrack(track);
                                  if (!context.mounted) return;
                                  final message = playerState.takeUserMessage();
                                  if (message != null) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                  }
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
