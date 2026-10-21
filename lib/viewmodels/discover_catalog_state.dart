import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/online_catalog_repository.dart';
import 'package:melora_music/data/sources/jamendo_config.dart';
import 'package:melora_music/data/sources/jamendo_exceptions.dart';

/// Discover screen state for Jamendo popular / search / tag browsing.
///
/// Uses a monotonic request id so slower responses cannot overwrite newer ones.
class DiscoverCatalogState extends ChangeNotifier {
  DiscoverCatalogState({
    OnlineCatalogRepository? repository,
    bool? isConfigured,
  }) : _repository = repository ?? OnlineCatalogRepository(),
       _ownsRepository = repository == null,
       _isConfigured = isConfigured ?? JamendoConfig.isConfigured;

  final OnlineCatalogRepository _repository;
  final bool _ownsRepository;
  final bool _isConfigured;

  int _requestId = 0;
  List<Track> _tracks = const [];
  bool _loading = false;
  String? _errorMessage;
  bool _needsConfig = false;
  String _activeQuery = '';
  String? _activeTags;

  List<Track> get tracks => List.unmodifiable(_tracks);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get needsConfig => _needsConfig;
  bool get hasTracks => _tracks.isNotEmpty;
  String get activeQuery => _activeQuery;
  String? get activeTags => _activeTags;
  bool get isFiltered =>
      _activeQuery.isNotEmpty ||
      (_activeTags != null && _activeTags!.isNotEmpty);

  /// Initial / retry popular listing.
  Future<void> loadPopular() =>
      _run(query: '', tags: null, loader: () => _repository.popularTracks());

  /// Free-text search (call on submit, not every keystroke).
  Future<void> search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return loadPopular();
    return _run(
      query: trimmed,
      tags: null,
      loader: () => _repository.searchTracks(query: trimmed),
    );
  }

  /// Genre / mood tag browse via Jamendo `tags`.
  Future<void> loadTags(String tags) {
    final trimmed = tags.trim();
    if (trimmed.isEmpty) return loadPopular();
    return _run(
      query: '',
      tags: trimmed,
      loader: () => _repository.tracksForTags(tags: trimmed),
    );
  }

  Future<void> retry() {
    final tags = _activeTags;
    if (tags != null && tags.isNotEmpty) return loadTags(tags);
    if (_activeQuery.isNotEmpty) return search(_activeQuery);
    return loadPopular();
  }

  Future<void> _run({
    required String query,
    required String? tags,
    required Future<List<Track>> Function() loader,
  }) async {
    if (!_isConfigured) {
      _needsConfig = true;
      _loading = false;
      _tracks = const [];
      _errorMessage =
          'Jamendo is not configured. Run with '
          '--dart-define=JAMENDO_CLIENT_ID=your_client_id';
      _activeQuery = query;
      _activeTags = tags;
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    _needsConfig = false;
    _loading = true;
    _errorMessage = null;
    _activeQuery = query;
    _activeTags = tags;
    notifyListeners();

    try {
      final tracks = await loader();
      if (requestId != _requestId) return;
      _tracks = tracks;
      _loading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (requestId != _requestId) return;
      _tracks = const [];
      _loading = false;
      _errorMessage = _friendlyMessage(e);
      _needsConfig = e is JamendoConfigException;
      notifyListeners();
    }
  }

  static String _friendlyMessage(Object error) {
    if (error is JamendoConfigException) {
      return 'Jamendo is not configured. Pass '
          '--dart-define=JAMENDO_CLIENT_ID=your_client_id';
    }
    if (error is JamendoHttpException) {
      return 'Could not reach the music catalog. Check your connection and try again.';
    }
    if (error is JamendoParseException || error is JamendoApiException) {
      return 'The catalog returned an unexpected response. Please try again.';
    }
    return 'Something went wrong loading music. Please try again.';
  }

  @override
  void dispose() {
    if (_ownsRepository) {
      _repository.dispose();
    }
    super.dispose();
  }
}
