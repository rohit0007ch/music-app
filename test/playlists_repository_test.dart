import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlaylistRecord _playlist({
  required String id,
  required String name,
  List<PlaylistTrackRecord> tracks = const [],
  int createdAtMs = 10,
  int updatedAtMs = 20,
}) {
  return PlaylistRecord(
    id: id,
    name: name,
    paletteIndex: 1,
    createdAtMs: createdAtMs,
    updatedAtMs: updatedAtMs,
    tracks: tracks,
  );
}

PlaylistTrackRecord _localTrack() => PlaylistTrackRecord.fromTrack(
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

PlaylistTrackRecord _onlineTrack() => PlaylistTrackRecord.fromTrack(
  const Track(
    id: 'online_99',
    title: 'Online Song',
    artist: 'Creator',
    album: 'Catalog',
    durationSeconds: 200,
    paletteIndex: 4,
    source: TrackSource.online,
    streamUrl: 'https://cdn.example.com/99.mp3',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesPlaylistsRepository', () {
    test(
      'saveAll / load round trip preserves playlist and track order',
      () async {
        final repo = SharedPreferencesPlaylistsRepository();
        final playlists = [
          _playlist(
            id: 'pl_a',
            name: 'A',
            tracks: [_localTrack(), _onlineTrack()],
          ),
          _playlist(id: 'pl_b', name: 'B'),
        ];

        await repo.saveAll(playlists);
        final loaded = await repo.load();

        expect(loaded.map((p) => p.id), ['pl_a', 'pl_b']);
        expect(loaded.first.tracks.map((t) => t.id), ['local_42', 'online_99']);
        expect(loaded.last.tracks, isEmpty);
      },
    );

    test('load returns empty for missing key', () async {
      final repo = SharedPreferencesPlaylistsRepository();
      expect(await repo.load(), isEmpty);
    });

    test('load returns empty for malformed JSON', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlaylistsRepository.storageKey: '{not-json',
      });
      final repo = SharedPreferencesPlaylistsRepository();
      expect(await repo.load(), isEmpty);
    });

    test('load skips invalid playlists and keeps valid ones', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlaylistsRepository.storageKey: '''
[
  {"id":"pl_ok","name":"Ok","paletteIndex":0,"createdAtMs":1,"updatedAtMs":1,"tracks":[]},
  {"id":"","name":"Bad","createdAtMs":1,"updatedAtMs":1,"tracks":[]},
  "not-an-object",
  {"id":"pl_ok","name":"Dup","paletteIndex":0,"createdAtMs":1,"updatedAtMs":1,"tracks":[]}
]
''',
      });
      final repo = SharedPreferencesPlaylistsRepository();
      final loaded = await repo.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'pl_ok');
      expect(loaded.single.name, 'Ok');
    });

    test('does not overwrite favorites storage key', () async {
      final favorites = SharedPreferencesFavoritesRepository();
      final playlists = SharedPreferencesPlaylistsRepository();

      await favorites.saveAll(const []);
      await playlists.saveAll([_playlist(id: 'pl_1', name: 'Mine')]);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(SharedPreferencesFavoritesRepository.storageKey),
        isTrue,
      );
      expect(
        prefs.containsKey(SharedPreferencesPlaylistsRepository.storageKey),
        isTrue,
      );
      expect(
        SharedPreferencesPlaylistsRepository.storageKey,
        isNot(SharedPreferencesFavoritesRepository.storageKey),
      );
      expect(
        prefs.getString(SharedPreferencesFavoritesRepository.storageKey),
        '[]',
      );
      expect(
        prefs.getString(SharedPreferencesPlaylistsRepository.storageKey),
        contains('pl_1'),
      );
    });
  });
}
