import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable app preferences.
abstract class SettingsRepository {
  /// Returns the stored playback speed, or [defaultSpeed] if not set or invalid.
  Future<double> loadPlaybackSpeed();

  /// Persists [speed]. Value is clamped to [minSpeed]–[maxSpeed].
  Future<void> savePlaybackSpeed(double speed);
}

/// [SharedPreferences]-backed [SettingsRepository].
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({
    SharedPreferences? preferences,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance {
    _preferences = preferences;
  }

  static const String speedKey = 'melora.settings.playbackSpeed.v1';
  static const double defaultSpeed = 1.0;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  SharedPreferences? _preferences;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<SharedPreferences> _prefs() async =>
      _preferences ??= await _preferencesLoader();

  @override
  Future<double> loadPlaybackSpeed() async {
    final prefs = await _prefs();
    final raw = prefs.getDouble(speedKey);
    if (raw == null) return defaultSpeed;
    if (raw.isNaN || raw.isInfinite || raw < minSpeed || raw > maxSpeed) {
      return defaultSpeed;
    }
    return raw;
  }

  @override
  Future<void> savePlaybackSpeed(double speed) async {
    final prefs = await _prefs();
    final clamped = speed.clamp(minSpeed, maxSpeed);
    await prefs.setDouble(speedKey, clamped);
  }
}
