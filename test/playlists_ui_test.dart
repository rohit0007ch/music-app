import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';
import 'package:melora_music/screens/home/home_screen.dart';
import 'package:melora_music/screens/library/library_screen.dart';
import 'package:melora_music/screens/library/playlist_detail_screen.dart';
import 'package:melora_music/shared/widgets/add_to_playlist_sheet.dart';
import 'package:melora_music/theme/app_theme.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePlaylistsRepository implements PlaylistsRepository {
  List<PlaylistRecord> stored = [];
  Object? throwOnSave;

  @override
  Future<List<PlaylistRecord>> load() async =>
      List<PlaylistRecord>.from(stored);

  @override
  Future<void> saveAll(List<PlaylistRecord> playlists) async {
    if (throwOnSave != null) throw throwOnSave!;
    stored = List<PlaylistRecord>.from(playlists);
  }
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<List<FavoriteRecord>> load() async => const [];

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {}
}

Track _local({
  String id = 'local_1',
  int localId = 1,
  String title = 'Local Song',
  String? localUri = 'content://media/external/audio/media/1',
}) {
  return Track(
    id: id,
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSeconds: 120,
    paletteIndex: 0,
    source: TrackSource.local,
    localId: localId,
    localUri: localUri,
  );
}

Track _online({String id = 'online_9', String title = 'Online Song'}) {
  return Track(
    id: id,
    title: title,
    artist: 'Creator',
    album: 'Catalog',
    durationSeconds: 180,
    paletteIndex: 2,
    source: TrackSource.online,
    streamUrl: 'https://cdn.example.com/$id.mp3',
  );
}

