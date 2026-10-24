import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _demo(String id) => Track(
  id: id,
  title: 'Demo $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
  paletteIndex: 0,
);

Track _local(String id) => Track(
  id: id,
  title: 'Local $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
  paletteIndex: 1,
  source: TrackSource.local,
  localUri: 'content://media/external/audio/media/$id',
);

Track _online(String id) => Track(
  id: id,
  title: 'Online $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
  paletteIndex: 2,
  source: TrackSource.online,
  streamUrl: 'https://cdn.example.com/$id.mp3',
);

/// Controllable engine for race / error tests (never touches just_audio).
class _ControllableEngine extends AudioEngine {
  final _playStarts = <Completer<void>>[];
  Object? throwOnPlay;
  int playCalls = 0;
  final List<String> playedIds = [];

  @override
  Future<void> play(Track track) async {
    playCalls++;
    playedIds.add(track.id);
    AudioEngine.resolvePlaybackUri(track);
    final gate = Completer<void>();
    _playStarts.add(gate);
    await gate.future;
    if (throwOnPlay != null) throw throwOnPlay!;
  }

  void completeNextPlay() {
    if (_playStarts.isEmpty) {
      throw StateError('No pending play');
    }
    _playStarts.removeAt(0).complete();
  }

  void completeAllPlays() {
    while (_playStarts.isNotEmpty) {
      completeNextPlay();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('queue navigation boundaries', () {
    test('RepeatMode.none does not wrap at ends', () {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      final a = _local('a');
      final b = _local('b');
      player.setQueue([a, b]);
      player.debugSetCurrentTrack(a);

      expect(player.debugPeekRelative(1)?.id, 'b');
      expect(player.debugPeekRelative(-1), isNull);
      expect(player.canSkipPrevious, isFalse);
      expect(player.canSkipNext, isTrue);

      player.debugSetCurrentTrack(b);
      expect(player.debugPeekRelative(1), isNull);
      expect(player.debugPeekRelative(-1)?.id, 'a');
      expect(player.canSkipNext, isFalse);
      expect(player.canSkipPrevious, isTrue);
    });

    test('RepeatMode.all wraps and skips demos from a playable track', () {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      final a = _local('a');
      final demo = _demo('demo');
      final b = _local('b');
      player.setQueue([a, demo, b]);
      player.debugSetCurrentTrack(a);
      player.cycleRepeat(); // none -> all

      expect(player.repeatMode, RepeatMode.all);
      expect(player.debugPeekRelative(1)?.id, 'b');
      expect(player.debugPeekRelative(-1)?.id, 'b');
    });
  });

  group('playback error recovery', () {
    test('engine failure sets friendly error and keeps queue', () async {
      final engine = _ControllableEngine()
        ..throwOnPlay = Exception('SocketException: Failed host lookup');
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      final track = _online('1');
      final other = _online('2');
      player.setQueue([track, other]);

      final future = player.playTrack(track);
      engine.completeNextPlay();
      final started = await future;

      expect(started, isFalse);
      expect(player.isPlaying, isFalse);
      expect(player.error, contains('connection'));
      expect(player.takeUserMessage(), contains('connection'));
      expect(player.currentTrack?.id, '1');
      expect(player.queue.map((t) => t.id), ['1', '2']);
    });

    test('switching to another track after failure can succeed', () async {
      final engine = _ControllableEngine();
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      final bad = _online('bad');
      final good = _online('good');
      player.setQueue([bad, good]);

      engine.throwOnPlay = StateError('unable to load source');
      final failFuture = player.playTrack(bad);
      engine.completeNextPlay();
      expect(await failFuture, isFalse);
      expect(player.error, isNotNull);

      engine.throwOnPlay = null;
      final okFuture = player.playTrack(good);
      engine.completeNextPlay();
      expect(await okFuture, isTrue);
      expect(player.error, isNull);
      expect(player.currentTrack?.id, 'good');
    });

    test('stale play failure does not overwrite a newer track', () async {
      final engine = _ControllableEngine();
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      final first = _online('first');
      final second = _online('second');
      player.setQueue([first, second]);

      final firstFuture = player.playTrack(first);
      final secondFuture = player.playTrack(second);

      // Fail the older (first) load after the newer request started.
      engine.throwOnPlay = Exception('network');
      engine.completeNextPlay(); // completes first
      expect(await firstFuture, isFalse);

      engine.throwOnPlay = null;
      engine.completeNextPlay(); // completes second
      expect(await secondFuture, isTrue);

      expect(player.currentTrack?.id, 'second');
      expect(player.error, isNull);
      expect(engine.playedIds, ['first', 'second']);
    });
  });

  group('favorites sync does not reset queue', () {
    test('syncFavouriteFlags updates flags only', () {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      final a = _local('a');
      final b = _local('b');
      player.setQueue([a, b]);
      player.debugSetCurrentTrack(a, isPlaying: true);

      player.syncFavouriteFlags((id) => id == 'a');

      expect(player.currentTrack!.isFavourite, isTrue);
      expect(player.queue.first.isFavourite, isTrue);
      expect(player.queue.last.isFavourite, isFalse);
      expect(player.queue.map((t) => t.id), ['a', 'b']);
      expect(player.currentTrack?.id, 'a');
    });
  });
}
