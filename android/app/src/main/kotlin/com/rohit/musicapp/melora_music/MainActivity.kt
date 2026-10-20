package com.rohit.musicapp.melora_music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Extends [AudioServiceActivity] so `just_audio_background` can bind the
/// media session / notification controls to this Flutter activity.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler(LocalLibraryHandler(applicationContext))
    }

    companion object {
        private const val CHANNEL = "melora_music/local_library"
    }
}
