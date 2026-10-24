import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/screens/library/playlist_detail_screen.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/shared/widgets/melora_card.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
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

  void _openPlaylist(BuildContext context, String playlistId) {
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
    final recentTracks = MockData.tracks.take(5).toList();
    final featuredTrack = MockData.tracks[2];
    final topTracks = MockData.tracks.skip(5).take(5).toList();

    return CustomScrollView(
      slivers: [
        // Greeting header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good Evening 👋', style: AppTextStyles.bodyMedium),
                      Text(
                        'What are you\nfeeling today?',
                        style: AppTextStyles.displayMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.artworkPalettes[0],
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: _FeaturedCard(
              track: featuredTrack,
              onTap: () => onTrackTap(featuredTrack),
            ),
          ),
        ),

        // Recently Played
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text('Recently Played', style: AppTextStyles.headlineLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: AppSpacing.artworkCardSize + 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: recentTracks.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final t = recentTracks[i];
                return _ArtworkCard(track: t, onTap: () => onTrackTap(t));
              },
            ),
          ),
        ),

        // Your Playlists
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text('Your Playlists', style: AppTextStyles.headlineLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: playlistsState,
            builder: (context, _) {
              final playlists = playlistsState.playlists;
              if (playlists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'Create playlists in Library to see them here.',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              return SizedBox(
                height: AppSpacing.artworkCardSize + 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: playlists.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) => _PlaylistCard(
                    playlist: playlists[i],
                    onTap: () => _openPlaylist(context, playlists[i].id),
                  ),
                ),
              );
            },
          ),
        ),

        // Top Tracks
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Top Tracks', style: AppTextStyles.headlineLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon'))),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            final t = topTracks[i];
            return ListenableBuilder(
              listenable: playerState,
              builder: (context, _) => MeloraTrackTile(
                track: t,
                isPlaying: playerState.currentTrack?.id == t.id,
                onTap: () => onTrackTap(t),
              ),
            );
          }, childCount: topTracks.length),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.track, required this.onTap});
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors
        .artworkPalettes[track.paletteIndex % AppColors.artworkPalettes.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            colors: [palette[0], palette[1]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: palette[0],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Play Now',
                          style: TextStyle(
                            color: palette[0],
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.track, required this.onTap});
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppSpacing.artworkCardSize,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MeloraArtwork(paletteIndex: track.paletteIndex),
            const SizedBox(height: AppSpacing.sm),
            Text(
              track.title,
              style: AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track.artist,
              style: AppTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});
  final PlaylistRecord playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MeloraCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        width: AppSpacing.artworkCardSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: MeloraArtwork(
                paletteIndex: playlist.paletteIndex,
                size: AppSpacing.artworkCardSize,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.trackCount} '
                    '${playlist.trackCount == 1 ? 'track' : 'tracks'}',
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
