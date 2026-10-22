import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

FavoriteRecord _local() => FavoriteRecord.fromTrack(
  const Track(
    id: 'local_42',
    title: 'Local Song',
    artist: 'Device',
    album: 'Phone',
    durationSeconds: 120,
    paletteIndex: 2,
    source: TrackSource.local,
    localId: 42,
    localUri: 'content://media/external/audio/media/42',
  ),
);

FavoriteRecord _online() => FavoriteRecord.fromTrack(
  const Track(
    id: 'online_1848357',
    title: 'Jamendo Song',
    artist: 'Creator',
    album: 'Album',
    durationSeconds: 200,
    paletteIndex: 4,
    source: TrackSource.online,
    streamUrl:
        'https://prod-1.storage.jamendo.com/?trackid=1848357&format=mp32',
    artworkUri: 'https://img.jamendo.com/cover.jpg',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesFavoritesRepository', () {
    test('saveAll / load round trip preserves order and fields', () async {
      final repo = SharedPreferencesFavoritesRepository();
      final records = [_local(), _online()];

      await repo.saveAll(records);
      final loaded = await repo.load();

      expect(loaded.map((r) => r.id), ['local_42', 'online_1848357']);
      expect(loaded[0].localUri, _local().localUri);
      expect(loaded[1].streamUrl, _online().streamUrl);
      expect(loaded[1].artworkUri, _online().artworkUri);
    });

    test('load returns empty for missing key', () async {
      final repo = SharedPreferencesFavoritesRepository();
      expect(await repo.load(), isEmpty);
    });

    test('load returns empty for malformed JSON string', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesFavoritesRepository.storageKey: '{not-json',
      });
      final repo = SharedPreferencesFavoritesRepository();
      expect(await repo.load(), isEmpty);
    });

    test('load skips invalid records and keeps valid ones', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesFavoritesRepository.storageKey: '''
[
  {"id":"online_1","source":"online","title":"Ok","artist":"A","album":"B","durationSeconds":10,"paletteIndex":1,"streamUrl":"https://x/a.mp3"},
  {"id":"","source":"online"},
  "not-an-object",
  {"id":"local_2","source":"bogus"},
  {"id":"local_3","source":"local","title":"Kept","artist":"A","album":"B","durationSeconds":5,"paletteIndex":0,"localId":3,"localUri":"content://media/3"}
]
''',
      });
      final repo = SharedPreferencesFavoritesRepository();
      final loaded = await repo.load();
      expect(loaded.map((r) => r.id), ['online_1', 'local_3']);
    });

    test('load deduplicates by id preserving first occurrence', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesFavoritesRepository.storageKey: '''
[
  {"id":"online_1","source":"online","title":"First","artist":"A","album":"B","durationSeconds":1,"paletteIndex":0},
  {"id":"online_1","source":"online","title":"Second","artist":"A","album":"B","durationSeconds":1,"paletteIndex":0}
]
''',
      });
      final repo = SharedPreferencesFavoritesRepository();
      final loaded = await repo.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'First');
    });

    test('removal persists across a new repository instance', () async {
      final first = SharedPreferencesFavoritesRepository();
      await first.saveAll([_local(), _online()]);
      await first.saveAll([_online()]);

      final second = SharedPreferencesFavoritesRepository();
      final loaded = await second.load();
      expect(loaded.map((r) => r.id), ['online_1848357']);
    });
  });
}
