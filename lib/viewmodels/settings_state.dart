import 'package:flutter/foundation.dart';
import 'package:melora_music/data/repositories/settings_repository.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Manages user-configurable app preferences.
///
/// Persists via [SettingsRepository] and applies audio preferences to the
/// shared [PlayerState] (which delegates to [AudioEngine]).
class SettingsState extends ChangeNotifier {
  SettingsState({
    required PlayerState playerState,
    SettingsRepository? repository,
  }) : _repository = repository ?? SharedPreferencesSettingsRepository() {
    _playerState = playerState;
  }

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;
  static const double defaultSpeed = 1.0;

  late final PlayerState _playerState;
  final SettingsRepository _repository;

  double _playbackSpeed = defaultSpeed;
  bool _isLoaded = false;

  double get playbackSpeed => _playbackSpeed;
  bool get isLoaded => _isLoaded;

  /// Loads persisted preferences and applies them to the player.
  /// Subsequent calls are no-ops once loaded.
  Future<void> load() async {
    if (_isLoaded) return;
    final speed = await _repository.loadPlaybackSpeed();
    _playbackSpeed = speed;
    _isLoaded = true;
    await _playerState.setPlaybackSpeed(speed);
    notifyListeners();
  }

  /// Updates and persists the playback speed, and applies it to the player.
  Future<void> setPlaybackSpeed(double speed) async {
    final clamped = speed.clamp(minSpeed, maxSpeed);
    if (_playbackSpeed == clamped) return;
    _playbackSpeed = clamped;
    notifyListeners();
    await _repository.savePlaybackSpeed(clamped);
    await _playerState.setPlaybackSpeed(clamped);
  }
}
