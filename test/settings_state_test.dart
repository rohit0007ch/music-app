import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/settings_repository.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake audio engine ─────────────────────────────────────────────────────────

class _FakeEngine extends AudioEngine {
  double lastSpeed = 1.0;

  @override
  Future<void> play(Track track) async {
    AudioEngine.resolvePlaybackUri(track);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setSpeed(double speed) async {
    lastSpeed = speed.clamp(0.5, 2.0);
  }
}

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeRepo implements SettingsRepository {
  double _speed = SharedPreferencesSettingsRepository.defaultSpeed;
  int loadCalls = 0;
  int saveCalls = 0;

  void seedSpeed(double v) => _speed = v;

  @override
  Future<double> loadPlaybackSpeed() async {
    loadCalls++;
    return _speed;
  }

  @override
  Future<void> savePlaybackSpeed(double speed) async {
    saveCalls++;
    _speed = speed;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MeloraPlayerState _makePlayer(_FakeEngine engine) =>
    MeloraPlayerState(engine: engine);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsState.load', () {
    test('defaults to 1.0 before load', () {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      expect(state.playbackSpeed, 1.0);
      expect(state.isLoaded, isFalse);
    });

    test('load reads from repository and applies to player', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo()..seedSpeed(1.5);
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.load();

      expect(state.playbackSpeed, 1.5);
      expect(state.isLoaded, isTrue);
      expect(engine.lastSpeed, 1.5);
      expect(repo.loadCalls, 1);
    });

    test('load is a no-op on subsequent calls', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo()..seedSpeed(1.25);
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.load();
      await state.load();
      await state.load();

      expect(repo.loadCalls, 1);
    });

    test('load notifies listeners once', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo()..seedSpeed(1.25);
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      var notifyCount = 0;
      state.addListener(() => notifyCount++);

      await state.load();

      expect(notifyCount, 1);
    });
  });

  group('SettingsState.setPlaybackSpeed', () {
    test('updates speed, notifies, persists, and applies to player', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      var notified = false;
      state.addListener(() => notified = true);

      await state.setPlaybackSpeed(1.75);

      expect(state.playbackSpeed, 1.75);
      expect(engine.lastSpeed, 1.75);
      expect(repo.saveCalls, 1);
      expect(notified, isTrue);
    });

    test('clamps speed below min to 0.5', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.setPlaybackSpeed(0.1);

      expect(state.playbackSpeed, 0.5);
      expect(engine.lastSpeed, 0.5);
    });

    test('clamps speed above max to 2.0', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.setPlaybackSpeed(5.0);

      expect(state.playbackSpeed, 2.0);
      expect(engine.lastSpeed, 2.0);
    });

    test('duplicate value does not re-notify or re-save', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.setPlaybackSpeed(1.0); // same as initial
      await state.setPlaybackSpeed(1.0); // again

      expect(repo.saveCalls, 0); // no save when value unchanged
    });

    test('sets speed on player via PlayerState.setPlaybackSpeed', () async {
      final engine = _FakeEngine();
      final player = _makePlayer(engine);
      addTearDown(player.dispose);
      final repo = _FakeRepo();
      final state = SettingsState(playerState: player, repository: repo);
      addTearDown(state.dispose);

      await state.setPlaybackSpeed(0.75);

      // The player's getter should also reflect it
      expect(player.playbackSpeed, 0.75);
    });
  });
}
