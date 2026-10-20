/// Origin of a [Track].
///
/// - [mock]  — demo data shipped with the app; no real audio file exists.
/// - [local] — a file on the device's media library (MediaStore / MPMediaLibrary).
/// - [online] — a permitted online stream (future milestone; not used yet).
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
    this.artworkUri,
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

  /// URI the audio engine opens.
  /// Android: `content://media/external/audio/media/<localId>`
  /// iOS:     `ipod-library://item/item.mp3?id=<localId>`
  /// Null for mock and online tracks.
  final String? localUri;

  /// Content URI for embedded artwork, or null.
  final String? artworkUri;

  final bool isFavourite;
  final bool isDownloaded;
  final String genre;

  /// Whether a real audio source URI exists for this track.
  ///
  /// Mock tracks are never playable. Local/online tracks require a non-empty
  /// [localUri] (file/content URI today; stream URL later for online).
  bool get isPlayable {
    if (source == TrackSource.mock) return false;
    final uri = localUri;
    return uri != null && uri.isNotEmpty;
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
    String? artworkUri,
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
      artworkUri: artworkUri ?? this.artworkUri,
      isFavourite: isFavourite ?? this.isFavourite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      genre: genre ?? this.genre,
    );
  }
}
