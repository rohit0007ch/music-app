import 'package:melora_music/data/models/track.dart';

/// Maps Jamendo `/tracks` result objects into Melora [Track]s.
///
/// Returns `null` when the entry cannot be streamed (missing/blank `audio`).
/// Does not read or promote `audiodownload` fields.
abstract final class JamendoTrackMapper {
  /// Converts one API result map, or `null` if unusable for streaming.
  static Track? fromJson(Map<String, dynamic> json) {
    final streamUrl = _streamUrl(json);
    if (streamUrl == null) return null;

    final rawId = json['id'];
    final idString = rawId?.toString().trim();
    if (idString == null || idString.isEmpty) return null;

    final numericId = int.tryParse(idString);
    final durationSeconds = _durationSeconds(json['duration']);

    return Track(
      id: 'online_$idString',
      title: _text(json['name'], fallback: 'Unknown title'),
      artist: _text(json['artist_name'], fallback: 'Unknown artist'),
      album: _text(json['album_name'], fallback: 'Unknown album'),
      durationSeconds: durationSeconds,
      paletteIndex: (numericId ?? idString.hashCode).abs() % 8,
      source: TrackSource.online,
      // Keep local file URI unset for online catalog tracks.
      localUri: null,
      streamUrl: streamUrl,
      artworkUri: _optionalUrl(json['image']),
      licenseUrl: _optionalUrl(json['license_ccurl']),
      genre: _genre(json),
    );
  }

  /// Maps many results, dropping entries without a usable stream URL.
  static List<Track> mapAll(Iterable<Map<String, dynamic>> results) {
    final tracks = <Track>[];
    for (final json in results) {
      final track = fromJson(json);
      if (track != null) tracks.add(track);
    }
    return tracks;
  }

  static String? _streamUrl(Map<String, dynamic> json) {
    final audio = _optionalUrl(json['audio']);
    if (audio == null) return null;
    final uri = Uri.tryParse(audio);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return audio;
  }

  static String? _optionalUrl(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String _text(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  static int _durationSeconds(Object? value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final seconds = value.round();
      return seconds < 0 ? 0 : seconds;
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  static String _genre(Map<String, dynamic> json) {
    final musicinfo = json['musicinfo'];
    if (musicinfo is! Map) return '';
    final tags = musicinfo['tags'];
    if (tags is! Map) return '';
    final genres = tags['genres'];
    if (genres is List && genres.isNotEmpty) {
      return genres.first.toString();
    }
    return '';
  }
}
