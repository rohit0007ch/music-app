import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';

void main() {
  group('FavoriteRecord', () {
    test('fromTrack / toTrack round trip preserves playback fields', () {
      const track = Track(
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
        isFavourite: false,
      );

      final record = FavoriteRecord.fromTrack(track);
      final restored = record.toTrack();

      expect(restored.id, track.id);
      expect(restored.source, TrackSource.online);
      expect(restored.streamUrl, track.streamUrl);
      expect(restored.artworkUri, track.artworkUri);
      expect(restored.licenseUrl, track.licenseUrl);
      expect(restored.isFavourite, isTrue);
      expect(restored.localUri, isNull);
    });

    test('toJson / tryFromJson round trip for local track', () {
      final record = FavoriteRecord.fromTrack(
        const Track(
          id: 'local_9',
          title: 'Home',
          artist: 'Local Artist',
          album: 'Device',
          durationSeconds: 200,
          paletteIndex: 1,
          source: TrackSource.local,
          localId: 9,
          localUri: 'content://media/external/audio/media/9',
        ),
      );

      final parsed = FavoriteRecord.tryFromJson(record.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.id, 'local_9');
      expect(parsed.source, TrackSource.local);
      expect(parsed.localId, 9);
      expect(parsed.localUri, 'content://media/external/audio/media/9');
      expect(parsed.streamUrl, isNull);
    });

    test('tryFromJson returns null for malformed entries', () {
      expect(FavoriteRecord.tryFromJson(null), isNull);
      expect(FavoriteRecord.tryFromJson('oops'), isNull);
      expect(FavoriteRecord.tryFromJson(<String, dynamic>{}), isNull);
      expect(
        FavoriteRecord.tryFromJson({'id': 'x', 'source': 'not-a-source'}),
        isNull,
      );
      expect(FavoriteRecord.tryFromJson({'id': '', 'source': 'local'}), isNull);
      expect(
        FavoriteRecord.tryFromJson({'id': '  ', 'source': 'online'}),
        isNull,
      );
    });

    test('tryFromJson fills display defaults when titles missing', () {
      final parsed = FavoriteRecord.tryFromJson({
        'id': 'online_1',
        'source': 'online',
        'streamUrl': 'https://cdn.example.com/a.mp3',
      });
      expect(parsed, isNotNull);
      expect(parsed!.title, 'Unknown title');
      expect(parsed.artist, 'Unknown artist');
      expect(parsed.album, 'Unknown album');
      expect(parsed.durationSeconds, 0);
      expect(parsed.paletteIndex, 0);
    });

    test('local and online IDs remain distinct', () {
      final local = FavoriteRecord.fromTrack(
        const Track(
          id: 'local_1',
          title: 'A',
          artist: 'B',
          album: 'C',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.local,
          localId: 1,
          localUri: 'content://media/external/audio/media/1',
        ),
      );
      final online = FavoriteRecord.fromTrack(
        const Track(
          id: 'online_1',
          title: 'A',
          artist: 'B',
          album: 'C',
          durationSeconds: 1,
          paletteIndex: 0,
          source: TrackSource.online,
          streamUrl: 'https://cdn.example.com/a.mp3',
        ),
      );
      expect(local.id, isNot(online.id));
      expect(local.source, TrackSource.local);
      expect(online.source, TrackSource.online);
    });
  });
}
