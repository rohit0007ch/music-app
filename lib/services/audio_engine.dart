import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:melora_music/data/models/track.dart';

/// Thin wrapper around [AudioPlayer] from `just_audio`.
///
/// Responsibilities:
/// - Converts a [Track] to an [AudioSource] (local URI or content URI).
/// - Refuses to load [TrackSource.mock] tracks — callers must check
///   [Track.isPlayable] and show the appropriate UI state instead.
/// - Configures [AudioSession] for music playback on first use.
/// - Exposes raw streams so [PlayerState] can derive its own UI state.
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

  /// Loads and plays [track].
  ///
  /// Throws [ArgumentError] if [track.isPlayable] is false — callers must
  /// never attempt to load a mock track into the audio engine.
  Future<void> play(Track track) async {
    if (!track.isPlayable) {
      throw ArgumentError(
        'AudioEngine.play() called with a non-playable track '
        '"${track.title}". Show demo-unavailable UI instead.',
      );
    }
    await _ensureSessionConfigured();
    final source = _toAudioSource(track);
    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _ensureSessionConfigured() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  /// Converts a playable [Track] to a [just_audio_background] [AudioSource].
  ///
  /// The [MediaItem] tag is picked up by `just_audio_background` to populate
  /// the Android notification and iOS lock-screen / Control Center.
  AudioSource _toAudioSource(Track track) {
    assert(track.isPlayable, 'Only playable tracks reach _toAudioSource');
    assert(track.localUri != null, 'Playable track must have a localUri');

    final tag = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: Duration(seconds: track.durationSeconds),
      artUri: track.artworkUri != null ? Uri.tryParse(track.artworkUri!) : null,
    );

    return AudioSource.uri(Uri.parse(track.localUri!), tag: tag);
  }
}
