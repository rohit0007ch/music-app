import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';

/// Persistent custom playlists state.
///
/// Not wired into the UI in Milestone 4B.2.
class PlaylistsState extends ChangeNotifier {
  PlaylistsState({
    PlaylistsRepository? repository,
    Random? random,
    int Function()? clockMs,
  }) : _repository = repository ?? SharedPreferencesPlaylistsRepository(),
       _random = random ?? Random(),
       _clockMs = clockMs ?? _defaultClockMs;

  final PlaylistsRepository _repository;
  final Random _random;
  final int Function() _clockMs;

  List<PlaylistRecord> _playlists = const [];
  bool _loading = false;
  bool _saving = false;
  bool _loadedOnce = false;
  String? _error;

  List<PlaylistRecord> get playlists => List.unmodifiable(_playlists);
  bool get loading => _loading;
  bool get saving => _saving;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  bool get isEmpty => _playlists.isEmpty;
  bool get isNotEmpty => _playlists.isNotEmpty;

  PlaylistRecord? playlistById(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    for (final playlist in _playlists) {
      if (playlist.id == trimmed) return playlist;
    }
    return null;
  }

  /// Loads from disk. Concurrent calls while loading are ignored.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _playlists = await _repository.load();
      _error = null;
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('PlaylistsState.load failed: $e');
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Creates an empty playlist. Returns the new id, or `null` on failure /
  /// invalid name.
  Future<String?> create(String name, {int paletteIndex = 0}) async {
    if (_saving) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _error = 'Playlist name cannot be empty.';
      notifyListeners();
      return null;
    }

    final now = _clockMs();
    final id = _newPlaylistId(now);
    final record = PlaylistRecord(
      id: id,
      name: trimmed,
      paletteIndex: paletteIndex < 0 ? 0 : paletteIndex,
      createdAtMs: now,
      updatedAtMs: now,
      tracks: const [],
    );
    final next = [..._playlists, record];
    final ok = await _persist(next);
    return ok ? id : null;
  }

  /// Renames a playlist. Returns `true` on success.
  Future<bool> rename(String playlistId, String name) async {
    if (_saving) return false;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Playlist name cannot be empty.';
      notifyListeners();
      return false;
    }

    final index = _indexOf(playlistId);
    if (index < 0) {
      _error = 'Playlist not found.';
      notifyListeners();
      return false;
    }

    final current = _playlists[index];
    if (current.name == trimmedName) return true;

    final next = List<PlaylistRecord>.from(_playlists);
    next[index] = current.copyWith(name: trimmedName, updatedAtMs: _clockMs());
    return _persist(next);
  }

  /// Deletes a playlist. Returns `true` when removed or already absent.
  Future<bool> delete(String playlistId) async {
    if (_saving) return false;
    final trimmed = playlistId.trim();
    if (trimmed.isEmpty) return true;
    if (!_playlists.any((p) => p.id == trimmed)) return true;

    final next = _playlists.where((p) => p.id != trimmed).toList();
    return _persist(next);
  }

  /// Appends [track] if not already present. Duplicate IDs are a no-op success.
  Future<bool> addTrack(String playlistId, Track track) async {
    if (_saving) return false;
    final index = _indexOf(playlistId);
    if (index < 0) {
      _error = 'Playlist not found.';
      notifyListeners();
      return false;
    }

    final current = _playlists[index];
    if (current.tracks.any((t) => t.id == track.id)) {
      return true;
    }

    final snapshot = PlaylistTrackRecord.fromTrack(track);
    final next = List<PlaylistRecord>.from(_playlists);
    next[index] = current.copyWith(
      tracks: [...current.tracks, snapshot],
      updatedAtMs: _clockMs(),
    );
    return _persist(next);
  }

  /// Removes a track by stable id. Missing track is a no-op success.
  Future<bool> removeTrack(String playlistId, String trackId) async {
    if (_saving) return false;
    final index = _indexOf(playlistId);
    if (index < 0) {
      _error = 'Playlist not found.';
      notifyListeners();
      return false;
    }

    final trimmedTrack = trackId.trim();
    if (trimmedTrack.isEmpty) return true;

    final current = _playlists[index];
    if (!current.tracks.any((t) => t.id == trimmedTrack)) return true;

    final nextTracks = current.tracks
        .where((t) => t.id != trimmedTrack)
        .toList();
    final next = List<PlaylistRecord>.from(_playlists);
    next[index] = current.copyWith(tracks: nextTracks, updatedAtMs: _clockMs());
    return _persist(next);
  }

  int _indexOf(String playlistId) {
    final trimmed = playlistId.trim();
    if (trimmed.isEmpty) return -1;
    return _playlists.indexWhere((p) => p.id == trimmed);
  }

  String _newPlaylistId(int nowMs) {
    final suffix = _random.nextInt(0x7fffffff).toRadixString(16);
    var id = 'pl_${nowMs}_$suffix';
    var attempt = 0;
    while (_playlists.any((p) => p.id == id) && attempt < 8) {
      attempt++;
      id = 'pl_${nowMs}_${_random.nextInt(0x7fffffff).toRadixString(16)}';
    }
    return id;
  }

  /// Saves [next] first; only publishes to listeners on success.
  Future<bool> _persist(List<PlaylistRecord> next) async {
    _saving = true;
    notifyListeners();
    try {
      await _repository.saveAll(next);
      _playlists = next;
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      debugPrint('PlaylistsState.persist failed: $e');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  static int _defaultClockMs() => DateTime.now().millisecondsSinceEpoch;

  static String _friendlyError(Object error) {
    if (error is PlaylistsStorageException) return error.message;
    return 'Could not update playlists. Please try again.';
  }
}
