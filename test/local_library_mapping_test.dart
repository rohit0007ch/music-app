import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/local_library_service.dart';

void main() {
  group('LocalLibraryService.mapSong', () {
    test('maps a song with content URI into a playable local Track', () {
      final track = LocalLibraryService.mapSong({
        'id': 42,
        'uri': 'content://media/external/audio/media/42',
        'title': 'Local Groove',
        'artist': 'Device Artist',
        'album': 'Phone Album',
        'durationMs': 125000,
        'genre': 'Jazz',
      });

      expect(track, isNotNull);
      expect(track!.id, 'local_42');
      expect(track.source, TrackSource.local);
      expect(track.isPlayable, isTrue);
      expect(track.localUri, 'content://media/external/audio/media/42');
      expect(track.durationSeconds, 125);
      expect(track.title, 'Local Groove');
      expect(track.artist, 'Device Artist');
    });

    test('accepts numeric ids delivered as strings', () {
      final track = LocalLibraryService.mapSong({
        'id': '7',
        'uri': 'file:///tmp/track.mp3',
        'title': 'File Only',
        'artist': 'A',
        'album': 'B',
        'durationMs': 60000,
      });

      expect(track, isNotNull);
      expect(track!.localUri, 'file:///tmp/track.mp3');
      expect(track.isPlayable, isTrue);
    });

    test('returns null when URI is missing', () {
      expect(
        LocalLibraryService.mapSong({
          'id': 1,
          'title': 'Broken',
          'durationMs': 1000,
        }),
        isNull,
      );
    });
  });
}
