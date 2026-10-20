import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.playerState,
    required this.libraryState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
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
                onTrackTap: widget.onTrackTap,
              ),
              const _AlbumsTab(),
              const _ArtistsTab(),
              _FavouritesTab(
                playerState: widget.playerState,
                onTrackTap: (track) => widget.onTrackTap(track),
              ),
              const _PlaylistsTab(),
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
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final LocalLibraryState libraryState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

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
                        'Grant library permission to play songs stored on this device.',
                    actionLabel: 'Allow access',
                    action: () => libraryState.load(requestPermission: true),
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
                    onMore: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    ),
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
                  onMore: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon'))),
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
                    libraryState.hasSongs
                        ? '${libraryState.songs.length} songs'
                        : 'Ready to scan',
                    style: AppTextStyles.bodyMedium,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: libraryState.loading
                ? null
                : () => libraryState.load(requestPermission: true),
            child: Text(
              libraryState.permissionGranted ? 'Refresh' : 'Allow access',
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
  const _FavouritesTab({required this.playerState, required this.onTrackTap});
  final PlayerState playerState;
  final void Function(Track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    final favs = MockData.favourites;
    if (favs.isEmpty) {
      return const MeloraEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favourites yet',
        subtitle: 'Tap the heart icon on any track to add it here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: favs.length,
      itemBuilder: (context, i) {
        final t = favs[i];
        return ListenableBuilder(
          listenable: playerState,
          builder: (context, _) => MeloraTrackTile(
            track: t,
            isPlaying: playerState.currentTrack?.id == t.id,
            onTap: () => onTrackTap(t),
            trailing: const Icon(
              Icons.favorite_rounded,
              color: AppColors.accentAmber,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: MockData.playlists.length,
          itemBuilder: (context, i) {
            final pl = MockData.playlists[i];
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
                '${pl.trackCount} tracks',
                style: AppTextStyles.bodyMedium,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
              ),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playlist: ${pl.name} — coming soon')),
              ),
            );
          },
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
          child: FloatingActionButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create playlist — coming soon')),
            ),
            backgroundColor: AppColors.accentViolet,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
