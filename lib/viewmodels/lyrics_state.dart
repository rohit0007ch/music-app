import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/lyrics_repository.dart';

enum LyricsStatus { idle, loading, ready, unavailable, error }

/// Owns lyrics loading for the current Now Playing track.
///
/// Never mutates playback, queue, favorites, or playlists.
class LyricsState extends ChangeNotifier {
  LyricsState({LyricsRepository? repository})
    : _repository = repository ?? MeloraLyricsRepository(),
      _ownsRepository = repository == null;

  final LyricsRepository _repository;
  final bool _ownsRepository;

  int _requestId = 0;
  String? _trackId;
  LyricsStatus _status = LyricsStatus.idle;
  LyricsResult? _result;
  String? _errorMessage;

  LyricsStatus get status => _status;
  LyricsResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get trackId => _trackId;
  bool get isLoading => _status == LyricsStatus.loading;

  /// Loads lyrics for [track], ignoring stale responses from earlier requests.
  Future<void> loadForTrack(Track? track) async {
    if (track == null) {
      _requestId++;
      _trackId = null;
      _status = LyricsStatus.idle;
      _result = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final title = track.title.trim();
    final artist = track.artist.trim();
    if (title.isEmpty || artist.isEmpty) {
      _requestId++;
      _trackId = track.id;
      _status = LyricsStatus.unavailable;
      _result = null;
      _errorMessage = 'Track metadata is incomplete for a lyrics lookup.';
      notifyListeners();
      return;
    }

    // Deduplicate identical in-flight / already-resolved loads.
    if (_trackId == track.id &&
        (_status == LyricsStatus.loading ||
            _status == LyricsStatus.ready ||
            _status == LyricsStatus.unavailable)) {
      return;
    }

    final requestId = ++_requestId;
    _trackId = track.id;
    _status = LyricsStatus.loading;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final lyrics = await _repository.fetchForTrack(track);
      if (requestId != _requestId || _trackId != track.id) return;

      if (lyrics == null || (lyrics.isEmpty && !lyrics.isInstrumental)) {
        _status = LyricsStatus.unavailable;
        _result = null;
        _errorMessage = null;
      } else {
        _status = LyricsStatus.ready;
        _result = lyrics;
        _errorMessage = null;
      }
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId || _trackId != track.id) return;
      _status = LyricsStatus.error;
      _result = null;
      _errorMessage = e is LyricsProviderException
          ? e.message
          : 'Something went wrong loading lyrics.';
      notifyListeners();
    }
  }

  /// Clears the cache for the current id and fetches again.
  Future<void> retry(Track? track) async {
    _status = LyricsStatus.idle;
    _result = null;
    _errorMessage = null;
    _trackId = null;
    await loadForTrack(track);
  }

  @override
  void dispose() {
    _requestId++;
    if (_ownsRepository) _repository.dispose();
    super.dispose();
  }
}
