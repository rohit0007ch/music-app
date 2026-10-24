import 'package:flutter/material.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/screens/discover/discover_screen.dart';
import 'package:melora_music/screens/downloads/downloads_screen.dart';
import 'package:melora_music/screens/home/home_screen.dart';
import 'package:melora_music/screens/library/library_screen.dart';
import 'package:melora_music/screens/now_playing/now_playing_screen.dart';
import 'package:melora_music/screens/profile/profile_screen.dart';
import 'package:melora_music/shared/widgets/melora_mini_player.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

/// Root scaffold — owns bottom nav, mini-player, and the active screen.
class RootScaffold extends StatefulWidget {
  const RootScaffold({
    super.key,
    this.playerState,
    this.libraryState,
    this.favoritesState,
    this.playlistsState,
  });

  /// Optional overrides for tests.
  final PlayerState? playerState;
  final LocalLibraryState? libraryState;
  final FavoritesState? favoritesState;
  final PlaylistsState? playlistsState;

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _currentIndex = 0;
  late final PlayerState _playerState;
  late final LocalLibraryState _libraryState;
  late final FavoritesState _favoritesState;
  late final PlaylistsState _playlistsState;
  late final bool _ownsPlayer;
  late final bool _ownsLibrary;
  late final bool _ownsFavorites;
  late final bool _ownsPlaylists;

  @override
  void initState() {
    super.initState();
    _ownsPlayer = widget.playerState == null;
    _ownsLibrary = widget.libraryState == null;
    _ownsFavorites = widget.favoritesState == null;
    _ownsPlaylists = widget.playlistsState == null;
    _playerState = widget.playerState ?? PlayerState();
    _libraryState = widget.libraryState ?? LocalLibraryState();
    _favoritesState = widget.favoritesState ?? FavoritesState();
    _playlistsState = widget.playlistsState ?? PlaylistsState();

    _favoritesState.addListener(_syncFavouriteFlags);
    // Fire-and-forget; Favourites tab / heart react via listeners.
    _favoritesState.load().then((_) {
      if (!mounted) return;
      _syncFavouriteFlags();
    });
    // Fire-and-forget; Playlists tab reacts via listeners.
    _playlistsState.load();
  }

  void _syncFavouriteFlags() {
    _playerState.syncFavouriteFlags(_favoritesState.isFavorite);
  }

  @override
  void dispose() {
    _favoritesState.removeListener(_syncFavouriteFlags);
    if (_ownsPlayer) _playerState.dispose();
    if (_ownsLibrary) _libraryState.dispose();
    if (_ownsFavorites) _favoritesState.dispose();
    if (_ownsPlaylists) _playlistsState.dispose();
    super.dispose();
  }

  Future<void> _onTrackTap(Track track, {List<Track>? queueContext}) async {
    final started = await _playerState.playTrack(
      track,
      queueContext: queueContext,
    );
    if (!mounted) return;

    _syncFavouriteFlags();

    final message = _playerState.takeUserMessage();
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    // Open Now Playing when playback started, or when browsing a demo track.
    // If a playable track was protected, stay put (snackbar only).
    if (started || _playerState.currentTrack?.id == track.id) {
      _openNowPlaying();
    }
  }

  void _showPlayerMessageIfAny() {
    final message = _playerState.takeUserMessage();
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openNowPlaying() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => NowPlayingScreen(
          playerState: _playerState,
          favoritesState: _favoritesState,
          playlistsState: _playlistsState,
        ),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              playerState: _playerState,
              libraryState: _libraryState,
              playlistsState: _playlistsState,
              onTrackTap: _onTrackTap,
            ),
            DiscoverScreen(
              playerState: _playerState,
              favoritesState: _favoritesState,
              playlistsState: _playlistsState,
              onTrackTap: _onTrackTap,
            ),
            LibraryScreen(
              playerState: _playerState,
              libraryState: _libraryState,
              favoritesState: _favoritesState,
              playlistsState: _playlistsState,
              onTrackTap: _onTrackTap,
            ),
            DownloadsScreen(
              playerState: _playerState,
              onTrackTap: (track) => _onTrackTap(track),
            ),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListenableBuilder(
            listenable: _playerState,
            builder: (context, _) {
              if (_playerState.currentTrack == null) {
                return const SizedBox.shrink();
              }
              return MeloraMiniPlayer(
                playerState: _playerState,
                onTap: _openNowPlaying,
                onControlMessage: _showPlayerMessageIfAny,
              );
            },
          ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.download_outlined),
                selectedIcon: Icon(Icons.download_rounded),
                label: 'Downloads',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
