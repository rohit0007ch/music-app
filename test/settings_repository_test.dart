import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesSettingsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns default speed when no value stored', () async {
      final repo = SharedPreferencesSettingsRepository();
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, SharedPreferencesSettingsRepository.defaultSpeed);
    });

    test('saves and reloads a valid speed', () async {
      final repo = SharedPreferencesSettingsRepository();
      await repo.savePlaybackSpeed(1.5);
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, 1.5);
    });

    test('clamps saved speed to valid range', () async {
      final repo = SharedPreferencesSettingsRepository();
      await repo.savePlaybackSpeed(3.0); // above max
      // savePlaybackSpeed clamps before storing
      final speed = await repo.loadPlaybackSpeed();
      expect(
        speed,
        closeTo(SharedPreferencesSettingsRepository.maxSpeed, 0.001),
      );
    });

    test('returns default for stored value below min', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(SharedPreferencesSettingsRepository.speedKey, 0.1);
      final repo = SharedPreferencesSettingsRepository(preferences: prefs);
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, SharedPreferencesSettingsRepository.defaultSpeed);
    });

    test('returns default for stored value above max', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(SharedPreferencesSettingsRepository.speedKey, 5.0);
      final repo = SharedPreferencesSettingsRepository(preferences: prefs);
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, SharedPreferencesSettingsRepository.defaultSpeed);
    });

    test('returns default for stored NaN', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        SharedPreferencesSettingsRepository.speedKey,
        double.nan,
      );
      final repo = SharedPreferencesSettingsRepository(preferences: prefs);
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, SharedPreferencesSettingsRepository.defaultSpeed);
    });

    test('returns default for stored infinity', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        SharedPreferencesSettingsRepository.speedKey,
        double.infinity,
      );
      final repo = SharedPreferencesSettingsRepository(preferences: prefs);
      final speed = await repo.loadPlaybackSpeed();
      expect(speed, SharedPreferencesSettingsRepository.defaultSpeed);
    });

    test('saves the min boundary value', () async {
      final repo = SharedPreferencesSettingsRepository();
      await repo.savePlaybackSpeed(
        SharedPreferencesSettingsRepository.minSpeed,
      );
      final speed = await repo.loadPlaybackSpeed();
      expect(
        speed,
        closeTo(SharedPreferencesSettingsRepository.minSpeed, 0.001),
      );
    });

    test('saves the max boundary value', () async {
      final repo = SharedPreferencesSettingsRepository();
      await repo.savePlaybackSpeed(
        SharedPreferencesSettingsRepository.maxSpeed,
      );
      final speed = await repo.loadPlaybackSpeed();
      expect(
        speed,
        closeTo(SharedPreferencesSettingsRepository.maxSpeed, 0.001),
      );
    });
  });
}
