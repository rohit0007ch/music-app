import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of checking or requesting device music-library access.
enum LocalLibraryPermission { granted, denied, permanentlyDenied }

/// Loads device media-library songs and maps them to Melora [Track]s.
///
/// Uses a thin platform channel (Android MediaStore / iOS MPMediaLibrary) plus
/// [permission_handler]. Avoids archived/`on_audio_query` packages that break
/// on modern Android Gradle Plugin namespace requirements.
class LocalLibraryService {
  LocalLibraryService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('melora_music/local_library');

  final MethodChannel _channel;

  static const _userScanError =
      'Could not read the music library. Please try again.';
  static const _userUnavailableError =
      'Local music library is not available on this device.';

  /// Soft check — does not show a system prompt.
  Future<LocalLibraryPermission> permissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final audio = await Permission.audio.status;
      if (audio.isGranted) return LocalLibraryPermission.granted;
      if (audio.isPermanentlyDenied) {
        return LocalLibraryPermission.permanentlyDenied;
      }

      final storage = await Permission.storage.status;
      if (storage.isGranted) return LocalLibraryPermission.granted;
      if (storage.isPermanentlyDenied) {
        return LocalLibraryPermission.permanentlyDenied;
      }
      return LocalLibraryPermission.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.mediaLibrary.status;
      if (status.isGranted) return LocalLibraryPermission.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return LocalLibraryPermission.permanentlyDenied;
      }
      return LocalLibraryPermission.denied;
    }

    return LocalLibraryPermission.denied;
  }

  /// Requests permission when not already granted.
  Future<LocalLibraryPermission> ensurePermission() async {
    final current = await permissionStatus();
    if (current == LocalLibraryPermission.granted) return current;
    if (current == LocalLibraryPermission.permanentlyDenied) return current;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final audio = await Permission.audio.request();
      if (audio.isGranted) return LocalLibraryPermission.granted;
      if (audio.isPermanentlyDenied) {
        return LocalLibraryPermission.permanentlyDenied;
      }

      final storage = await Permission.storage.request();
      if (storage.isGranted) return LocalLibraryPermission.granted;
      if (storage.isPermanentlyDenied) {
        return LocalLibraryPermission.permanentlyDenied;
      }
      return LocalLibraryPermission.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.mediaLibrary.request();
      if (status.isGranted) return LocalLibraryPermission.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return LocalLibraryPermission.permanentlyDenied;
      }
      return LocalLibraryPermission.denied;
    }

    return LocalLibraryPermission.denied;
  }

  /// Opens the OS Settings page for this app (user must grant access there).
  Future<bool> openSystemSettings() => openAppSettings();

  /// Queries songs and returns only those with a resolvable audio URI.
  Future<List<Track>> loadSongs() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('querySongs');
      if (raw == null) return const [];

      final tracks = <Track>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final track = mapSong(Map<String, dynamic>.from(item));
        if (track != null) tracks.add(track);
      }
      return tracks;
    } on PlatformException catch (e) {
      throw LocalLibraryException.fromPlatform(e);
    } on MissingPluginException catch (e) {
      throw LocalLibraryException.fromMissingPlugin(e);
    }
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
      artworkUri: _optionalArtworkUri(song['artworkUri']),
      genre: (song['genre'] as String?) ?? '',
    );
  }

  /// Accepts file:// or http(s) artwork; drops blank / unsupported values.
  static String? _optionalArtworkUri(Object? value) {
    final raw = (value as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'file' || scheme == 'http' || scheme == 'https') {
      return raw;
    }
    // content:// and others are not displayed by MeloraArtwork — omit.
    return null;
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

/// Friendly failure from the local-library channel.
///
/// [message] is safe for UI. [debugDetail] keeps technical context for logs.
class LocalLibraryException implements Exception {
  const LocalLibraryException(this.message, {this.debugDetail});

  /// User-facing copy — never includes stack traces or raw plugin text.
  final String message;

  /// Optional diagnostic string for debugPrint / developer tooling.
  final String? debugDetail;

  factory LocalLibraryException.fromPlatform(PlatformException e) {
    final detail = [
      e.code,
      if (e.message != null && e.message!.trim().isNotEmpty) e.message!.trim(),
      if (e.details != null) e.details.toString(),
    ].join(': ');
    return LocalLibraryException(
      LocalLibraryService._userScanError,
      debugDetail: detail,
    );
  }

  factory LocalLibraryException.fromMissingPlugin(MissingPluginException e) {
    return LocalLibraryException(
      LocalLibraryService._userUnavailableError,
      debugDetail: e.message,
    );
  }

  @override
  String toString() {
    if (debugDetail == null || debugDetail!.isEmpty) return message;
    return '$message ($debugDetail)';
  }
}
