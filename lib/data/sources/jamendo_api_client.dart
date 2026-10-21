import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:melora_music/data/sources/jamendo_config.dart';
import 'package:melora_music/data/sources/jamendo_exceptions.dart';

/// Thin HTTP client for Jamendo `/v3.0/tracks` (read-only).
///
/// Does not call download endpoints (`/tracks/file`, `audiodownload` URLs).
class JamendoApiClient {
  JamendoApiClient({
    http.Client? httpClient,
    String? clientId,
    this.baseUrl = JamendoConfig.apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client(),
       _clientId = clientId ?? JamendoConfig.clientId,
       _ownsClient = httpClient == null;

  final http.Client _http;
  final String _clientId;
  final String baseUrl;
  final Duration timeout;
  final bool _ownsClient;

  /// Fetches track objects from `/tracks`.
  ///
  /// Returns the raw `results` list maps. Mapping to [Track] is the
  /// repository's responsibility so filtering stays in one place.
  Future<List<Map<String, dynamic>>> fetchTracks({
    String? search,
    String? namesearch,
    String? tags,
    String? fuzzytags,
    String order = 'popularity_month',
    int limit = 20,
    int offset = 0,
    String audioformat = 'mp32',
  }) async {
    _ensureConfigured();

    final clampedLimit = limit.clamp(1, 200);
    final params = <String, String>{
      'client_id': _clientId,
      'format': 'json',
      'include': 'licenses',
      'audioformat': audioformat,
      'limit': '$clampedLimit',
      'offset': '${offset < 0 ? 0 : offset}',
      'order': order,
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      params['search'] = trimmedSearch;
      // Relevance is required for meaningful search ranking per Jamendo docs.
      params['order'] = 'relevance';
    }

    final trimmedName = namesearch?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      params['namesearch'] = trimmedName;
    }

    final trimmedTags = tags?.trim();
    if (trimmedTags != null && trimmedTags.isNotEmpty) {
      params['tags'] = trimmedTags;
    }

    final trimmedFuzzy = fuzzytags?.trim();
    if (trimmedFuzzy != null && trimmedFuzzy.isNotEmpty) {
      params['fuzzytags'] = trimmedFuzzy;
    }

    final uri = Uri.parse('$baseUrl/tracks/').replace(queryParameters: params);

    late final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const JamendoHttpException('Jamendo request timed out.');
    } on http.ClientException catch (e) {
      throw JamendoHttpException('Jamendo network error: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw JamendoHttpException(
        'Jamendo HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    return _parseTracksDocument(response.body);
  }

  List<Map<String, dynamic>> _parseTracksDocument(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw JamendoParseException('Invalid JSON from Jamendo: ${e.message}');
    }

    if (decoded is! Map) {
      throw const JamendoParseException(
        'Jamendo response root must be a JSON object.',
      );
    }

    final root = Map<String, dynamic>.from(decoded);
    final headers = root['headers'];
    if (headers is Map) {
      final status = headers['status']?.toString();
      final code = headers['code'];
      final errorMessage = headers['error_message']?.toString() ?? '';
      if (status != null && status != 'success') {
        throw JamendoApiException(
          errorMessage.isEmpty ? 'Jamendo API status "$status".' : errorMessage,
          code: code is int ? code : int.tryParse(code?.toString() ?? ''),
        );
      }
    }

    final results = root['results'];
    if (results == null) {
      return const [];
    }
    if (results is! List) {
      throw const JamendoParseException(
        'Jamendo "results" must be a JSON array.',
      );
    }

    final tracks = <Map<String, dynamic>>[];
    for (final item in results) {
      if (item is Map) {
        tracks.add(Map<String, dynamic>.from(item));
      }
    }
    return tracks;
  }

  void _ensureConfigured() {
    if (_clientId.trim().isEmpty) {
      throw const JamendoConfigException(
        'JAMENDO_CLIENT_ID is missing. Pass '
        '--dart-define=JAMENDO_CLIENT_ID=your_client_id',
      );
    }
  }

  void dispose() {
    if (_ownsClient) {
      _http.close();
    }
  }
}
