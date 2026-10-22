import 'dart:convert';

import 'package:melora_music/data/models/favorite_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent store for the ordered favorites list.
abstract class FavoritesRepository {
  /// Loads favorites in stored order. Never throws for corrupt entries —
  /// invalid items are skipped. May throw on underlying storage failure.
  Future<List<FavoriteRecord>> load();

  /// Persists [records] in order, replacing any previous list.
  Future<void> saveAll(List<FavoriteRecord> records);
}

/// [SharedPreferences]-backed [FavoritesRepository].
///
/// Stores a JSON array under [storageKey]. Duplicate IDs are not created by
/// callers; [FavoritesState] owns add/remove semantics.
class SharedPreferencesFavoritesRepository implements FavoritesRepository {
  SharedPreferencesFavoritesRepository({
    this._preferences,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// Namespaced key for the favorites JSON list.
  static const String storageKey = 'melora.favorites.v1';

  SharedPreferences? _preferences;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await _preferencesLoader();
  }

  @override
  Future<List<FavoriteRecord>> load() async {
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

    final records = <FavoriteRecord>[];
    final seenIds = <String>{};
    for (final item in decoded) {
      final record = FavoriteRecord.tryFromJson(item);
      if (record == null) continue;
      if (!seenIds.add(record.id)) continue;
      records.add(record);
    }
    return records;
  }

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {
    final prefs = await _prefs();
    final payload = jsonEncode([for (final record in records) record.toJson()]);
    final ok = await prefs.setString(storageKey, payload);
    if (!ok) {
      throw const FavoritesStorageException(
        'Could not save favorites to local storage.',
      );
    }
  }
}

/// Thrown when the favorites store cannot complete a write.
class FavoritesStorageException implements Exception {
  const FavoritesStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
