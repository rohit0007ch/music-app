import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';
import 'package:melora_music/screens/library/library_screen.dart';
import 'package:melora_music/services/local_library_service.dart';
import 'package:melora_music/theme/app_theme.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Track _local({
  required String id,
  required String title,
  String artist = 'Artist',
  String album = 'Album',
  int localId = 1,
}) {
  return Track(
    id: id,
    title: title,
    artist: artist,
    album: album,
    durationSeconds: 120,
    paletteIndex: 0,
    source: TrackSource.local,
    localId: localId,
    localUri: 'content://media/external/audio/media/$localId',
  );
}

class _FakeLocalLibraryService extends LocalLibraryService {
  _FakeLocalLibraryService()
    : super(channel: const MethodChannel('test/local_library'));

  LocalLibraryPermission status = LocalLibraryPermission.granted;
  List<Track> songs = const [];

  @override
  Future<LocalLibraryPermission> permissionStatus() async => status;

  @override
  Future<LocalLibraryPermission> ensurePermission() async => status;

  @override
  Future<bool> openSystemSettings() async => true;

  @override
  Future<List<Track>> loadSongs() async => songs;
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<List<FavoriteRecord>> load() async => const [];

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {}
}

class _FakePlaylistsRepository implements PlaylistsRepository {
  @override
  Future<List<PlaylistRecord>> load() async => const [];

  @override
  Future<void> saveAll(List<PlaylistRecord> playlists) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filterTracksByQuery', () {
    final tracks = [
      _local(id: 'local_1', title: 'Neon Dreams', artist: 'Aether'),
      _local(
        id: 'local_2',
        title: 'Static Rain',
        artist: 'Nox',
        album: 'Voltage',
      ),
      _local(id: 'local_3', title: 'Morning Light', artist: 'Lumis'),
    ];

    test('blank query returns all tracks', () {
      expect(filterTracksByQuery(tracks, ''), hasLength(3));
      expect(filterTracksByQuery(tracks, '   '), hasLength(3));
    });

    test('matches title case-insensitively', () {
      final result = filterTracksByQuery(tracks, 'neon');
      expect(result.map((t) => t.id), ['local_1']);
    });

    test('matches artist and album', () {
      expect(filterTracksByQuery(tracks, 'nox').map((t) => t.id), ['local_2']);
      expect(filterTracksByQuery(tracks, 'voltage').map((t) => t.id), [
        'local_2',
      ]);
    });

    test('returns empty when nothing matches', () {
      expect(filterTracksByQuery(tracks, 'zzzz'), isEmpty);
    });
  });

  group('Library Songs search UI', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpLibrary(
      WidgetTester tester, {
      required List<Track> songs,
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeLocalLibraryService()..songs = songs;
      final library = LocalLibraryState(service: service);
      addTearDown(library.dispose);
      await library.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();
      final playlists = PlaylistsState(repository: _FakePlaylistsRepository());
      addTearDown(playlists.dispose);
      await playlists.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LibraryScreen(
              playerState: player,
              libraryState: library,
              favoritesState: favorites,
              playlistsState: playlists,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('filters local songs as the query changes', (tester) async {
      await pumpLibrary(
        tester,
        songs: [
          _local(id: 'local_1', title: 'Alpha Song', localId: 1),
          _local(id: 'local_2', title: 'Beta Tune', localId: 2),
        ],
      );

      expect(find.text('Alpha Song'), findsOneWidget);
      expect(find.text('Beta Tune'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pump();

      expect(find.text('Alpha Song'), findsOneWidget);
      expect(find.text('Beta Tune'), findsNothing);
    });

    testWidgets('shows empty match state and clear restores list', (
      tester,
    ) async {
      await pumpLibrary(
        tester,
        songs: [
          _local(id: 'local_1', title: 'Alpha Song', localId: 1),
          _local(id: 'local_2', title: 'Beta Tune', localId: 2),
        ],
      );

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('No matching songs'), findsOneWidget);
      expect(find.text('Alpha Song'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('No matching songs'), findsNothing);
      expect(find.text('Alpha Song'), findsOneWidget);
      expect(find.text('Beta Tune'), findsOneWidget);
    });
  });
}
