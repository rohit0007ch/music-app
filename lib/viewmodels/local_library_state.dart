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
  bool _permissionPermanentlyDenied = false;
  bool _loadedOnce = false;
  String? _error;

  List<Track> get songs => List.unmodifiable(_songs);
  bool get loading => _loading;
  bool get permissionGranted => _permissionGranted;
  bool get permissionPermanentlyDenied => _permissionPermanentlyDenied;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  bool get hasSongs => _songs.isNotEmpty;

  /// True when a scan failed after permission was granted.
  bool get hasLoadError =>
      _permissionGranted && _error != null && _songs.isEmpty;

  /// Requests permission (if needed) and loads songs.
  Future<void> load({bool requestPermission = true}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final status = requestPermission
          ? await _service.ensurePermission()
          : await _service.permissionStatus();

      _permissionGranted = status == LocalLibraryPermission.granted;
      _permissionPermanentlyDenied =
          status == LocalLibraryPermission.permanentlyDenied;

      if (!_permissionGranted) {
        _songs = const [];
        _error = _permissionPermanentlyDenied
            ? 'Music access is turned off. Enable it in Settings to play '
                  'songs stored on this device.'
            : 'Music library permission is required to play local tracks.';
        return;
      }

      _songs = await _service.loadSongs();
      _error = null;
    } catch (e) {
      // Keep permissionGranted if we already obtained it — show a retryable
      // load error instead of bouncing the user back to the allow-access UI.
      if (e is LocalLibraryException) {
        _error = e.message;
        final detail = e.debugDetail;
        if (detail != null && detail.isNotEmpty) {
          debugPrint('LocalLibraryState scan failed: $detail');
        }
      } else {
        _error = 'Could not load local songs. Please try again.';
        debugPrint('LocalLibraryState scan failed: $e');
      }
      _songs = const [];
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Opens the system Settings app when permission was permanently denied.
  Future<bool> openSettings() => _service.openSystemSettings();
}
