import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:melora_music/data/models/track.dart';

/// Thin wrapper around [AudioPlayer] from `just_audio`.
///
/// Responsibilities:
/// - Resolves [Track] audio for local/online/asset sources.
/// - Refuses mock / non-playable tracks and malformed URIs before touching
///   `just_audio`.
/// - Configures [AudioSession] for music playback on first use.
/// - Exposes raw streams so [MeloraPlayerState] can derive UI state.
///
/// This class has no UI knowledge and is tested independently.
class AudioEngine {
  AudioEngine() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _sessionConfigured = false;

  // ── Streams ──────────────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Emits a [PlayerState] from just_audio (playing + processingState).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ── Playback commands ─────────────────────────────────────────────────────

  /// Loads and plays [track] via a resolved [AudioSource].
  ///
  /// Throws [ArgumentError] or [FormatException] if the track cannot be played
  /// (mock, missing URI/path, wrong scheme for source). Callers must not invoke
  /// this for demo tracks.
  Future<void> play(Track track) async {
    // Validate before any async player work so failures stay synchronous and
    // do not leave just_audio mid-load.
    final source = resolveAudioSource(track);

    await _ensureSessionConfigured();
    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();

  // ── Source resolution (testable without a live player) ────────────────────

  /// Builds a tagged [AudioSource] for [track].
  ///
  /// - [TrackSource.online] → [AudioSource.uri] http(s)
  /// - [TrackSource.local] → [AudioSource.uri] file/content/…
  /// - [TrackSource.asset] → [AudioSource.asset]
  /// - [TrackSource.mock] → always rejected
  static AudioSource resolveAudioSource(Track track) {
    final tag = _mediaItemFor(track);

    if (track.source == TrackSource.asset) {
      final path = track.assetPath?.trim();
      if (path == null || path.isEmpty) {
        throw ArgumentError('Asset track "${track.title}" has no assetPath.');
      }
      if (!path.startsWith('assets/')) {
        throw ArgumentError(
          'Asset track "${track.title}" path must start with "assets/", '
          'got "$path".',
        );
      }
      return AudioSource.asset(path, tag: tag);
    }

    final uri = resolvePlaybackUri(track);
    return AudioSource.uri(uri, tag: tag);
  }

  /// Resolves and validates a URI for local/online playback.
  ///
  /// Asset tracks should use [resolveAudioSource] — this method still returns
  /// a synthetic `asset:` [Uri] for tests that assert path identity.
  ///
  /// - [TrackSource.online] → http(s) [Track.streamUrl]
  /// - [TrackSource.local] → non-http(s) [Track.localUri] (content/file/…)
  /// - [TrackSource.asset] → `asset:` URI whose path is [Track.assetPath]
  /// - [TrackSource.mock] → always rejected
  static Uri resolvePlaybackUri(Track track) {
    if (track.source == TrackSource.mock) {
      throw ArgumentError(
        'AudioEngine cannot load mock track "${track.title}". '
        'Show demo-unavailable UI instead.',
      );
    }

    if (track.source == TrackSource.asset) {
      final path = track.assetPath?.trim();
      if (path == null || path.isEmpty) {
        throw ArgumentError('Track "${track.title}" (asset) has no assetPath.');
      }
      if (!path.startsWith('assets/')) {
        throw ArgumentError(
          'Asset path must start with "assets/", got "$path".',
        );
      }
      return Uri(scheme: 'asset', path: path);
    }

    final raw = track.playbackUri;
    if (raw == null) {
      throw ArgumentError(
        'Track "${track.title}" (${track.source.name}) has no playback URI.',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) {
      throw FormatException('Malformed playback URI: $raw');
    }

    switch (track.source) {
      case TrackSource.online:
        if (uri.scheme != 'http' && uri.scheme != 'https') {
          throw ArgumentError(
            'Online track "${track.title}" requires an http(s) stream URL, '
            'got scheme "${uri.scheme}".',
          );
        }
        if (uri.host.isEmpty) {
          throw FormatException('Online stream URI is missing a host: $raw');
        }
      case TrackSource.local:
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          throw ArgumentError(
            'Local track "${track.title}" must use a file/content URI, '
            'not http(s). Put remote audio in streamUrl with '
            'TrackSource.online.',
          );
        }
      case TrackSource.asset:
      case TrackSource.mock:
        throw ArgumentError(
          'AudioEngine cannot load mock track "${track.title}".',
        );
    }

    return uri;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _ensureSessionConfigured() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  static MediaItem _mediaItemFor(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: Duration(seconds: track.durationSeconds),
      artUri: _mediaArtUri(track.artworkUri),
    );
  }

  /// OS media controls need a network/file URI — Flutter asset paths are not
  /// valid [MediaItem.artUri] values.
  static Uri? _mediaArtUri(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('assets/')) return null;
    return Uri.tryParse(value);
  }
}
