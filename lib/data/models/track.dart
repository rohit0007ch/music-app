/// Origin of a [Track].
///
/// - [mock]  — demo data shipped with the app; no real audio file exists.
/// - [local] — a file on the device's media library (MediaStore / MPMediaLibrary).
/// - [online] — a permitted online stream (e.g. Jamendo HTTPS audio URL).
///
/// Local identifiers ([Track.localId], [Track.localUri]) are intentionally
/// omitted from any cloud/Firebase synchronisation — they are device-specific
/// and meaningless on another device.
enum TrackSource { mock, local, online }

/// A single music track.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.paletteIndex,
    this.source = TrackSource.mock,
    this.localId,
    this.localUri,
    this.streamUrl,
    this.artworkUri,
    this.licenseUrl,
    this.isFavourite = false,
    this.isDownloaded = false,
    this.genre = '',
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final int paletteIndex;

  /// Origin of this track. Determines how the audio engine resolves audio.
  final TrackSource source;

  /// Platform-native stable identifier.
  /// Android: MediaStore `_ID` (int).
  /// iOS: MPMediaItem `persistentID` (int).
  /// Null for [TrackSource.mock] and [TrackSource.online].
  /// NOT suitable as a cloud-sync key — it is device-specific.
  final int? localId;

  /// Local file/content URI for [TrackSource.local] playback.
  /// Android: `content://media/external/audio/media/<localId>`
  /// iOS:     `ipod-library://item/item.mp3?id=<localId>`
  /// Null for mock and online tracks — do not store HTTPS streams here.
  final String? localUri;

  /// Remote HTTPS stream URL for [TrackSource.online] playback.
  /// Null for mock and local tracks.
  final String? streamUrl;

  /// Content URI or HTTPS URL for artwork, or null.
  final String? artworkUri;

  /// License deed / info URL when provided by the catalog (e.g. Creative
  /// Commons). Presence does **not** imply a commercial Jamendo Pro license.
  final String? licenseUrl;

  final bool isFavourite;
  final bool isDownloaded;
  final String genre;

  /// URI the player should open: [streamUrl] for online, [localUri] for local.
  String? get playbackUri {
    switch (source) {
      case TrackSource.online:
        return _nonEmpty(streamUrl);
      case TrackSource.local:
        return _nonEmpty(localUri);
      case TrackSource.mock:
        return null;
    }
  }

  /// Whether a real audio source URI exists for this track.
  ///
  /// Mock tracks are never playable. Local tracks need [localUri]; online
  /// tracks need [streamUrl]. Prefer [playbackUri] over reading either field
  /// directly at call sites.
  bool get isPlayable {
    if (source == TrackSource.mock) return false;
    return playbackUri != null;
  }

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationSeconds,
    int? paletteIndex,
    TrackSource? source,
    int? localId,
    String? localUri,
    String? streamUrl,
    String? artworkUri,
    String? licenseUrl,
    bool? isFavourite,
    bool? isDownloaded,
    String? genre,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      paletteIndex: paletteIndex ?? this.paletteIndex,
      source: source ?? this.source,
      localId: localId ?? this.localId,
      localUri: localUri ?? this.localUri,
      streamUrl: streamUrl ?? this.streamUrl,
      artworkUri: artworkUri ?? this.artworkUri,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      isFavourite: isFavourite ?? this.isFavourite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      genre: genre ?? this.genre,
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
