import 'package:flutter/material.dart';
import 'package:melora_music/app/root_scaffold.dart';
import 'package:melora_music/theme/app_theme.dart';

/// App entry point — sets up MaterialApp with Melora theme.
class MeloraApp extends StatelessWidget {
  const MeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootScaffold(),
    );
  }
}
