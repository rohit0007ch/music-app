import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';

class _FakePlaylistsRepository implements PlaylistsRepository {
  List<PlaylistRecord> stored = [];
  Object? throwOnLoad;
  Object? throwOnSave;
  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<PlaylistRecord>> load() async {
    loadCalls++;
    if (throwOnLoad != null) throw throwOnLoad!;
    return List<PlaylistRecord>.from(stored);
  }

  @override
  Future<void> saveAll(List<PlaylistRecord> playlists) async {
    saveCalls++;
    if (throwOnSave != null) throw throwOnSave!;
    stored = List<PlaylistRecord>.from(playlists);
  }
}

Track _local() => const Track(
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

Track _online() => const Track(
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
  group('PlaylistsState', () {
    late _FakePlaylistsRepository repo;
    late PlaylistsState state;
    var clock = 1000;

    setUp(() {
      repo = _FakePlaylistsRepository();
      clock = 1000;
      state = PlaylistsState(
        repository: repo,
        random: Random(1),
        clockMs: () => clock++,
      );
    });

    tearDown(() {
      state.dispose();
    });

    test('load populates playlists and clears loading', () async {
      repo.stored = [
        PlaylistRecord(
          id: 'pl_1',
          name: 'Seeded',
          paletteIndex: 0,
          createdAtMs: 1,
          updatedAtMs: 1,
        ),
      ];

      final pending = state.load();
      expect(state.loading, isTrue);
      await pending;

      expect(state.loading, isFalse);
      expect(state.loadedOnce, isTrue);
      expect(state.playlists.single.name, 'Seeded');
    });

    test('ignores concurrent load while already loading', () async {
      final first = state.load();
      final second = state.load();
      await Future.wait([first, second]);
      expect(repo.loadCalls, 1);
      expect(state.loading, isFalse);
    });

    test('create / rename / delete persist', () async {
      await state.load();

      final id = await state.create('  Night Drive  ');
      expect(id, isNotNull);
      expect(state.playlists.single.name, 'Night Drive');
      expect(state.playlistById(id!)!.tracks, isEmpty);

      expect(await state.rename(id, 'Evening'), isTrue);
      expect(state.playlistById(id)!.name, 'Evening');
      expect(state.playlistById(id)!.updatedAtMs, greaterThan(1000));

      expect(await state.delete(id), isTrue);
      expect(state.playlists, isEmpty);
      expect(repo.stored, isEmpty);
    });

    test('rejects blank playlist names', () async {
      await state.load();
      expect(await state.create('   '), isNull);
      expect(state.error, isNotNull);
      expect(state.playlists, isEmpty);

      final id = await state.create('Valid');
      expect(await state.rename(id!, '  '), isFalse);
      expect(state.playlistById(id)!.name, 'Valid');
    });

    test(
      'addTrack rejects duplicates without moving; removeTrack keeps order',
      () async {
        await state.load();
        final id = await state.create('Mix');
        expect(id, isNotNull);

        expect(await state.addTrack(id!, _local()), isTrue);
        expect(await state.addTrack(id, _online()), isTrue);
        expect(await state.addTrack(id, _local()), isTrue); // no-op duplicate

        final tracks = state.playlistById(id)!.tracks;
        expect(tracks.map((t) => t.id), ['local_7', 'online_99']);
        expect(repo.saveCalls, 3); // create + 2 adds (duplicate did not save)

        expect(await state.removeTrack(id, 'local_7'), isTrue);
        expect(state.playlistById(id)!.tracks.map((t) => t.id), ['online_99']);
      },
    );

    test('fresh state reloads persisted playlists (restart)', () async {
      await state.load();
      final id = await state.create('Persist Me');
      await state.addTrack(id!, _online());

      final second = PlaylistsState(repository: repo, random: Random(2));
      addTearDown(second.dispose);
      await second.load();

      expect(second.playlists, hasLength(1));
      expect(second.playlistById(id)!.tracks.single.id, 'online_99');
    });

    test('keeps local and online track IDs distinct', () async {
      await state.load();
      final id = await state.create('Both');
      await state.addTrack(
        id!,
        const Track(
          id: 'local_1',
          title: 'Same',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.local,
          localId: 1,
          localUri: 'content://media/1',
        ),
      );
      await state.addTrack(
        id,
        const Track(
          id: 'online_1',
          title: 'Same',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.online,
          streamUrl: 'https://cdn.example.com/1.mp3',
        ),
      );

      expect(state.playlistById(id)!.tracks, hasLength(2));
    });

    test(
      'save failure does not publish mutation or leave saving stuck',
      () async {
        await state.load();
        final id = await state.create('Keep');
        expect(id, isNotNull);

        repo.throwOnSave = const PlaylistsStorageException('write failed');
        final ok = await state.rename(id!, 'Nope');

        expect(ok, isFalse);
        expect(state.saving, isFalse);
        expect(state.error, 'write failed');
        expect(state.playlistById(id)!.name, 'Keep');
      },
    );

    test('load failure clears loading and reports error', () async {
      repo.throwOnLoad = Exception('disk');
      await state.load();
      expect(state.loading, isFalse);
      expect(state.loadedOnce, isTrue);
      expect(state.error, isNotNull);
      expect(state.playlists, isEmpty);
    });

    test('invalid playlist id operations fail gracefully', () async {
      await state.load();
      expect(await state.rename('missing', 'X'), isFalse);
      expect(await state.addTrack('missing', _online()), isFalse);
      expect(await state.removeTrack('missing', 'online_99'), isFalse);
      expect(await state.delete('missing'), isTrue);
    });
  });
}
