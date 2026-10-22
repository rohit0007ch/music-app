import 'package:flutter/foundation.dart';
import 'package:melora_music/data/models/playlist.dart';
import 'package:melora_music/data/models/track.dart';

/// Persisted track snapshot inside a [PlaylistRecord].
///
/// Same metadata shape as favorites snapshots, but independent of the
/// Favorites store. [toTrack] does not force `isFavourite`.
class PlaylistTrackRecord {
  const PlaylistTrackRecord({
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

  factory PlaylistTrackRecord.fromTrack(Track track) {
    return PlaylistTrackRecord(
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

  Track toTrack({bool isFavourite = false}) {
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
      isFavourite: isFavourite,
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

  /// Returns `null` when required fields are missing or invalid.
  static PlaylistTrackRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final map = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json);

    final id = _nonEmptyString(map['id']);
    if (id == null) return null;

    final source = _parseSource(map['source']);
    if (source == null) return null;

    return PlaylistTrackRecord(
      id: id,
      source: source,
      title: _stringOr(map['title'], 'Unknown title'),
      artist: _stringOr(map['artist'], 'Unknown artist'),
      album: _stringOr(map['album'], 'Unknown album'),
      durationSeconds: _asNonNegativeInt(map['durationSeconds']) ?? 0,
      paletteIndex: _asNonNegativeInt(map['paletteIndex']) ?? 0,
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

/// Persisted custom playlist (ordered track snapshots).
///
/// Distinct from the UI/mock [Playlist] model, which holds live [Track]s.
class PlaylistRecord {
  const PlaylistRecord({
    required this.id,
    required this.name,
    required this.paletteIndex,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.tracks = const [],
  });

  final String id;
  final String name;
  final int paletteIndex;
  final int createdAtMs;
  final int updatedAtMs;
  final List<PlaylistTrackRecord> tracks;

  int get trackCount => tracks.length;

  PlaylistRecord copyWith({
    String? id,
    String? name,
    int? paletteIndex,
    int? createdAtMs,
    int? updatedAtMs,
    List<PlaylistTrackRecord>? tracks,
  }) {
    return PlaylistRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      paletteIndex: paletteIndex ?? this.paletteIndex,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      tracks: tracks ?? this.tracks,
    );
  }

  /// Builds a UI [Playlist] from snapshots (no local-library re-resolution).
  Playlist toPlaylist() {
    return Playlist(
      id: id,
      name: name,
      paletteIndex: paletteIndex,
      tracks: [for (final t in tracks) t.toTrack()],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'paletteIndex': paletteIndex,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'tracks': [for (final t in tracks) t.toJson()],
    };
  }

  /// Parses one playlist. Invalid track rows are skipped. Returns `null` when
  /// the playlist itself is unusable (missing id/name).
  static PlaylistRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final map = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json);

    final id = PlaylistTrackRecord._nonEmptyString(map['id']);
    final name = PlaylistTrackRecord._nonEmptyString(map['name']);
    if (id == null || name == null) return null;

    final createdAtMs = PlaylistTrackRecord._asNonNegativeInt(
      map['createdAtMs'],
    );
    final updatedAtMs = PlaylistTrackRecord._asNonNegativeInt(
      map['updatedAtMs'],
    );
    if (createdAtMs == null || updatedAtMs == null) return null;

    final rawTracks = map['tracks'];
    final tracks = <PlaylistTrackRecord>[];
    final seenTrackIds = <String>{};
    if (rawTracks is List) {
      for (final item in rawTracks) {
        final track = PlaylistTrackRecord.tryFromJson(item);
        if (track == null) continue;
        if (!seenTrackIds.add(track.id)) continue;
        tracks.add(track);
      }
    }

    return PlaylistRecord(
      id: id,
      name: name,
      paletteIndex:
          PlaylistTrackRecord._asNonNegativeInt(map['paletteIndex']) ?? 0,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      tracks: tracks,
    );
  }
}

/// Resolves a playlist track against the current local library scan by stable ID.
///
/// Intended for UI/playback integration (4B.3). Missing local files stay in the
/// playlist but return a non-playable [Track] (`localUri == null`).
@visibleForTesting
Track resolvePlaylistTrackForDisplay(
  PlaylistTrackRecord record,
  List<Track> localSongs,
) {
  if (record.source == TrackSource.local) {
    for (final song in localSongs) {
      if (song.id == record.id) {
        return song;
      }
    }
    return Track(
      id: record.id,
      title: record.title,
      artist: record.artist,
      album: record.album,
      durationSeconds: record.durationSeconds,
      paletteIndex: record.paletteIndex,
      source: TrackSource.local,
      localId: record.localId,
      localUri: null,
      artworkUri: record.artworkUri,
      genre: record.genre,
    );
  }
  return record.toTrack();
}
