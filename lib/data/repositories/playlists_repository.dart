import 'dart:convert';

import 'package:melora_music/data/models/playlist_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent store for the ordered custom playlists list.
abstract class PlaylistsRepository {
  /// Loads playlists in stored order. Corrupt entries are skipped.
  /// May throw on underlying storage failure.
  Future<List<PlaylistRecord>> load();

  /// Persists [playlists] in order, replacing any previous list.
  Future<void> saveAll(List<PlaylistRecord> playlists);
}

/// [SharedPreferences]-backed [PlaylistsRepository].
///
/// Uses [storageKey] — independent of favorites (`melora.favorites.v1`).
class SharedPreferencesPlaylistsRepository implements PlaylistsRepository {
  SharedPreferencesPlaylistsRepository({
    this._preferences,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// Namespaced key for the playlists JSON list.
  static const String storageKey = 'melora.playlists.v1';

  SharedPreferences? _preferences;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await _preferencesLoader();
  }

  @override
  Future<List<PlaylistRecord>> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }

    if (decoded is! List) return const [];

    final playlists = <PlaylistRecord>[];
    final seenIds = <String>{};
    for (final item in decoded) {
      final record = PlaylistRecord.tryFromJson(item);
      if (record == null) continue;
      if (!seenIds.add(record.id)) continue;
      playlists.add(record);
    }
    return playlists;
  }

  @override
  Future<void> saveAll(List<PlaylistRecord> playlists) async {
    final prefs = await _prefs();
    final payload = jsonEncode([
      for (final playlist in playlists) playlist.toJson(),
    ]);
    final ok = await prefs.setString(storageKey, payload);
    if (!ok) {
      throw const PlaylistsStorageException(
        'Could not save playlists to local storage.',
      );
    }
  }
}

/// Thrown when the playlists store cannot complete a write.
class PlaylistsStorageException implements Exception {
  const PlaylistsStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
