import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';

Track _track({TrackSource source = TrackSource.mock, String? localUri}) {
  return Track(
    id: 't',
    title: 'Title',
    artist: 'Artist',
    album: 'Album',
    durationSeconds: 120,
    paletteIndex: 0,
    source: source,
    localUri: localUri,
  );
}

void main() {
  group('Track.isPlayable', () {
    test('mock tracks are never playable', () {
      expect(_track().isPlayable, isFalse);
      expect(_track(localUri: 'file:///tmp/demo.mp3').isPlayable, isFalse);
    });

    test('local tracks require a non-empty localUri', () {
      expect(_track(source: TrackSource.local).isPlayable, isFalse);
      expect(
        _track(source: TrackSource.local, localUri: '').isPlayable,
        isFalse,
      );
      expect(
        _track(
          source: TrackSource.local,
          localUri: 'content://media/external/audio/media/1',
        ).isPlayable,
        isTrue,
      );
    });

    test('online tracks require a non-empty URI', () {
      expect(_track(source: TrackSource.online).isPlayable, isFalse);
      expect(
        _track(
          source: TrackSource.online,
          localUri: 'https://example.com/a.mp3',
        ).isPlayable,
        isTrue,
      );
    });
  });
}
