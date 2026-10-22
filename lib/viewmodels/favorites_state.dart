import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';

/// Persistent favorites list state.
///
/// Membership in this store is the source of truth for favourite status.
/// [Track.isFavourite] on player/queue copies is kept in sync by the UI layer.
class FavoritesState extends ChangeNotifier {
  FavoritesState({FavoritesRepository? repository})
    : _repository = repository ?? SharedPreferencesFavoritesRepository();

  final FavoritesRepository _repository;

  List<FavoriteRecord> _favorites = const [];
  bool _loading = false;
  bool _saving = false;
  bool _loadedOnce = false;
  String? _error;

  /// Ordered favorite records (persistence order).
  List<FavoriteRecord> get favorites => List.unmodifiable(_favorites);

  /// Favorites as [Track]s with `isFavourite: true`.
  List<Track> get tracks => [for (final record in _favorites) record.toTrack()];

  bool get loading => _loading;
  bool get saving => _saving;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  bool get isEmpty => _favorites.isEmpty;
  bool get isNotEmpty => _favorites.isNotEmpty;

  bool isFavorite(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    return _favorites.any((r) => r.id == trimmed);
  }

  /// Loads from disk. Concurrent calls while loading are ignored.
  ///
  /// Always clears [loading] in a `finally` so listeners are never stuck.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await _repository.load();
      _error = null;
    } catch (e) {
      _error = _friendlyError(e);
      // Keep any previously loaded list; first-load failure stays empty.
      debugPrint('FavoritesState.load failed: $e');
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Adds [track] if missing; if already present, refreshes metadata in place.
  /// Returns `true` when the store was updated successfully.
  Future<bool> add(Track track) async {
    if (_saving) return false;
    final record = FavoriteRecord.fromTrack(track);
    final index = _favorites.indexWhere((r) => r.id == record.id);
    final next = List<FavoriteRecord>.from(_favorites);
    if (index >= 0) {
      next[index] = record;
    } else {
      next.add(record);
    }
    return _persist(next);
  }

  /// Removes the favorite with [id], if present.
  /// Returns `true` when the store was updated successfully (or already absent).
  Future<bool> remove(String id) async {
    if (_saving) return false;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return true;
    if (!_favorites.any((r) => r.id == trimmed)) return true;
    final next = _favorites.where((r) => r.id != trimmed).toList();
    return _persist(next);
  }

  /// Adds when absent; removes when present.
  /// Returns `true` only after a successful persist (or no-op remove).
  Future<bool> toggle(Track track) async {
    if (_saving) return false;
    if (isFavorite(track.id)) {
      return remove(track.id);
    }
    return add(track);
  }

  Future<bool> _persist(List<FavoriteRecord> next) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.saveAll(next);
      _favorites = next;
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('FavoritesState.persist failed: $e');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  static String _friendlyError(Object error) {
    if (error is FavoritesStorageException) return error.message;
    return 'Could not update favorites. Please try again.';
  }
}
