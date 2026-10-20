import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise background audio service.
  // Must be called before runApp(). Registers the Android foreground service
  // and iOS AVAudioSession handlers via just_audio_background.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.rohit.musicapp.melora_music.audio',
    androidNotificationChannelName: 'Melora Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MeloraApp());
}
