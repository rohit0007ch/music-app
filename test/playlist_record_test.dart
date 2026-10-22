import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';

void main() {
  group('PlaylistTrackRecord', () {
    test('fromTrack / toJson / tryFromJson round trip', () {
      final record = PlaylistTrackRecord.fromTrack(
        const Track(
          id: 'online_42',
          title: 'Aurora',
          artist: 'Nova',
          album: 'Skies',
          durationSeconds: 180,
          paletteIndex: 3,
          source: TrackSource.online,
          streamUrl: 'https://cdn.example.com/a.mp3',
          artworkUri: 'https://cdn.example.com/a.jpg',
          licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
          genre: 'Electronic',
        ),
      );

      final parsed = PlaylistTrackRecord.tryFromJson(record.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.id, 'online_42');
      expect(parsed.source, TrackSource.online);
      expect(parsed.streamUrl, 'https://cdn.example.com/a.mp3');
      expect(parsed.toTrack().isFavourite, isFalse);
    });

    test('tryFromJson returns null for invalid tracks', () {
      expect(PlaylistTrackRecord.tryFromJson(null), isNull);
      expect(
        PlaylistTrackRecord.tryFromJson({'id': '', 'source': 'local'}),
        isNull,
      );
      expect(
        PlaylistTrackRecord.tryFromJson({'id': 'x', 'source': 'nope'}),
        isNull,
      );
    });
  });

  group('PlaylistRecord', () {
    test('toJson / tryFromJson preserves order and fields', () {
      final record = PlaylistRecord(
        id: 'pl_1',
        name: 'Focus',
        paletteIndex: 2,
        createdAtMs: 100,
        updatedAtMs: 200,
        tracks: [
          PlaylistTrackRecord.fromTrack(
            const Track(
              id: 'local_1',
              title: 'A',
              artist: 'B',
              album: 'C',
              durationSeconds: 10,
              paletteIndex: 0,
              source: TrackSource.local,
              localId: 1,
              localUri: 'content://media/1',
            ),
          ),
          PlaylistTrackRecord.fromTrack(
            const Track(
              id: 'online_2',
              title: 'D',
              artist: 'E',
              album: 'F',
              durationSeconds: 20,
              paletteIndex: 1,
              source: TrackSource.online,
              streamUrl: 'https://cdn.example.com/2.mp3',
            ),
          ),
        ],
      );

      final parsed = PlaylistRecord.tryFromJson(record.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.name, 'Focus');
      expect(parsed.tracks.map((t) => t.id), ['local_1', 'online_2']);
      expect(parsed.toPlaylist().trackCount, 2);
    });

    test('tryFromJson skips bad tracks and keeps valid siblings', () {
      final parsed = PlaylistRecord.tryFromJson({
        'id': 'pl_ok',
        'name': 'Mixed',
        'paletteIndex': 1,
        'createdAtMs': 1,
        'updatedAtMs': 2,
        'tracks': [
          {
            'id': 'online_1',
            'source': 'online',
            'title': 'Keep',
            'artist': 'A',
            'album': 'B',
            'durationSeconds': 1,
            'paletteIndex': 0,
            'streamUrl': 'https://x/a.mp3',
          },
          {'id': '', 'source': 'online'},
          'not-a-map',
          {
            'id': 'online_1',
            'source': 'online',
            'title': 'Dup',
            'artist': 'A',
            'album': 'B',
            'durationSeconds': 1,
            'paletteIndex': 0,
          },
        ],
      });
      expect(parsed, isNotNull);
      expect(parsed!.tracks.map((t) => t.id), ['online_1']);
      expect(parsed.tracks.single.title, 'Keep');
    });

    test('tryFromJson returns null for invalid playlist shells', () {
      expect(PlaylistRecord.tryFromJson(null), isNull);
      expect(
        PlaylistRecord.tryFromJson({
          'id': '',
          'name': 'X',
          'createdAtMs': 1,
          'updatedAtMs': 1,
        }),
        isNull,
      );
      expect(
        PlaylistRecord.tryFromJson({
          'id': 'pl_1',
          'name': '  ',
          'createdAtMs': 1,
          'updatedAtMs': 1,
        }),
        isNull,
      );
      expect(
        PlaylistRecord.tryFromJson({
          'id': 'pl_1',
          'name': 'X',
          'createdAtMs': -1,
          'updatedAtMs': 1,
        }),
        isNull,
      );
    });

    test('allows empty track lists', () {
      final parsed = PlaylistRecord.tryFromJson({
        'id': 'pl_empty',
        'name': 'Empty',
        'paletteIndex': 0,
        'createdAtMs': 1,
        'updatedAtMs': 1,
        'tracks': [],
      });
      expect(parsed, isNotNull);
      expect(parsed!.tracks, isEmpty);
    });
  });

  group('resolvePlaylistTrackForDisplay', () {
    test('uses live local metadata when ID matches', () {
      final record = PlaylistTrackRecord.fromTrack(
        const Track(
          id: 'local_1',
          title: 'Stale',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.local,
          localId: 1,
          localUri: 'content://media/1',
        ),
      );
      const live = Track(
        id: 'local_1',
        title: 'Fresh',
        artist: 'A',
        album: 'B',
        durationSeconds: 1,
        paletteIndex: 0,
        source: TrackSource.local,
        localId: 1,
        localUri: 'content://media/1',
      );
      final resolved = resolvePlaylistTrackForDisplay(record, [live]);
      expect(resolved.title, 'Fresh');
      expect(resolved.isPlayable, isTrue);
    });

    test('missing local file stays unplayable without deleting identity', () {
      final record = PlaylistTrackRecord.fromTrack(
        const Track(
          id: 'local_9',
          title: 'Gone',
          artist: 'A',
          album: 'B',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.local,
          localId: 9,
          localUri: 'content://media/9',
        ),
      );
      final resolved = resolvePlaylistTrackForDisplay(record, const []);
      expect(resolved.id, 'local_9');
      expect(resolved.isPlayable, isFalse);
      expect(resolved.localUri, isNull);
    });

    test('keeps local and online IDs distinct', () {
      final local = PlaylistTrackRecord.fromTrack(
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
      final online = PlaylistTrackRecord.fromTrack(
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
      expect(local.id, isNot(online.id));
    });
  });
}
