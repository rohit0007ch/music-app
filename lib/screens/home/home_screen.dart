import 'package:flutter/material.dart';
import 'package:melora_music/data/featured/featured_song.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/screens/library/playlist_detail_screen.dart';
import 'package:melora_music/screens/now_playing/sheets/lyrics_sheet.dart';
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

        // Featured song
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: FeaturedSongCard(
              playerState: playerState,
              onPlay: () => onTrackTap(FeaturedSong.track),
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

/// Premium featured-song card driven by the shared [PlayerState].
class FeaturedSongCard extends StatefulWidget {
  const FeaturedSongCard({
    super.key,
    required this.playerState,
    required this.onPlay,
  });

  final PlayerState playerState;
  final Future<void> Function() onPlay;

  @override
  State<FeaturedSongCard> createState() => FeaturedSongCardState();
}

@visibleForTesting
class FeaturedSongCardState extends State<FeaturedSongCard>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _pulseController;

  bool get _isCurrent =>
      FeaturedSong.isFeaturedId(widget.playerState.currentTrack?.id);

  bool get _isPlayingFeatured => _isCurrent && widget.playerState.isPlaying;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    widget.playerState.addListener(_syncAnimations);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimations());
  }

  @override
  void didUpdateWidget(covariant FeaturedSongCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerState != widget.playerState) {
      oldWidget.playerState.removeListener(_syncAnimations);
      widget.playerState.addListener(_syncAnimations);
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    widget.playerState.removeListener(_syncAnimations);
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _syncAnimations() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final playing = _isPlayingFeatured;

    if (reduceMotion) {
      _glowController.stop();
      _glowController.value = 0.35;
      _pulseController.stop();
      _pulseController.value = 0;
      return;
    }

    if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }

    if (playing) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onPlayPause() async {
    if (_isCurrent) {
      await widget.playerState.togglePlayPause();
      return;
    }
    await widget.onPlay();
  }

  void _openLyrics(BuildContext context) {
    if (!_isCurrent) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Play Dinesh Dalla first to view lyrics.'),
          ),
        );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsSheet(playerState: widget.playerState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = FeaturedSong.track;
    final palette = AppColors
        .artworkPalettes[track.paletteIndex % AppColors.artworkPalettes.length];

    return ListenableBuilder(
      listenable: widget.playerState,
      builder: (context, _) {
        final playing = _isPlayingFeatured;
        return AnimatedBuilder(
          animation: Listenable.merge([_glowController, _pulseController]),
          builder: (context, child) {
            final glowT = _glowController.value;
            final pulse = 1.0 + (_pulseController.value * 0.035);
            final glowAlpha = 0.22 + (glowT * 0.28);
            final borderAlpha = 0.35 + (glowT * 0.4);

            return Transform.scale(
              scale: playing ? pulse : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentViolet.withValues(
                        alpha: playing ? glowAlpha : glowAlpha * 0.45,
                      ),
                      blurRadius: playing ? 28 : 18,
                      spreadRadius: playing ? 1 : 0,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.accentVioletLight.withValues(
                        alpha: borderAlpha * (playing ? 1 : 0.55),
                      ),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        palette[0].withValues(alpha: 0.95),
                        AppColors.surfaceElevated,
                        palette[1].withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                MeloraArtwork(
                  paletteIndex: track.paletteIndex,
                  size: 108,
                  borderRadius: AppSpacing.radiusMd,
                  imageUrl: track.artworkUri,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentViolet.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              FeaturedSong.featuredLabel,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'Local Song',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        track.title,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _PlayPauseButton(
                            isPlaying: playing,
                            accent: palette[0],
                            onPressed: _onPlayPause,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Lyrics',
                            onPressed: () => _openLyrics(context),
                            icon: const Icon(
                              Icons.lyrics_outlined,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.accent,
    required this.onPressed,
  });

  final bool isPlaying;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isPlaying ? 'Pause' : 'Play',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
