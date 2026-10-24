import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/sources/lrclib_api_client.dart';

/// Looks up lyrics for a [Track] without affecting playback.
abstract class LyricsRepository {
  Future<LyricsResult?> fetchForTrack(Track track);
  void dispose();
}

/// LRCLIB-backed lyrics repository with conservative matching.
class LrclibLyricsRepository implements LyricsRepository {
  LrclibLyricsRepository({LrclibApiClient? client})
    : _client = client ?? LrclibApiClient(),
      _ownsClient = client == null;

  final LrclibApiClient _client;
  final bool _ownsClient;

  static const sourceName = 'LRCLIB';

  @override
  Future<LyricsResult?> fetchForTrack(Track track) async {
    final title = track.title.trim();
    final artist = track.artist.trim();
    if (title.isEmpty || artist.isEmpty) {
      return null;
    }

    try {
      final direct = await _client.getLyrics(
        trackName: title,
        artistName: artist,
        albumName: track.album.trim().isEmpty ? null : track.album.trim(),
        durationSeconds: track.durationSeconds > 0
            ? track.durationSeconds
            : null,
      );
      if (direct != null) {
        final mapped = _mapRecord(track.id, direct);
        if (mapped != null) return mapped;
      }

      final results = await _client.search(
        trackName: title,
        artistName: artist,
      );
      for (final record in results) {
        if (!_isConfidentMatch(record, title: title, artist: artist)) {
          continue;
        }
        final mapped = _mapRecord(track.id, record);
        if (mapped != null) return mapped;
      }
      return null;
    } on LrclibHttpException {
      throw const LyricsProviderException(
        'Could not reach the lyrics service. Check your connection and try again.',
      );
    } on LrclibParseException {
      throw const LyricsProviderException(
        'The lyrics service returned an unexpected response.',
      );
    } catch (_) {
      throw const LyricsProviderException(
        'Something went wrong loading lyrics.',
      );
    }
  }

  LyricsResult? _mapRecord(String trackId, Map<String, dynamic> json) {
    final instrumental = json['instrumental'] == true;
    final synced = _asString(json['syncedLyrics']);
    final plain = _asString(json['plainLyrics']);

    final lines = <LyricLine>[];
    if (synced != null && synced.isNotEmpty) {
      lines.addAll(parseSyncedLyrics(synced));
    }
    if (lines.isEmpty && plain != null && plain.isNotEmpty) {
      lines.addAll(parsePlainLyrics(plain));
    }

    if (!instrumental && lines.isEmpty) return null;

    return LyricsResult(
      trackId: trackId,
      sourceName: sourceName,
      lines: lines,
      isInstrumental: instrumental,
      providerTrackName:
          _asString(json['trackName']) ?? _asString(json['name']),
      providerArtistName: _asString(json['artistName']),
    );
  }

  /// Requires case-insensitive equality on title and artist (trimmed).
  bool _isConfidentMatch(
    Map<String, dynamic> record, {
    required String title,
    required String artist,
  }) {
    final recordTitle =
        (_asString(record['trackName']) ?? _asString(record['name']) ?? '')
            .trim()
            .toLowerCase();
    final recordArtist = (_asString(record['artistName']) ?? '')
        .trim()
        .toLowerCase();
    if (recordTitle.isEmpty || recordArtist.isEmpty) return false;
    return recordTitle == title.toLowerCase() &&
        recordArtist == artist.toLowerCase();
  }

  static String? _asString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  /// Parses LRC timed lyrics into [LyricLine]s.
  static List<LyricLine> parseSyncedLyrics(String synced) {
    final pattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');
    final lines = <LyricLine>[];
    for (final raw in synced.split(RegExp(r'\r?\n'))) {
      final match = pattern.firstMatch(raw.trim());
      if (match == null) continue;
      final minutes = int.tryParse(match.group(1)!) ?? 0;
      final seconds = int.tryParse(match.group(2)!) ?? 0;
      final fraction = match.group(3);
      var millis = 0;
      if (fraction != null && fraction.isNotEmpty) {
        final padded = fraction.padRight(3, '0').substring(0, 3);
        millis = int.tryParse(padded) ?? 0;
      }
      final text = match.group(4)?.trim() ?? '';
      if (text.isEmpty) continue;
      lines.add(
        LyricLine(
          text: text,
          start: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: millis,
          ),
        ),
      );
    }
    lines.sort(
      (a, b) => (a.start ?? Duration.zero).compareTo(b.start ?? Duration.zero),
    );
    return lines;
  }

  static List<LyricLine> parsePlainLyrics(String plain) {
    return [
      for (final line in plain.split(RegExp(r'\r?\n')))
        if (line.trim().isNotEmpty) LyricLine(text: line.trim()),
    ];
  }

  @override
  void dispose() {
    if (_ownsClient) _client.dispose();
  }
}
