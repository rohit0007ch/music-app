import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  List<FavoriteRecord> stored = [];
  Object? throwOnLoad;
  Object? throwOnSave;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<FavoriteRecord>> load() async {
    loadCalls++;
    if (throwOnLoad != null) throw throwOnLoad!;
    return List<FavoriteRecord>.from(stored);
  }

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {
    saveCalls++;
    if (throwOnSave != null) throw throwOnSave!;
    stored = List<FavoriteRecord>.from(records);
  }
}

Track _localTrack() => const Track(
  id: 'local_7',
  title: 'Local',
  artist: 'A',
  album: 'B',
  durationSeconds: 90,
  paletteIndex: 1,
  source: TrackSource.local,
  localId: 7,
  localUri: 'content://media/external/audio/media/7',
);

Track _onlineTrack() => const Track(
  id: 'online_99',
  title: 'Online',
  artist: 'C',
  album: 'D',
  durationSeconds: 110,
  paletteIndex: 2,
  source: TrackSource.online,
  streamUrl: 'https://cdn.example.com/99.mp3',
);

void main() {
  group('FavoritesState', () {
    test('load populates favorites and clears loading', () async {
      final repo = _FakeFavoritesRepository()
        ..stored = [FavoriteRecord.fromTrack(_localTrack())];
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);

      expect(state.loading, isFalse);
      final pending = state.load();
      expect(state.loading, isTrue);
      await pending;

      expect(state.loading, isFalse);
      expect(state.loadedOnce, isTrue);
      expect(state.error, isNull);
      expect(state.isFavorite('local_7'), isTrue);
      expect(state.tracks.single.isFavourite, isTrue);
    });

    test('ignores concurrent load while already loading', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);

      final first = state.load();
      final second = state.load();
      await Future.wait([first, second]);

      expect(repo.loadCalls, 1);
      expect(state.loading, isFalse);
      expect(state.loadedOnce, isTrue);
    });

    test('add does not duplicate; refreshes metadata in place', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();

      await state.add(_onlineTrack());
      await state.add(
        _onlineTrack().copyWith(
          title: 'Updated',
          streamUrl: 'https://cdn.example.com/new.mp3',
        ),
      );

      expect(state.favorites, hasLength(1));
      expect(state.favorites.single.title, 'Updated');
      expect(
        state.favorites.single.streamUrl,
        'https://cdn.example.com/new.mp3',
      );
      expect(repo.stored, hasLength(1));
    });

    test('remove persists and isFavorite becomes false', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();

      await state.add(_localTrack());
      await state.add(_onlineTrack());
      await state.remove('local_7');

      expect(state.isFavorite('local_7'), isFalse);
      expect(state.isFavorite('online_99'), isTrue);
      expect(repo.stored.map((r) => r.id), ['online_99']);
    });

    test(
      'fresh state instance reloads persisted favorites (restart)',
      () async {
        final repo = _FakeFavoritesRepository();
        final first = FavoritesState(repository: repo);
        addTearDown(first.dispose);
        await first.load();
        await first.add(_localTrack());
        await first.add(_onlineTrack());

        final second = FavoritesState(repository: repo);
        addTearDown(second.dispose);
        await second.load();

        expect(second.favorites.map((r) => r.id), ['local_7', 'online_99']);
        expect(second.isFavorite('local_7'), isTrue);
        expect(second.isFavorite('online_99'), isTrue);
      },
    );

    test('toggle adds then removes and notifies listeners', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();

      var notifications = 0;
      state.addListener(() => notifications++);

      await state.toggle(_onlineTrack());
      expect(state.isFavorite('online_99'), isTrue);
      expect(notifications, greaterThan(0));

      final beforeRemove = notifications;
      await state.toggle(_onlineTrack());
      expect(state.isFavorite('online_99'), isFalse);
      expect(notifications, greaterThan(beforeRemove));
    });

    test('load failure sets error and clears loading', () async {
      final repo = _FakeFavoritesRepository()..throwOnLoad = Exception('disk');
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);

      await state.load();

      expect(state.loading, isFalse);
      expect(state.loadedOnce, isTrue);
      expect(state.error, isNotNull);
      expect(state.favorites, isEmpty);
    });

    test('save failure keeps previous list and reports error', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();
      await state.add(_localTrack());

      repo.throwOnSave = const FavoritesStorageException('write failed');
      final ok = await state.add(_onlineTrack());

      expect(ok, isFalse);
      expect(state.saving, isFalse);
      expect(state.error, 'write failed');
      expect(state.favorites.map((r) => r.id), ['local_7']);
      expect(state.isFavorite('online_99'), isFalse);
    });

    test('toggle returns true only after successful persist', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();

      expect(await state.toggle(_onlineTrack()), isTrue);
      expect(state.isFavorite('online_99'), isTrue);
      expect(await state.toggle(_onlineTrack()), isTrue);
      expect(state.isFavorite('online_99'), isFalse);
    });

    test('keeps local and Jamendo IDs distinct in the list', () async {
      final repo = _FakeFavoritesRepository();
      final state = FavoritesState(repository: repo);
      addTearDown(state.dispose);
      await state.load();

      await state.add(
        const Track(
          id: 'local_1',
          title: 'Same Title',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.local,
          localId: 1,
          localUri: 'content://media/1',
        ),
      );
      await state.add(
        const Track(
          id: 'online_1',
          title: 'Same Title',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.online,
          streamUrl: 'https://cdn.example.com/1.mp3',
        ),
      );

      expect(state.favorites, hasLength(2));
      expect(state.isFavorite('local_1'), isTrue);
      expect(state.isFavorite('online_1'), isTrue);
    });
  });
}
