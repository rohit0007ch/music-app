import 'package:flutter/material.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

/// Detail view for one persisted playlist.
class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistsState,
    required this.libraryState,
    required this.playerState,
    required this.onTrackTap,
  });

  final String playlistId;
  final PlaylistsState playlistsState;
  final LocalLibraryState libraryState;
  final PlayerState playerState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  Future<void> _rename(BuildContext context, PlaylistRecord playlist) async {
    final name = await showPlaylistNameDialog(
      context,
      title: 'Rename playlist',
      initialName: playlist.name,
      confirmLabel: 'Save',
    );
    if (name == null || !context.mounted) return;

    final ok = await playlistsState.rename(playlist.id, name);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Playlist renamed')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(playlistsState.error ?? 'Could not rename playlist.'),
          ),
        );
    }
  }

  Future<void> _delete(BuildContext context, PlaylistRecord playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Delete playlist?', style: AppTextStyles.headlineMedium),
        content: Text(
          '“${playlist.name}” will be removed permanently. '
          'Songs on this device are not deleted.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await playlistsState.delete(playlist.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Playlist deleted')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(playlistsState.error ?? 'Could not delete playlist.'),
          ),
        );
    }
  }

  Future<void> _playAll(BuildContext context, List<Track> displayTracks) async {
    final playable = displayTracks.where((t) => t.isPlayable).toList();
    if (playable.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No playable songs in this playlist.')),
        );
      return;
    }
    await onTrackTap(playable.first, queueContext: playable);
  }

  Future<void> _removeTrack(
    BuildContext context,
    PlaylistRecord playlist,
    Track track,
  ) async {
    final ok = await playlistsState.removeTrack(playlist.id, track.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Removed “${track.title}”')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(playlistsState.error ?? 'Could not update playlist.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([playlistsState, libraryState, playerState]),
      builder: (context, _) {
        final playlist = playlistsState.playlistById(playlistId);
        if (playlist == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
            ),
            body: const MeloraEmptyState(
              icon: Icons.queue_music_rounded,
              title: 'Playlist not found',
              subtitle: 'It may have been deleted.',
            ),
          );
        }

        final displayTracks = [
          for (final record in playlist.tracks)
            resolvePlaylistTrackForDisplay(record, libraryState.songs),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            title: Text(playlist.name, style: AppTextStyles.titleMedium),
            actions: [
              IconButton(
                tooltip: 'Rename',
                icon: const Icon(Icons.edit_rounded),
                onPressed: playlistsState.saving
                    ? null
                    : () => _rename(context, playlist),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: playlistsState.saving
                    ? null
                    : () => _delete(context, playlist),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    MeloraArtwork(
                      paletteIndex: playlist.paletteIndex,
                      size: 72,
                      borderRadius: AppSpacing.radiusMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: AppTextStyles.headlineMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${displayTracks.length} '
                            '${displayTracks.length == 1 ? 'track' : 'tracks'}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: playlistsState.saving
                          ? null
                          : () => _playAll(context, displayTracks),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: displayTracks.isEmpty
                    ? const MeloraEmptyState(
                        icon: Icons.music_off_rounded,
                        title: 'No songs yet',
                        subtitle:
                            'Add songs to this playlist from Library or Discover '
                            'in a later update.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: displayTracks.length,
                        itemBuilder: (context, i) {
                          final t = displayTracks[i];
                          final unavailable =
                              t.source == TrackSource.local && !t.isPlayable;
                          return MeloraTrackTile(
                            track: t,
                            isPlaying: playerState.currentTrack?.id == t.id,
                            onTap: () {
                              if (unavailable) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This song is no longer on this device.',
                                      ),
                                    ),
                                  );
                                return;
                              }
                              if (!t.isPlayable) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This song can’t be played right now.',
                                      ),
                                    ),
                                  );
                                return;
                              }
                              final queue = displayTracks
                                  .where((track) => track.isPlayable)
                                  .toList();
                              onTrackTap(t, queueContext: queue);
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (unavailable)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      'Unavailable',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textDisabled,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  tooltip: 'Remove from playlist',
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  color: AppColors.textDisabled,
                                  onPressed: playlistsState.saving
                                      ? null
                                      : () =>
                                            _removeTrack(context, playlist, t),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
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

/// Shared name dialog for create/rename. Returns trimmed name or `null`.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  String confirmLabel = 'Create',
}) async {
  final controller = TextEditingController(text: initialName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      String? errorText;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: Text(title, style: AppTextStyles.headlineMedium),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Playlist name',
                errorText: errorText,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setState(() => errorText = 'Name cannot be empty');
                  return;
                }
                Navigator.pop(context, trimmed);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmed = controller.text.trim();
                  if (trimmed.isEmpty) {
                    setState(() => errorText = 'Name cannot be empty');
                    return;
                  }
                  Navigator.pop(context, trimmed);
                },
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}
