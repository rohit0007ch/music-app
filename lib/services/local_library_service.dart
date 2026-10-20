import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:permission_handler/permission_handler.dart';

/// Loads device media-library songs and maps them to Melora [Track]s.
///
/// Uses a thin platform channel (Android MediaStore / iOS MPMediaLibrary) plus
/// [permission_handler]. Avoids archived/`on_audio_query` packages that break
/// on modern Android Gradle Plugin namespace requirements.
class LocalLibraryService {
  LocalLibraryService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('melora_music/local_library');

  final MethodChannel _channel;

  /// Returns `true` when the app may read the device music library.
  Future<bool> ensurePermission() async {
    if (await hasPermission()) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final audio = await Permission.audio.request();
      if (audio.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await Permission.mediaLibrary.request()).isGranted;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.audio.isGranted) return true;
      return Permission.storage.isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Permission.mediaLibrary.isGranted;
    }
    return false;
  }

  /// Queries songs and returns only those with a resolvable audio URI.
  Future<List<Track>> loadSongs() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('querySongs');
    if (raw == null) return const [];

    final tracks = <Track>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final track = mapSong(Map<String, dynamic>.from(item));
      if (track != null) tracks.add(track);
    }
    return tracks;
  }

  /// Maps a platform song map to a playable Melora [Track], or `null` if
  /// no URI is available.
  static Track? mapSong(Map<String, dynamic> song) {
    final id = _asInt(song['id']);
    if (id == null) return null;

    final uri = (song['uri'] as String?)?.trim();
    if (uri == null || uri.isEmpty) return null;

    final durationMilliseconds = _asInt(song['durationMs']) ?? 0;
    final durationSeconds = durationMilliseconds > 0
        ? (durationMilliseconds / 1000).round().clamp(1, 24 * 60 * 60)
        : 0;

    return Track(
      id: 'local_$id',
      title: _nonEmpty(song['title'] as String?, 'Unknown title'),
      artist: _nonEmpty(song['artist'] as String?, 'Unknown artist'),
      album: _nonEmpty(song['album'] as String?, 'Unknown album'),
      durationSeconds: durationSeconds,
      paletteIndex: id.abs() % 8,
      source: TrackSource.local,
      localId: id,
      localUri: uri,
      genre: (song['genre'] as String?) ?? '',
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '<unknown>') {
      return fallback;
    }
    return trimmed;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
