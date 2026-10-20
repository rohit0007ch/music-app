import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/local_library_service.dart';

/// UI state for scanning and exposing the device music library.
class LocalLibraryState extends ChangeNotifier {
  LocalLibraryState({LocalLibraryService? service})
    : _service = service ?? LocalLibraryService();

  final LocalLibraryService _service;

  List<Track> _songs = const [];
  bool _loading = false;
  bool _permissionGranted = false;
  bool _loadedOnce = false;
  String? _error;

  List<Track> get songs => List.unmodifiable(_songs);
  bool get loading => _loading;
  bool get permissionGranted => _permissionGranted;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  bool get hasSongs => _songs.isNotEmpty;

  /// Requests permission (if needed) and loads songs.
  Future<void> load({bool requestPermission = true}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (requestPermission) {
        _permissionGranted = await _service.ensurePermission();
      } else {
        _permissionGranted = await _service.hasPermission();
      }

      if (!_permissionGranted) {
        _songs = const [];
        _error = 'Music library permission is required to play local tracks.';
        return;
      }

      _songs = await _service.loadSongs();
    } catch (e) {
      // MissingPluginException in unit tests / unsupported platforms.
      _error = e.toString();
      _permissionGranted = false;
      _songs = const [];
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }
}
