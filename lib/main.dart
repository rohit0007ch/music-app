import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background audio / lock-screen controls are for mobile & desktop.
  // On Flutter web, just_audio_background interferes with asset playback.
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rohit.musicapp.melora_music.audio',
      androidNotificationChannelName: 'Melora Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MeloraApp());
}
