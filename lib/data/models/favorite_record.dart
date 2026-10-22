import 'package:melora_music/data/models/track.dart';

/// Persisted favorite metadata for a [Track].
///
/// Membership in the favorites store is the source of truth — this record does
/// **not** store `isFavourite`. [toTrack] sets `isFavourite: true` for UI use.
class FavoriteRecord {
  const FavoriteRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.paletteIndex,
    this.localId,
    this.localUri,
    this.streamUrl,
    this.artworkUri,
    this.licenseUrl,
    this.genre = '',
  });

  final String id;
  final TrackSource source;
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final int paletteIndex;
  final int? localId;
  final String? localUri;
  final String? streamUrl;
  final String? artworkUri;
  final String? licenseUrl;
  final String genre;

  /// Snapshot of [track] suitable for persistence.
  factory FavoriteRecord.fromTrack(Track track) {
    return FavoriteRecord(
      id: track.id,
      source: track.source,
      title: track.title,
      artist: track.artist,
      album: track.album,
      durationSeconds: track.durationSeconds,
      paletteIndex: track.paletteIndex,
      localId: track.localId,
      localUri: track.localUri,
      streamUrl: track.streamUrl,
      artworkUri: track.artworkUri,
      licenseUrl: track.licenseUrl,
      genre: track.genre,
    );
  }

  /// Rebuilds a [Track] marked as favourite for list / playback wiring.
  Track toTrack() {
    return Track(
      id: id,
      title: title,
      artist: artist,
      album: album,
      durationSeconds: durationSeconds,
      paletteIndex: paletteIndex,
      source: source,
      localId: localId,
      localUri: localUri,
      streamUrl: streamUrl,
      artworkUri: artworkUri,
      licenseUrl: licenseUrl,
      isFavourite: true,
      genre: genre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'title': title,
      'artist': artist,
      'album': album,
      'durationSeconds': durationSeconds,
      'paletteIndex': paletteIndex,
      if (localId != null) 'localId': localId,
      if (localUri != null) 'localUri': localUri,
      if (streamUrl != null) 'streamUrl': streamUrl,
      if (artworkUri != null) 'artworkUri': artworkUri,
      if (licenseUrl != null) 'licenseUrl': licenseUrl,
      if (genre.isNotEmpty) 'genre': genre,
    };
  }

  /// Parses one persisted map. Returns `null` when required fields are missing
  /// or invalid so a bad entry cannot break the whole list.
  static FavoriteRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final map = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json);

    final id = _nonEmptyString(map['id']);
    if (id == null) return null;

    final source = _parseSource(map['source']);
    if (source == null) return null;

    final durationSeconds = _asNonNegativeInt(map['durationSeconds']) ?? 0;
    final paletteIndex = _asNonNegativeInt(map['paletteIndex']) ?? 0;

    return FavoriteRecord(
      id: id,
      source: source,
      title: _stringOr(map['title'], 'Unknown title'),
      artist: _stringOr(map['artist'], 'Unknown artist'),
      album: _stringOr(map['album'], 'Unknown album'),
      durationSeconds: durationSeconds,
      paletteIndex: paletteIndex,
      localId: _asInt(map['localId']),
      localUri: _optionalString(map['localUri']),
      streamUrl: _optionalString(map['streamUrl']),
      artworkUri: _optionalString(map['artworkUri']),
      licenseUrl: _optionalString(map['licenseUrl']),
      genre: _stringOr(map['genre'], ''),
    );
  }

  static TrackSource? _parseSource(Object? value) {
    final name = value?.toString().trim();
    if (name == null || name.isEmpty) return null;
    for (final source in TrackSource.values) {
      if (source.name == name) return source;
    }
    return null;
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String _stringOr(Object? value, String fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static int? _asNonNegativeInt(Object? value) {
    final parsed = _asInt(value);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
}
