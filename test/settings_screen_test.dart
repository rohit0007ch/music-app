import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/settings_repository.dart';
import 'package:melora_music/screens/settings/settings_screen.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/theme/app_theme.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

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

class _FakeRepo implements SettingsRepository {
  double _speed = 1.0;

  @override
  Future<double> loadPlaybackSpeed() async => _speed;

  @override
  Future<void> savePlaybackSpeed(double speed) async => _speed = speed;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: child);

SettingsState _makeState({double initialSpeed = 1.0}) {
  final engine = _FakeEngine();
  final player = MeloraPlayerState(engine: engine);
  final repo = _FakeRepo();
  final state = SettingsState(playerState: player, repository: repo);
  if (initialSpeed != 1.0) {
    state.setPlaybackSpeed(initialSpeed);
  }
  return state;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsScreen rendering', () {
    testWidgets('renders without error', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('shows Settings title in AppBar', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Playback section header', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.text('PLAYBACK'), findsOneWidget);
    });

    testWidgets('shows Playback Speed tile', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.text('Playback Speed'), findsOneWidget);
    });

    testWidgets('shows normal speed label when speed is 1.0', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.textContaining('Normal'), findsWidgets);
    });

    testWidgets('shows About section with Melora name', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.text('Melora'), findsOneWidget);
    });

    testWidgets('shows version string', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.textContaining('1.0.0'), findsOneWidget);
    });

    testWidgets('shows Attributions section', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();
      // Scroll to bottom so off-screen items are rendered.
      await tester.scrollUntilVisible(
        find.text('ATTRIBUTIONS'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('ATTRIBUTIONS'), findsOneWidget);
    });

    testWidgets('shows Jamendo attribution', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(
        find.textContaining('Jamendo', skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('shows LRCLIB attribution', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(
        find.textContaining('LRCLIB', skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('shows Equalizer not-yet-available tile', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.textContaining('Equalizer'), findsOneWidget);
      expect(find.textContaining('Not Yet Available'), findsOneWidget);
    });

    testWidgets('shows a Slider widget for speed control', (tester) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('SettingsScreen interaction', () {
    testWidgets('speed label updates when SettingsState changes', (
      tester,
    ) async {
      final state = _makeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(_wrap(SettingsScreen(settingsState: state)));
      await tester.pump();

      // Change speed programmatically
      await state.setPlaybackSpeed(1.5);
      await tester.pump();

      expect(find.textContaining('1.5'), findsWidgets);
    });
  });
}
