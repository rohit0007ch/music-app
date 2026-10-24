import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin HTTP client for the documented LRCLIB public API.
///
/// Docs: https://lrclib.net/docs — no API key required. Identify the app via
/// User-Agent. Lyrics content licensing is separate from API access; Melora
/// displays results for personal listening only and does not cache lyrics.
class LrclibApiClient {
  LrclibApiClient({
    http.Client? httpClient,
    this.baseUrl = 'https://lrclib.net',
    this.timeout = const Duration(seconds: 12),
    this.userAgent =
        'MeloraMusic/1.0 (https://github.com/rohit0007ch/music-app)',
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final http.Client _http;
  final bool _ownsClient;
  final String baseUrl;
  final Duration timeout;
  final String userAgent;

  Map<String, String> get _headers => {
    'User-Agent': userAgent,
    'Accept': 'application/json',
  };

  /// Exact-ish lookup. Returns `null` on HTTP 404 (not found).
  Future<Map<String, dynamic>?> getLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    final params = <String, String>{
      'track_name': trackName,
      'artist_name': artistName,
    };
    final album = albumName?.trim();
    if (album != null && album.isNotEmpty) {
      params['album_name'] = album;
    }
    if (durationSeconds != null && durationSeconds > 0) {
      params['duration'] = '$durationSeconds';
    }

    final uri = Uri.parse('$baseUrl/api/get').replace(queryParameters: params);

    final response = await _get(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LrclibHttpException(
        'LRCLIB HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return _decodeObject(response.body);
  }

  /// Search fallback. Returns an empty list when nothing matches.
  Future<List<Map<String, dynamic>>> search({
    required String trackName,
    required String artistName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {'track_name': trackName, 'artist_name': artistName},
    );

    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LrclibHttpException(
        'LRCLIB HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const LrclibParseException('LRCLIB search returned non-list JSON.');
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _http.get(uri, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw const LrclibHttpException('LRCLIB request timed out.');
    } on http.ClientException catch (e) {
      throw LrclibHttpException('LRCLIB network error: ${e.message}');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const LrclibParseException('LRCLIB returned invalid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LrclibParseException('LRCLIB returned unexpected JSON.');
    }
    return decoded;
  }

  void dispose() {
    if (_ownsClient) _http.close();
  }
}

class LrclibHttpException implements Exception {
  const LrclibHttpException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class LrclibParseException implements Exception {
  const LrclibParseException(this.message);
  final String message;

  @override
  String toString() => message;
}
