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
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Root scaffold — owns bottom nav, mini-player, and the active screen.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _currentIndex = 0;
  final PlayerState _playerState = PlayerState();
  final LocalLibraryState _libraryState = LocalLibraryState();

  @override
  void dispose() {
    _playerState.dispose();
    _libraryState.dispose();
    super.dispose();
  }

  Future<void> _onTrackTap(Track track, {List<Track>? queueContext}) async {
    final started = await _playerState.playTrack(
      track,
      queueContext: queueContext,
    );
    if (!mounted) return;

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
        pageBuilder: (_, animation, _) =>
            NowPlayingScreen(playerState: _playerState),
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
              onTrackTap: (track) => _onTrackTap(track),
            ),
            DiscoverScreen(
              playerState: _playerState,
              onTrackTap: (track) => _onTrackTap(track),
            ),
            LibraryScreen(
              playerState: _playerState,
              libraryState: _libraryState,
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
