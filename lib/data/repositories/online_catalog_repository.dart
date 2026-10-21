import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/sources/jamendo_api_client.dart';
import 'package:melora_music/data/sources/jamendo_track_mapper.dart';

/// Online music catalog backed by Jamendo `/v3.0/tracks`.
///
/// Streaming only — never requests download endpoints. Commercial licensing
/// suitability of returned tracks is **not** asserted; callers must treat
/// [Track.licenseUrl] as attribution metadata only.
class OnlineCatalogRepository {
  OnlineCatalogRepository({JamendoApiClient? client})
    : _client = client ?? JamendoApiClient(),
      _ownsClient = client == null;

  final JamendoApiClient _client;
  final bool _ownsClient;

  /// Free-text search. Empty [query] falls back to a popular listing.
  Future<List<Track>> searchTracks({
    String query = '',
    int limit = 20,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    final results = await _client.fetchTracks(
      search: trimmed.isEmpty ? null : trimmed,
      order: trimmed.isEmpty ? 'popularity_month' : 'relevance',
      limit: limit,
      offset: offset,
    );
    return JamendoTrackMapper.mapAll(results);
  }

  /// Tag / genre discovery (Jamendo `tags` = AND semantics).
  Future<List<Track>> tracksForTags({
    required String tags,
    int limit = 20,
    int offset = 0,
  }) async {
    final results = await _client.fetchTracks(
      tags: tags,
      order: 'popularity_month',
      limit: limit,
      offset: offset,
    );
    return JamendoTrackMapper.mapAll(results);
  }

  /// Popular tracks for an empty Discover landing state.
  Future<List<Track>> popularTracks({int limit = 20, int offset = 0}) {
    return searchTracks(query: '', limit: limit, offset: offset);
  }

  void dispose() {
    if (_ownsClient) {
      _client.dispose();
    }
  }
}
