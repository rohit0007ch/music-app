import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _local(String id) => Track(
  id: id,
  title: 'Local $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 0,
  source: TrackSource.local,
  localUri: 'content://media/external/audio/media/$id',
);

class _RecordingEngine extends AudioEngine {
  int pauseCalls = 0;
  int playCalls = 0;

  @override
  Future<void> play(Track track) async {
    playCalls++;
    AudioEngine.resolvePlaybackUri(track);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sleep timer', () {
    test('start sets deadline and remaining', () {
      var now = DateTime.utc(2026, 1, 1, 12);
      final player = MeloraPlayerState(clock: () => now);
      addTearDown(player.dispose);

      player.setSleepTimer(15);
      expect(player.hasActiveSleepTimer, isTrue);
      expect(player.sleepTimerMinutes, 15);
      expect(player.sleepTimerRemaining, const Duration(minutes: 15));

      now = now.add(const Duration(minutes: 5));
      expect(player.sleepTimerRemaining, const Duration(minutes: 10));
    });

    test('invalid duration cancels timer', () {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      player.setSleepTimer(30);
      expect(player.hasActiveSleepTimer, isTrue);

      player.setSleepTimer(0);
      expect(player.hasActiveSleepTimer, isFalse);
      expect(player.sleepTimerMinutes, isNull);

      player.setSleepTimer(-5);
      expect(player.hasActiveSleepTimer, isFalse);
    });

    test('replace timer cancels previous expiration', () async {
      final engine = _RecordingEngine();
      var now = DateTime.utc(2026, 1, 1, 12);
      final player = MeloraPlayerState(engine: engine, clock: () => now);
      addTearDown(player.dispose);

      final a = _local('a');
      player.debugSetCurrentTrack(a, isPlaying: true);
      player.setQueue([a]);

      player.setSleepTimer(1);
      final firstDeadline = player.sleepTimerDeadline;

      player.setSleepTimer(30);
      expect(player.sleepTimerDeadline!.isAfter(firstDeadline!), isTrue);

      // Simulate first timer firing late — generation should ignore it.
      now = firstDeadline;
      player.refreshSleepTimerAfterResume();
      await Future<void>.delayed(Duration.zero);

      expect(engine.pauseCalls, 0);
      expect(player.hasActiveSleepTimer, isTrue);
      expect(player.sleepTimerMinutes, 30);
    });

    test('cancel before expiration prevents pause', () async {
      final engine = _RecordingEngine();
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      player.debugSetCurrentTrack(_local('a'), isPlaying: true);
      player.setSleepTimer(15);
      player.setSleepTimer(null);

      expect(player.hasActiveSleepTimer, isFalse);
      expect(engine.pauseCalls, 0);
    });

    test('expiration pauses once and keeps queue/current track', () async {
      final engine = _RecordingEngine();
      var now = DateTime.utc(2026, 1, 1, 12);
      final player = MeloraPlayerState(engine: engine, clock: () => now);
      addTearDown(player.dispose);

      final a = _local('a');
      final b = _local('b');
      player.setQueue([a, b]);
      player.debugSetCurrentTrack(a, isPlaying: true);

      player.setSleepTimer(15);
      now = now.add(const Duration(minutes: 15, seconds: 1));
      player.refreshSleepTimerAfterResume();
      await Future<void>.delayed(Duration.zero);

      expect(engine.pauseCalls, 1);
      expect(player.hasActiveSleepTimer, isFalse);
      expect(player.currentTrack?.id, 'a');
      expect(player.queue.map((t) => t.id), ['a', 'b']);

      // Second resume must not pause again.
      player.refreshSleepTimerAfterResume();
      await Future<void>.delayed(Duration.zero);
      expect(engine.pauseCalls, 1);
    });

    test('timer stays active across track changes', () {
      final player = MeloraPlayerState();
      addTearDown(player.dispose);

      final a = _local('a');
      final b = _local('b');
      player.setQueue([a, b]);
      player.debugSetCurrentTrack(a, isPlaying: true);
      player.setSleepTimer(45);

      player.debugSetCurrentTrack(b, isPlaying: true);
      expect(player.hasActiveSleepTimer, isTrue);
      expect(player.sleepTimerMinutes, 45);
    });

    test('expiration when already stopped does not throw', () async {
      final engine = _RecordingEngine();
      var now = DateTime.utc(2026, 1, 1, 12);
      final player = MeloraPlayerState(engine: engine, clock: () => now);
      addTearDown(player.dispose);

      player.debugSetCurrentTrack(_local('a'), isPlaying: false);
      player.setSleepTimer(5);
      now = now.add(const Duration(minutes: 6));
      player.refreshSleepTimerAfterResume();
      await Future<void>.delayed(Duration.zero);

      expect(engine.pauseCalls, 0);
      expect(player.hasActiveSleepTimer, isFalse);
    });
  });
}
