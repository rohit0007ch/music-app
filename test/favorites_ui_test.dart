import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/screens/library/library_screen.dart';
import 'package:melora_music/screens/now_playing/now_playing_screen.dart';
import 'package:melora_music/theme/app_theme.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  List<FavoriteRecord> stored = [];
  Object? throwOnSave;

  @override
  Future<List<FavoriteRecord>> load() async =>
      List<FavoriteRecord>.from(stored);

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {
    if (throwOnSave != null) throw throwOnSave!;
    stored = List<FavoriteRecord>.from(records);
  }
}

Track _playableLocal({
  String id = 'local_1',
  int localId = 1,
  String title = 'Saved Local',
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
    localUri: 'content://media/external/audio/media/$localId',
  );
}

Track _online({String id = 'online_9', String title = 'Jamendo Hit'}) {
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

Future<void> _openFavouritesTab(WidgetTester tester) async {
  final tab = find.text('Favourites');
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('resolveFavoriteForDisplay', () {
    test('uses live library metadata when local ID matches', () {
      final record = FavoriteRecord.fromTrack(
        _playableLocal(title: 'Stale Title'),
      );
      final live = _playableLocal(title: 'Fresh Title');
      final resolved = resolveFavoriteForDisplay(record, [live]);
      expect(resolved.title, 'Fresh Title');
      expect(resolved.isPlayable, isTrue);
      expect(resolved.isFavourite, isTrue);
    });

    test('missing local file stays saved but is not playable', () {
      final record = FavoriteRecord.fromTrack(_playableLocal());
      final resolved = resolveFavoriteForDisplay(record, const []);
      expect(resolved.id, 'local_1');
      expect(resolved.isFavourite, isTrue);
      expect(resolved.isPlayable, isFalse);
      expect(resolved.localUri, isNull);
    });

    test('keeps local and online IDs distinct', () {
      final local = FavoriteRecord.fromTrack(_playableLocal(id: 'local_1'));
      final online = FavoriteRecord.fromTrack(_online(id: 'online_1'));
      expect(local.id, isNot(online.id));
      expect(
        resolveFavoriteForDisplay(local, const []).source,
        TrackSource.local,
      );
      expect(
        resolveFavoriteForDisplay(online, const []).source,
        TrackSource.online,
      );
    });
  });

  group('MeloraPlayerState.syncFavouriteFlags', () {
    test('updates flags without changing queue order', () async {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      final a = _playableLocal(id: 'local_a', localId: 10, title: 'A');
      final b = _online(id: 'online_b', title: 'B');
      player.debugSetCurrentTrack(a);
      player.setQueue([a, b]);

      final idsBefore = player.queue.map((t) => t.id).toList();
      player.syncFavouriteFlags((id) => id == 'online_b');

      expect(player.queue.map((t) => t.id), idsBefore);
      expect(player.currentTrack!.isFavourite, isFalse);
      expect(player.queue[0].isFavourite, isFalse);
      expect(player.queue[1].isFavourite, isTrue);
    });
  });

  group('Now Playing heart', () {
    Future<void> setPhoneSurface(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('reflects saved status and toggles persistence', (
      tester,
    ) async {
      await setPhoneSurface(tester);

      final repo = _FakeFavoritesRepository();
      final favorites = FavoritesState(repository: repo);
      addTearDown(favorites.dispose);
      await favorites.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final track = _online();
      player.debugSetCurrentTrack(track);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: NowPlayingScreen(
            playerState: player,
            favoritesState: favorites,
          ),
        ),
      );
      await tester.pump();

      final outlineHeart = find.byIcon(Icons.favorite_border_rounded);
      expect(outlineHeart, findsOneWidget);
      await tester.ensureVisible(outlineHeart);
      await tester.tap(outlineHeart);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(favorites.isFavorite('online_9'), isTrue);
      expect(repo.stored.map((r) => r.id), ['online_9']);
      expect(player.currentTrack!.isFavourite, isTrue);

      final filledHeart = find.byIcon(Icons.favorite_rounded);
      expect(filledHeart, findsWidgets);
      await tester.ensureVisible(filledHeart.first);
      await tester.tap(filledHeart.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(favorites.isFavorite('online_9'), isFalse);
      expect(repo.stored, isEmpty);
      expect(player.currentTrack!.isFavourite, isFalse);
    });

    testWidgets('storage error shows snackbar and does not claim success', (
      tester,
    ) async {
      await setPhoneSurface(tester);

      final repo = _FakeFavoritesRepository()
        ..throwOnSave = const FavoritesStorageException('write failed');
      final favorites = FavoritesState(repository: repo);
      addTearDown(favorites.dispose);
      await favorites.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      player.debugSetCurrentTrack(_online());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: NowPlayingScreen(
              playerState: player,
              favoritesState: favorites,
            ),
          ),
        ),
      );
      await tester.pump();

      final outlineHeart = find.byIcon(Icons.favorite_border_rounded);
      await tester.ensureVisible(outlineHeart);
      await tester.tap(outlineHeart);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(favorites.isFavorite('online_9'), isFalse);
      expect(find.text('write failed'), findsOneWidget);
      expect(favorites.saving, isFalse);
    });
  });

  group('Library Favourites tab', () {
    testWidgets('shows empty state when nothing is saved', (tester) async {
      final favorites = FavoritesState(repository: _FakeFavoritesRepository());
      addTearDown(favorites.dispose);
      await favorites.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LibraryScreen(
              playerState: player,
              libraryState: library,
              favoritesState: favorites,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();
      await _openFavouritesTab(tester);

      expect(find.text('No favourites yet'), findsOneWidget);
    });

    testWidgets('lists persisted favorites instead of mock data', (
      tester,
    ) async {
      final repo = _FakeFavoritesRepository()
        ..stored = [
          FavoriteRecord.fromTrack(_online(title: 'Persisted Jamendo')),
          FavoriteRecord.fromTrack(_playableLocal(title: 'Persisted Local')),
        ];
      final favorites = FavoritesState(repository: repo);
      addTearDown(favorites.dispose);
      await favorites.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LibraryScreen(
              playerState: player,
              libraryState: library,
              favoritesState: favorites,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();
      await _openFavouritesTab(tester);

      expect(find.text('Persisted Jamendo'), findsOneWidget);
      expect(find.text('Persisted Local'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('No favourites yet'), findsNothing);
    });

    testWidgets('updates list after add and remove', (tester) async {
      final repo = _FakeFavoritesRepository();
      final favorites = FavoritesState(repository: repo);
      addTearDown(favorites.dispose);
      await favorites.load();

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final library = LocalLibraryState();
      addTearDown(library.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LibraryScreen(
              playerState: player,
              libraryState: library,
              favoritesState: favorites,
              onTrackTap: (_, {queueContext}) async {},
            ),
          ),
        ),
      );
      await tester.pump();
      await _openFavouritesTab(tester);

      expect(find.text('No favourites yet'), findsOneWidget);

      await favorites.add(_online(title: 'After Add'));
      await tester.pump();

      expect(find.text('After Add'), findsOneWidget);
      expect(find.text('No favourites yet'), findsNothing);

      await favorites.remove('online_9');
      await tester.pump();

      expect(find.text('After Add'), findsNothing);
      expect(find.text('No favourites yet'), findsOneWidget);
    });
  });
}
