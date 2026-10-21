import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:melora_music/data/models/track.dart';

/// Thin wrapper around [AudioPlayer] from `just_audio`.
///
/// Responsibilities:
/// - Resolves [Track.playbackUri] (local file/content URI or online HTTPS).
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

  /// Loads and plays [track] via [Track.playbackUri].
  ///
  /// Throws [ArgumentError] or [FormatException] if the track cannot be played
  /// (mock, missing URI, wrong scheme for source). Callers must not invoke
  /// this for demo tracks.
  Future<void> play(Track track) async {
    // Validate before any async player work so failures stay synchronous and
    // do not leave just_audio mid-load.
    final uri = resolvePlaybackUri(track);

    await _ensureSessionConfigured();
    final source = _toAudioSource(track, uri);
    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();

  // ── URI resolution (testable without a live player) ───────────────────────

  /// Resolves and validates the URI that `just_audio` should open.
  ///
  /// - [TrackSource.online] → http(s) [Track.streamUrl]
  /// - [TrackSource.local] → non-http(s) [Track.localUri] (content/file/…)
  /// - [TrackSource.mock] → always rejected
  static Uri resolvePlaybackUri(Track track) {
    if (track.source == TrackSource.mock) {
      throw ArgumentError(
        'AudioEngine cannot load mock track "${track.title}". '
        'Show demo-unavailable UI instead.',
      );
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

  /// Builds a tagged [AudioSource] for notification / lock-screen metadata.
  AudioSource _toAudioSource(Track track, Uri uri) {
    final tag = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: Duration(seconds: track.durationSeconds),
      artUri: track.artworkUri != null ? Uri.tryParse(track.artworkUri!) : null,
    );

    return AudioSource.uri(uri, tag: tag);
  }
}
