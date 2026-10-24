import 'package:flutter/material.dart';
import 'package:melora_music/screens/now_playing/sheets/equalizer_sheet.dart';
import 'package:melora_music/screens/now_playing/sheets/lyrics_sheet.dart';
import 'package:melora_music/screens/now_playing/sheets/queue_sheet.dart';
import 'package:melora_music/screens/now_playing/sheets/sleep_timer_dialog.dart';
import 'package:melora_music/screens/now_playing/widgets/artwork_hero.dart';
import 'package:melora_music/screens/now_playing/widgets/playback_controls.dart';
import 'package:melora_music/screens/now_playing/widgets/progress_bar_widget.dart';
import 'package:melora_music/shared/widgets/add_to_playlist_sheet.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    super.key,
    required this.playerState,
    required this.favoritesState,
    required this.playlistsState,
  });

  final PlayerState playerState;
  final FavoritesState favoritesState;
  final PlaylistsState playlistsState;

  void _showQueue(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QueueSheet(playerState: playerState),
  );

  void _showLyrics(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LyricsSheet(playerState: playerState),
  );

  void _showSleepTimer(BuildContext context) => showDialog(
    context: context,
    builder: (_) => SleepTimerDialog(playerState: playerState),
  );

  void _showEqualizer(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const EqualizerSheet(),
  );

  Future<void> _onFavouritePressed(BuildContext context) async {
    final track = playerState.currentTrack;
    if (track == null || favoritesState.saving) return;

    final ok = await favoritesState.toggle(track);
    playerState.syncFavouriteFlags(favoritesState.isFavorite);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              favoritesState.error ?? 'Could not update favorites.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: Listenable.merge([playerState, favoritesState]),
        builder: (context, _) {
          final track = playerState.currentTrack;
          if (track == null) return const SizedBox.shrink();

          final isFavourite = favoritesState.isFavorite(track.id);
          final palette =
              AppColors.artworkPalettes[track.paletteIndex %
                  AppColors.artworkPalettes.length];

          return Stack(
            children: [
              // Cinematic gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette[0].withValues(alpha: 0.35),
                        AppColors.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                            color: AppColors.textPrimary,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Now Playing',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  track.album,
                                  style: AppTextStyles.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            onPressed: () => showAddToPlaylistSheet(
                              context: context,
                              track: track,
                              playlistsState: playlistsState,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Artwork
                    ArtworkHero(
                      paletteIndex: track.paletteIndex,
                      isPlaying: playerState.isPlaying,
                    ),

                    const Spacer(),

                    // Title + Favourite
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: AppTextStyles.displayMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artist,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavourite
                                  ? AppColors.accentAmber
                                  : AppColors.textDisabled,
                              size: 26,
                            ),
                            onPressed: favoritesState.saving
                                ? null
                                : () => _onFavouritePressed(context),
                          ),
                        ],
                      ),
                    ),

                    if (!track.isPlayable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          MeloraPlayerState.demoNotPlayableMessage,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accentAmber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    ProgressBarWidget(playerState: playerState),
                    const SizedBox(height: AppSpacing.md),
                    PlaybackControls(playerState: playerState),
                    const SizedBox(height: AppSpacing.lg),

                    // Bottom action row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BottomAction(
                            icon: Icons.queue_music_rounded,
                            label: 'Queue',
                            onTap: () => _showQueue(context),
                          ),
                          _BottomAction(
                            icon: Icons.lyrics_rounded,
                            label: 'Lyrics',
                            onTap: () => _showLyrics(context),
                          ),
                          _BottomAction(
                            icon: Icons.bedtime_rounded,
                            label: 'Sleep',
                            onTap: () => _showSleepTimer(context),
                            isActive: playerState.sleepTimerMinutes != null,
                          ),
                          _BottomAction(
                            icon: Icons.graphic_eq_rounded,
                            label: 'EQ',
                            onTap: () => _showEqualizer(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.accentViolet : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive
                  ? AppColors.accentVioletLight
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