Future<void> _openPlaylistsTab(WidgetTester tester) async {
  final tab = find.text('Playlists');
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _libraryApp({
  required PlayerState player,
  required LocalLibraryState library,
  required FavoritesState favorites,
  required PlaylistsState playlists,
  Future<void> Function(Track track, {List<Track>? queueContext})? onTrackTap,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: LibraryScreen(
        playerState: player,
        libraryState: library,
        favoritesState: favorites,
        playlistsState: playlists,
        onTrackTap: onTrackTap ?? (_, {queueContext}) async {},
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Library Playlists tab', () {
    testWidgets('shows empty state when nothing is saved', (tester) async {
      final playlists = PlaylistsState(repository: _FakePlaylistsRepository());
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();

      await tester.pumpWidget(
        _libraryApp(
          player: player,
          library: library,
          favorites: favorites,
          playlists: playlists,
        ),
      );
      await tester.pump();
      await _openPlaylistsTab(tester);

      expect(find.text('No playlists yet'), findsOneWidget);
      expect(find.text('Late Night Vibes'), findsNothing);
    });

    testWidgets('lists persisted playlists instead of mock data', (
      tester,
    ) async {
      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_real',
            name: 'Persisted Mix',
            paletteIndex: 1,
            createdAtMs: 1,
            updatedAtMs: 1,
            tracks: [PlaylistTrackRecord.fromTrack(_online())],
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();

      await tester.pumpWidget(
        _libraryApp(
          player: player,
          library: library,
          favorites: favorites,
          playlists: playlists,
        ),
      );
      await tester.pump();
      await _openPlaylistsTab(tester);

      expect(find.text('Persisted Mix'), findsOneWidget);
      expect(find.text('1 track'), findsOneWidget);
      expect(find.text('Late Night Vibes'), findsNothing);
      expect(find.text('Focus Mode'), findsNothing);
    });

    testWidgets('name dialog rejects blank names', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showPlaylistNameDialog(
                    context,
                    title: 'New playlist',
                    confirmLabel: 'Create',
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open dialog'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pump();
      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    testWidgets('create persists and list shows the new playlist', (
      tester,
    ) async {
      final repo = _FakePlaylistsRepository();
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();

      await tester.pumpWidget(
        _libraryApp(
          player: player,
          library: library,
          favorites: favorites,
          playlists: playlists,
        ),
      );
      await tester.pump();
      await _openPlaylistsTab(tester);

      final id = await playlists.create('Road Trip');
      expect(id, isNotNull);
      await tester.pump();

      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.text('No playlists yet'), findsNothing);
      expect(repo.stored.single.name, 'Road Trip');
    });

    testWidgets('create failure does not add a playlist', (tester) async {
      final repo = _FakePlaylistsRepository()
        ..throwOnSave = const PlaylistsStorageException('write failed');
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final id = await playlists.create('Nope');
      expect(id, isNull);
      expect(playlists.playlists, isEmpty);
      expect(playlists.error, 'write failed');
      expect(playlists.saving, isFalse);
    });
  });

  group('PlaylistDetailScreen', () {
    testWidgets('shows tracks in saved order and playable queue', (
      tester,
    ) async {
      final playlist = PlaylistRecord(
        id: 'pl_1',
        name: 'Ordered',
        paletteIndex: 0,
        createdAtMs: 1,
        updatedAtMs: 1,
        tracks: [
          PlaylistTrackRecord.fromTrack(_online(title: 'First')),
          PlaylistTrackRecord.fromTrack(
            _local(
              id: 'local_missing',
              localId: 99,
              title: 'Missing',
              localUri: null,
            ),
          ),
          PlaylistTrackRecord.fromTrack(
            _local(id: 'local_ok', localId: 2, title: 'Third'),
          ),
        ],
      );
      // Persist with URI for third; resolve against library songs.
      final repo = _FakePlaylistsRepository()
        ..stored = [
          playlist.copyWith(
            tracks: [
              playlist.tracks[0],
              PlaylistTrackRecord.fromTrack(
                _local(
                  id: 'local_missing',
                  localId: 99,
                  title: 'Missing',
                  localUri: 'content://media/99',
                ),
              ),
              PlaylistTrackRecord.fromTrack(
                _local(id: 'local_ok', localId: 2, title: 'Third'),
              ),
            ],
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      Track? played;
      List<Track>? queue;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlaylistDetailScreen(
            playlistId: 'pl_1',
            playlistsState: playlists,
            libraryState: library,
            playerState: player,
            onTrackTap: (track, {queueContext}) async {
              played = track;
              queue = queueContext;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Missing'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Unavailable'), findsNWidgets(2));

      await tester.tap(find.text('Play'));
      await tester.pump();

      // Library empty → both locals unavailable; only online is playable.
      expect(played?.id, 'online_9');
      expect(queue?.map((t) => t.id), ['online_9']);
    });

    testWidgets('play-all with no playable tracks leaves playback unchanged', (
      tester,
    ) async {
      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_1',
            name: 'Empty Playable',
            paletteIndex: 0,
            createdAtMs: 1,
            updatedAtMs: 1,
            tracks: [
              PlaylistTrackRecord.fromTrack(_local(title: 'Missing Local')),
            ],
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      player.debugSetCurrentTrack(_online(title: 'Keep Playing'));
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PlaylistDetailScreen(
              playlistId: 'pl_1',
              playlistsState: playlists,
              libraryState: library,
              playerState: player,
              onTrackTap: (_, {queueContext}) async {
                taps++;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(taps, 0);
      expect(player.currentTrack?.title, 'Keep Playing');
      expect(find.text('No playable songs in this playlist.'), findsOneWidget);
    });

    testWidgets('rename and delete persist', (tester) async {
      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_1',
            name: 'Old Name',
            paletteIndex: 0,
            createdAtMs: 1,
            updatedAtMs: 1,
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlaylistDetailScreen(
            playlistId: 'pl_1',
            playlistsState: playlists,
            libraryState: library,
            playerState: player,
            onTrackTap: (_, {queueContext}) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Rename'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playlists.playlistById('pl_1')!.name, 'New Name');

      await tester.tap(find.byTooltip('Delete'));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playlists.playlistById('pl_1'), isNull);
      expect(repo.stored, isEmpty);
    });

    testWidgets('remove track updates playlist only', (tester) async {
      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_1',
            name: 'Two Songs',
            paletteIndex: 0,
            createdAtMs: 1,
            updatedAtMs: 1,
            tracks: [
              PlaylistTrackRecord.fromTrack(_online(title: 'Keep')),
              PlaylistTrackRecord.fromTrack(
                _online(id: 'online_2', title: 'Remove Me'),
              ),
            ],
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: PlaylistDetailScreen(
            playlistId: 'pl_1',
            playlistsState: playlists,
            libraryState: library,
            playerState: player,
            onTrackTap: (_, {queueContext}) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Remove from playlist').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playlists.playlistById('pl_1')!.tracks.map((t) => t.id), [
        'online_9',
      ]);
      expect(find.text('Remove Me'), findsNothing);
      expect(find.text('Keep'), findsOneWidget);
    });
  });

  group('Favorites integration remains intact', () {
    testWidgets('Favourites tab still works with playlistsState required', (
      tester,
    ) async {
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();
      await favorites.add(_online(title: 'Fav Song'));

      final playlists = PlaylistsState(repository: _FakePlaylistsRepository());
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        _libraryApp(
          player: player,
          library: library,
          favorites: favorites,
          playlists: playlists,
        ),
      );
      await tester.pump();

      final favTab = find.text('Favourites');
      await tester.ensureVisible(favTab);
      await tester.tap(favTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fav Song'), findsOneWidget);
    });
  });

  group('Add to playlist sheet', () {
    testWidgets('adds track to existing playlist from sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_1',
            name: 'Road Trip',
            paletteIndex: 0,
            createdAtMs: 1,
            updatedAtMs: 1,
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final track = _online(title: 'Add Me');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddToPlaylistSheet(
                  context: context,
                  track: track,
                  playlistsState: playlists,
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.text('Road Trip'), findsOneWidget);

      await tester.tap(find.text('Road Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(playlists.playlistById('pl_1')!.tracks.map((t) => t.id), [
        'online_9',
      ]);
      expect(find.textContaining('Added to'), findsOneWidget);
    });

    testWidgets('Songs tab more opens track actions with add to playlist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final playlists = PlaylistsState(repository: _FakePlaylistsRepository());
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();

      await tester.pumpWidget(
        _libraryApp(
          player: player,
          library: library,
          favorites: favorites,
          playlists: playlists,
        ),
      );
      await tester.pump();

      final more = find.byIcon(Icons.more_vert_rounded);
      expect(more, findsWidgets);
      await tester.ensureVisible(more.first);
      await tester.tap(more.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.text('Add to favourites'), findsOneWidget);
    });
  });

  group('Home Your Playlists', () {
    testWidgets('shows empty hint when no playlists exist', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final playlists = PlaylistsState(repository: _FakePlaylistsRepository());
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomeScreen(
              playerState: player,
              libraryState: library,
              playlistsState: playlists,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      final section = find.text('Your Playlists');
      expect(section, findsOneWidget);
      await tester.ensureVisible(section);
      await tester.pump();

      expect(
        find.textContaining('Create playlists in Library'),
        findsOneWidget,
      );
      expect(find.text('Late Night Vibes'), findsNothing);
    });

    testWidgets('lists user playlists and opens detail on tap', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakePlaylistsRepository()
        ..stored = [
          PlaylistRecord(
            id: 'pl_home',
            name: 'Home Mix',
            paletteIndex: 2,
            createdAtMs: 1,
            updatedAtMs: 1,
            tracks: [PlaylistTrackRecord.fromTrack(_online())],
          ),
        ];
      final playlists = PlaylistsState(repository: repo);
      addTearDown(playlists.dispose);
      await playlists.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: HomeScreen(
              playerState: player,
              libraryState: library,
              playlistsState: playlists,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      final mix = find.text('Home Mix');
      expect(mix, findsOneWidget);
      await tester.ensureVisible(mix);
      await tester.pump();
      expect(find.text('1 track'), findsOneWidget);

      await tester.tap(mix);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(find.text('Home Mix'), findsWidgets);
    });
  });
}
