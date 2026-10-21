import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _local({String? uri}) => Track(
  id: 'local-1',
  title: 'Local Song',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 0,
  source: TrackSource.local,
  localUri: uri,
);

Track _online({String? streamUrl}) => Track(
  id: 'online-1',
  title: 'Online Song',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 1,
  source: TrackSource.online,
  streamUrl: streamUrl,
);

Track _mock() => const Track(
  id: 'mock-1',
  title: 'Demo Song',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 2,
);

/// Engine that validates URIs then fails like a bad stream load.
class _FailingAudioEngine extends AudioEngine {
  @override
  Future<void> play(Track track) async {
    AudioEngine.resolvePlaybackUri(track);
    throw StateError('simulated stream failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioEngine.resolvePlaybackUri', () {
    test('resolves local content and file URIs', () {
      final content = AudioEngine.resolvePlaybackUri(
        _local(uri: 'content://media/external/audio/media/42'),
      );
      expect(content.scheme, 'content');
      expect(content.toString(), contains('42'));

      final file = AudioEngine.resolvePlaybackUri(
        _local(uri: 'file:///tmp/track.mp3'),
      );
      expect(file.scheme, 'file');
    });

    test('resolves online https stream URLs', () {
      final uri = AudioEngine.resolvePlaybackUri(
        _online(
          streamUrl:
              'https://prod-1.storage.jamendo.com/?trackid=1&format=mp32',
        ),
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'prod-1.storage.jamendo.com');
    });

    test('rejects mock tracks', () {
      expect(
        () => AudioEngine.resolvePlaybackUri(_mock()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects missing URIs', () {
      expect(
        () => AudioEngine.resolvePlaybackUri(_local()),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AudioEngine.resolvePlaybackUri(_online()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects malformed online URIs without a host', () {
      expect(
        () => AudioEngine.resolvePlaybackUri(_online(streamUrl: 'https://')),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects online non-http(s) schemes', () {
      expect(
        () => AudioEngine.resolvePlaybackUri(
          _online(streamUrl: 'ftp://example.com/a.mp3'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects http(s) used as a local URI', () {
      expect(
        () => AudioEngine.resolvePlaybackUri(
          _local(uri: 'https://example.com/a.mp3'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not treat streamUrl as local or localUri as online', () {
      // Online source ignores localUri even if present.
      final online = Track(
        id: 'o',
        title: 'O',
        artist: 'A',
        album: 'B',
        durationSeconds: 1,
        paletteIndex: 0,
        source: TrackSource.online,
        localUri: 'content://media/external/audio/media/1',
        streamUrl: 'https://cdn.example.com/a.mp3',
      );
      expect(AudioEngine.resolvePlaybackUri(online).scheme, 'https');

      // Local source ignores streamUrl even if present.
      final local = Track(
        id: 'l',
        title: 'L',
        artist: 'A',
        album: 'B',
        durationSeconds: 1,
        paletteIndex: 0,
        source: TrackSource.local,
        localUri: 'content://media/external/audio/media/2',
        streamUrl: 'https://cdn.example.com/b.mp3',
      );
      expect(AudioEngine.resolvePlaybackUri(local).scheme, 'content');
    });
  });

  group('AudioEngine.play early rejection', () {
    test('play rejects mock tracks before loading audio', () async {
      final engine = AudioEngine();
      addTearDown(engine.dispose);

      await expectLater(engine.play(_mock()), throwsA(isA<ArgumentError>()));
    });

    test('play rejects online track with missing stream URL', () async {
      final engine = AudioEngine();
      addTearDown(engine.dispose);

      await expectLater(engine.play(_online()), throwsA(isA<ArgumentError>()));
    });
  });

  group('MeloraPlayerState engine errors', () {
    test('stream failure sets error, stops playing, keeps queue', () async {
      final player = MeloraPlayerState(engine: _FailingAudioEngine());
      addTearDown(player.dispose);

      final track = _online(streamUrl: 'https://cdn.example.com/a.mp3');
      final queue = [track, _mock()];
      player.setQueue(queue);

      final started = await player.playTrack(track);

      expect(started, isFalse);
      expect(player.isPlaying, isFalse);
      expect(player.error, isNotNull);
      expect(player.currentTrack?.id, track.id);
      expect(player.queue.map((t) => t.id), queue.map((t) => t.id));
    });

    test(
      'demo track still does not replace a playable current track',
      () async {
        final player = MeloraPlayerState(engine: _FailingAudioEngine());
        addTearDown(player.dispose);

        final playable = _online(streamUrl: 'https://cdn.example.com/a.mp3');
        player.debugSetCurrentTrack(playable, isPlaying: true);
        player.setQueue([playable, _mock()]);

        final started = await player.playTrack(_mock());

        expect(started, isFalse);
        expect(player.currentTrack?.id, playable.id);
        expect(player.userMessage, MeloraPlayerState.demoNotPlayableMessage);
      },
    );
  });
}
