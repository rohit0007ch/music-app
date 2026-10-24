import 'package:flutter/material.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/screens/library/playlist_detail_screen.dart';
import 'package:melora_music/shared/widgets/favorite_track_action.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

/// Adds [track] to an existing playlist or creates a new one.
Future<void> showAddToPlaylistSheet({
  required BuildContext context,
  required Track track,
  required PlaylistsState playlistsState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      final messenger = ScaffoldMessenger.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: ListenableBuilder(
            listenable: playlistsState,
            builder: (_, _) {
              final playlists = playlistsState.playlists;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add to playlist',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.title,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.add_rounded,
                        color: AppColors.accentViolet,
                      ),
                      title: Text(
                        'New playlist',
                        style: AppTextStyles.titleMedium,
                      ),
                      enabled: !playlistsState.saving,
                      onTap: () async {
                        final name = await showPlaylistNameDialog(
                          sheetContext,
                          title: 'New playlist',
                          confirmLabel: 'Create',
                        );
                        if (name == null || !sheetContext.mounted) return;
                        final id = await playlistsState.create(
                          name,
                          paletteIndex: playlistsState.playlists.length % 8,
                        );
                        if (id == null) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  playlistsState.error ??
                                      'Could not create playlist.',
                                ),
                              ),
                            );
                          return;
                        }
                        final ok = await playlistsState.addTrack(id, track);
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Added to “$name”'
                                    : (playlistsState.error ??
                                          'Could not update playlist.'),
                              ),
                            ),
                          );
                      },
                    ),
                    if (playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'No playlists yet. Create one above.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (context, i) {
                            final pl = playlists[i];
                            final alreadyIn = pl.tracks.any(
                              (t) => t.id == track.id,
                            );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                alreadyIn
                                    ? Icons.playlist_add_check_rounded
                                    : Icons.queue_music_rounded,
                                color: alreadyIn
                                    ? AppColors.accentViolet
                                    : AppColors.textSecondary,
                              ),
                              title: Text(
                                pl.name,
                                style: AppTextStyles.titleMedium,
                              ),
                              subtitle: Text(
                                alreadyIn
                                    ? 'Already in playlist'
                                    : '${pl.trackCount} '
                                          '${pl.trackCount == 1 ? 'track' : 'tracks'}',
                                style: AppTextStyles.bodyMedium,
                              ),
                              enabled: !playlistsState.saving && !alreadyIn,
                              onTap: alreadyIn
                                  ? null
                                  : () async {
                                      final ok = await playlistsState.addTrack(
                                        pl.id,
                                        track,
                                      );
                                      if (!sheetContext.mounted) return;
                                      Navigator.pop(sheetContext);
                                      messenger
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? 'Added to “${pl.name}”'
                                                  : (playlistsState.error ??
                                                        'Could not update playlist.'),
                                            ),
                                          ),
                                        );
                                    },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Track overflow sheet: favourites + add to playlist.
Future<void> showTrackActionsSheet({
  required BuildContext context,
  required Track track,
  required PlaylistsState playlistsState,
  required FavoritesState favoritesState,
  required PlayerState playerState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(track.artist, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FavoriteToggleTile(
              track: track,
              favoritesState: favoritesState,
              playerState: playerState,
              onCompleted: () => Navigator.of(sheetContext).pop(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.playlist_add_rounded,
                color: AppColors.accentViolet,
              ),
              title: Text('Add to playlist', style: AppTextStyles.titleMedium),
              onTap: () {
                Navigator.pop(sheetContext);
                showAddToPlaylistSheet(
                  context: context,
                  track: track,
                  playlistsState: playlistsState,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
