import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/screens/library/playlist_detail_screen.dart';
import 'package:melora_music/shared/widgets/add_to_playlist_sheet.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.playerState,
    required this.libraryState,
    required this.favoritesState,
    required this.playlistsState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
  final FavoritesState favoritesState;
  final PlaylistsState playlistsState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Songs',
    'Albums',
    'Artists',
    'Favourites',
    'Playlists',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Soft permission check when Library is first shown (no system prompt).
    if (!widget.libraryState.loadedOnce && !widget.libraryState.loading) {
      widget.libraryState.load(requestPermission: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text('Library', style: AppTextStyles.displayMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                color: AppColors.textSecondary,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sort coming soon')),
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accentViolet,
          labelColor: AppColors.accentVioletLight,
          unselectedLabelColor: AppColors.textDisabled,
          labelStyle: AppTextStyles.labelLarge,
          dividerColor: AppColors.border,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SongsTab(
                playerState: widget.playerState,
                libraryState: widget.libraryState,
                favoritesState: widget.favoritesState,
                playlistsState: widget.playlistsState,
                onTrackTap: widget.onTrackTap,
              ),
              const _AlbumsTab(),
              const _ArtistsTab(),
              _FavouritesTab(
                playerState: widget.playerState,
                libraryState: widget.libraryState,
                favoritesState: widget.favoritesState,
                onTrackTap: widget.onTrackTap,
              ),
              _PlaylistsTab(
                playerState: widget.playerState,
                libraryState: widget.libraryState,
                playlistsState: widget.playlistsState,
                onTrackTap: widget.onTrackTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab({
    required this.playerState,
    required this.libraryState,
    required this.favoritesState,
    required this.playlistsState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
  final FavoritesState favoritesState;
  final PlaylistsState playlistsState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  void _showActions(BuildContext context, Track track) {
    showTrackActionsSheet(
      context: context,
      track: track,
      playlistsState: playlistsState,
      favoritesState: favoritesState,
      playerState: playerState,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([playerState, libraryState]),
      builder: (context, _) {
        final localSongs = libraryState.songs;
        final demos = MockData.tracks;

        return RefreshIndicator(
          color: AppColors.accentViolet,
          onRefresh: () => libraryState.load(requestPermission: true),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              _LocalLibraryHeader(libraryState: libraryState),
              if (libraryState.loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (libraryState.permissionPermanentlyDenied)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: MeloraEmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Permission blocked',
                    subtitle:
                        libraryState.error ??
                        'Music access is turned off. Enable it in Settings '
                            'to play songs stored on this device.',
                    actionLabel: 'Open Settings',
                    action: () => libraryState.openSettings(),
                  ),
                )
              else if (!libraryState.permissionGranted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: MeloraEmptyState(
                    icon: Icons.library_music_outlined,
                    title: 'Allow music access',
                    subtitle:
                        'Grant library permission to play songs stored on '
                        'this device.',
                    actionLabel: 'Allow access',
                    action: () => libraryState.load(requestPermission: true),
                  ),
                )
              else if (libraryState.hasLoadError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: MeloraEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load songs',
                    subtitle:
                        libraryState.error ??
                        'Something went wrong reading your music library.',
                    actionLabel: 'Retry',
                    action: () => libraryState.load(requestPermission: false),
                  ),
                )
              else if (localSongs.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: MeloraEmptyState(
                    icon: Icons.music_off_rounded,
                    title: 'No local songs found',
                    subtitle: 'Add music to this device, then pull to refresh.',
                  ),
                )
              else
                ...localSongs.map(
                  (t) => MeloraTrackTile(
                    track: t,
                    isPlaying: playerState.currentTrack?.id == t.id,
                    onTap: () => onTrackTap(t, queueContext: localSongs),
                    onMore: () => _showActions(context, t),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Demo catalog',
                  style: AppTextStyles.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Preview UI only — these tracks are not playable.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...demos.map(
                (t) => MeloraTrackTile(
                  track: t,
                  isPlaying: playerState.currentTrack?.id == t.id,
                  onTap: () => onTrackTap(t),
                  onMore: () => _showActions(context, t),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocalLibraryHeader extends StatelessWidget {
  const _LocalLibraryHeader({required this.libraryState});

  final LocalLibraryState libraryState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('On this device', style: AppTextStyles.headlineMedium),
                if (libraryState.permissionGranted)
                  Text(
                    libraryState.hasLoadError
                        ? 'Scan failed'
                        : libraryState.hasSongs
                        ? '${libraryState.songs.length} songs'
                        : 'Ready to scan',
                    style: AppTextStyles.bodyMedium,
                  )
                else if (libraryState.loadedOnce)
                  Text(
                    libraryState.permissionPermanentlyDenied
                        ? 'Access blocked'
                        : 'Permission needed',
                    style: AppTextStyles.bodyMedium,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: libraryState.loading
                ? null
                : libraryState.permissionPermanentlyDenied
                ? () => libraryState.openSettings()
                : () => libraryState.load(requestPermission: true),
            child: Text(
              libraryState.permissionPermanentlyDenied
                  ? 'Settings'
                  : libraryState.permissionGranted
                  ? 'Refresh'
                  : 'Allow access',
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: MockData.albums.length,
      itemBuilder: (context, i) {
        final a = MockData.albums[i];
        return GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Album: ${a.title} — coming soon')),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MeloraArtwork(
                  paletteIndex: a.paletteIndex,
                  size: double.infinity,
                  borderRadius: AppSpacing.radiusMd,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                a.title,
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${a.artist} · ${a.year}',
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: MockData.artists.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final ar = MockData.artists[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    AppColors.artworkPalettes[ar.paletteIndex %
                        AppColors.artworkPalettes.length],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          title: Text(ar.name, style: AppTextStyles.titleMedium),
          subtitle: Text(
            '${ar.trackCount} tracks',
            style: AppTextStyles.bodyMedium,
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textDisabled,
          ),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artist: ${ar.name} — coming soon')),
          ),
        );
      },
    );
  }
}

class _FavouritesTab extends StatelessWidget {
  const _FavouritesTab({
    required this.playerState,
    required this.libraryState,
    required this.favoritesState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
  final FavoritesState favoritesState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([playerState, libraryState, favoritesState]),
      builder: (context, _) {
        if (favoritesState.loading && !favoritesState.loadedOnce) {
          return const Center(child: CircularProgressIndicator());
        }

        if (favoritesState.loadedOnce &&
            favoritesState.error != null &&
            favoritesState.isEmpty) {
          return MeloraEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Couldn’t load favourites',
            subtitle: favoritesState.error,
            actionLabel: 'Retry',
            action: () => favoritesState.load(),
          );
        }

        if (favoritesState.isEmpty) {
          return const MeloraEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No favourites yet',
            subtitle: 'Tap the heart icon on any track to add it here.',
          );
        }

        final displayTracks = [
          for (final record in favoritesState.favorites)
            resolveFavoriteForDisplay(record, libraryState.songs),
        ];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: displayTracks.length,
          itemBuilder: (context, i) {
            final t = displayTracks[i];
            final unavailable = t.source == TrackSource.local && !t.isPlayable;
            return MeloraTrackTile(
              track: t,
              isPlaying: playerState.currentTrack?.id == t.id,
              onTap: () {
                if (unavailable) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('This song is no longer on this device.'),
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
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'Unavailable',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accentAmber,
                    size: 18,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Resolves a persisted favorite against the current library scan by stable ID.
///
/// Local matches use live metadata/URI. Missing local files stay saved but
/// return a non-playable track (no [Track.localUri]).
@visibleForTesting
Track resolveFavoriteForDisplay(FavoriteRecord record, List<Track> localSongs) {
  if (record.source == TrackSource.local) {
    for (final song in localSongs) {
      if (song.id == record.id) {
        return song.copyWith(isFavourite: true);
      }
    }
    return Track(
      id: record.id,
      title: record.title,
      artist: record.artist,
      album: record.album,
      durationSeconds: record.durationSeconds,
      paletteIndex: record.paletteIndex,
      source: TrackSource.local,
      localId: record.localId,
      localUri: null,
      artworkUri: record.artworkUri,
      genre: record.genre,
      isFavourite: true,
    );
  }
  return record.toTrack();
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({
    required this.playerState,
    required this.libraryState,
    required this.playlistsState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
  final PlaylistsState playlistsState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await showPlaylistNameDialog(
      context,
      title: 'New playlist',
      confirmLabel: 'Create',
    );
    if (name == null || !context.mounted) return;

    final id = await playlistsState.create(
      name,
      paletteIndex: playlistsState.playlists.length % 8,
    );
    if (!context.mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(playlistsState.error ?? 'Could not create playlist.'),
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Created “$name”')));
    _openDetail(context, id);
  }

  void _openDetail(BuildContext context, String playlistId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(
          playlistId: playlistId,
          playlistsState: playlistsState,
          libraryState: libraryState,
          playerState: playerState,
          onTrackTap: onTrackTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playlistsState,
      builder: (context, _) {
        Widget body;
        if (playlistsState.loading && !playlistsState.loadedOnce) {
          body = const Center(child: CircularProgressIndicator());
        } else if (playlistsState.loadedOnce &&
            playlistsState.error != null &&
            playlistsState.isEmpty) {
          body = MeloraEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Couldn’t load playlists',
            subtitle: playlistsState.error,
            actionLabel: 'Retry',
            action: () => playlistsState.load(),
          );
        } else if (playlistsState.isEmpty) {
          body = MeloraEmptyState(
            icon: Icons.queue_music_rounded,
            title: 'No playlists yet',
            subtitle: 'Create a playlist to organize your music.',
            actionLabel: 'Create playlist',
            action: playlistsState.saving
                ? null
                : () => _createPlaylist(context),
          );
        } else {
          final playlists = playlistsState.playlists;
          body = ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              final pl = playlists[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: MeloraArtwork(
                    paletteIndex: pl.paletteIndex,
                    size: 52,
                    borderRadius: AppSpacing.radiusSm,
                  ),
                ),
                title: Text(pl.name, style: AppTextStyles.titleMedium),
                subtitle: Text(
                  '${pl.trackCount} '
                  '${pl.trackCount == 1 ? 'track' : 'tracks'}',
                  style: AppTextStyles.bodyMedium,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                ),
                onTap: () => _openDetail(context, pl.id),
              );
            },
          );
        }

        return Stack(
          children: [
            body,
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
              child: FloatingActionButton(
                onPressed: playlistsState.saving
                    ? null
                    : () => _createPlaylist(context),
                backgroundColor: AppColors.accentViolet,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
