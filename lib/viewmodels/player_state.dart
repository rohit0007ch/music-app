import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/audio_engine.dart';

export 'package:melora_music/data/models/track.dart' show TrackSource;

/// Playback repeat behaviour.
enum RepeatMode { none, all, one }

/// Central playback state and controller.
///
/// Owns an [AudioEngine] and listens to its streams to derive real-time
/// position and playing state. UI widgets consume this via [ListenableBuilder].
///
/// Non-playable demo tracks never reach the audio engine. Selecting one while
/// a playable track is current leaves that track alone and surfaces
/// [demoNotPlayableMessage] for the UI.
class MeloraPlayerState extends ChangeNotifier {
  MeloraPlayerState({AudioEngine? engine}) : _engine = engine ?? AudioEngine() {
    _queue = List<Track>.from(MockData.tracks);
    _subscribeToEngine();
  }

  /// Shown when the user tries to play a track with no real audio source.
  static const String demoNotPlayableMessage =
      "This demo track isn't playable yet.";

  final AudioEngine _engine;
  final Random _random = Random();

  Track? _currentTrack;
  bool _isPlaying = false;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;
  double _progress = 0.0; // 0.0 – 1.0
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<Track> _queue = [];
  List<int> _shuffleOrder = [];
  int? _sleepTimerMinutes;
  Timer? _sleepTimer;
  String? _error;
  String? _userMessage;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _stateSub;

  // ── Public getters ────────────────────────────────────────────────────────

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;
  List<Track> get queue => List.unmodifiable(_queue);
  int? get sleepTimerMinutes => _sleepTimerMinutes;

  /// Whether [currentTrack] has a real audio source.
  bool get isCurrentPlayable =>
      _currentTrack != null && _currentTrack!.isPlayable;

  /// Non-null when the audio engine raised an error on the last operation.
  String? get error => _error;

  /// Transient UX message (e.g. demo track not playable).
  String? get userMessage => _userMessage;

  /// Returns and clears [userMessage], if any.
  String? takeUserMessage() {
    final message = _userMessage;
    _userMessage = null;
    return message;
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Replaces the playback queue. Does not change the current track.
  void setQueue(List<Track> tracks) {
    _queue = List<Track>.from(tracks);
    _rebuildShuffleOrder();
    notifyListeners();
  }

  /// Loads [track] and starts playback when it is playable.
  ///
  /// When [queueContext] is provided, the queue is replaced first (e.g. local
  /// library songs). Returns `true` when the engine was asked to play.
  Future<bool> playTrack(Track track, {List<Track>? queueContext}) async {
    if (queueContext != null) {
      _queue = List<Track>.from(queueContext);
      _rebuildShuffleOrder();
    } else if (!_queue.any((t) => t.id == track.id)) {
      _queue = [..._queue, track];
      _rebuildShuffleOrder();
    }

    if (!track.isPlayable) {
      _userMessage = demoNotPlayableMessage;
      // Never interrupt a playable current track with a demo selection.
      final protectPlayable = isCurrentPlayable;
      if (!protectPlayable) {
        _currentTrack = track;
        _isPlaying = false;
        _progress = 0.0;
        _position = Duration.zero;
        _duration = Duration.zero;
        _error = null;
      }
      notifyListeners();
      return false;
    }

    _userMessage = null;
    _error = null;
    _currentTrack = track;
    // Snapshot queue identity so a failed load cannot be confused with a
    // queue mutation (play must not alter [_queue] on error).
    final queueLengthBefore = _queue.length;

    try {
      await _engine.play(track);
    } catch (e) {
      _error = e.toString();
      _isPlaying = false;
      _progress = 0.0;
      // Keep [_currentTrack] as the attempted track so the UI can show the
      // error; never roll the queue back except to assert stability.
      assert(_queue.length == queueLengthBefore);
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    if (!_currentTrack!.isPlayable) {
      _userMessage = demoNotPlayableMessage;
      notifyListeners();
      return;
    }
    if (_isPlaying) {
      await _engine.pause();
    } else {
      await _engine.resume();
    }
  }

  Future<void> skipNext() async {
    final next = _findRelativeTrack(1);
    if (next == null) return;
    await playTrack(next);
  }

  Future<void> skipPrevious() async {
    if (_currentTrack == null) return;
    // If more than 3 s into track, restart from beginning.
    if (_position.inSeconds > 3 && _currentTrack!.isPlayable) {
      await _engine.seek(Duration.zero);
      return;
    }
    final prev = _findRelativeTrack(-1);
    if (prev == null) return;
    await playTrack(prev);
  }

  Future<void> seekTo(double value) async {
    if (_currentTrack == null || !_currentTrack!.isPlayable) return;
    final target = Duration(
      milliseconds: (value.clamp(0.0, 1.0) * _duration.inMilliseconds).round(),
    );
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
    await _engine.seek(target);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      _rebuildShuffleOrder();
    }
    notifyListeners();
  }

  void cycleRepeat() {
    _repeatMode =
        RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  /// Aligns [Track.isFavourite] on the current track and queue with [isFavorite].
  ///
  /// Does not change queue order, playback position, or the audio engine.
  /// [FavoritesState] remains the source of truth for membership.
  void syncFavouriteFlags(bool Function(String id) isFavorite) {
    var changed = false;

    if (_currentTrack != null) {
      final next = isFavorite(_currentTrack!.id);
      if (_currentTrack!.isFavourite != next) {
        _currentTrack = _currentTrack!.copyWith(isFavourite: next);
        changed = true;
      }
    }

    for (var i = 0; i < _queue.length; i++) {
      final track = _queue[i];
      final next = isFavorite(track.id);
      if (track.isFavourite != next) {
        _queue[i] = track.copyWith(isFavourite: next);
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerMinutes = minutes;
    if (minutes != null && minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        _sleepTimerMinutes = null;
        _sleepTimer = null;
        if (_currentTrack != null && _currentTrack!.isPlayable && _isPlaying) {
          await _engine.pause();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Test-only: set the current track without touching the audio engine.
  @visibleForTesting
  void debugSetCurrentTrack(Track? track, {bool isPlaying = false}) {
    _currentTrack = track;
    _isPlaying = isPlaying;
    if (track == null || !track.isPlayable) {
      _progress = 0.0;
      _position = Duration.zero;
      _duration = Duration.zero;
    }
    notifyListeners();
  }

  /// Test-only: peek at next/previous selection without invoking the engine.
  @visibleForTesting
  Track? debugPeekRelative(int direction) => _findRelativeTrack(direction);

  // ── Convenience labels ────────────────────────────────────────────────────

  int get elapsedSeconds => _position.inSeconds;
  int get remainingSeconds =>
      (_currentTrack?.durationSeconds ?? 0) - elapsedSeconds;

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  String get elapsedLabel => _fmt(elapsedSeconds);
  String get remainingLabel => '-${_fmt(remainingSeconds.clamp(0, 99999))}';

  // ── Queue helpers ─────────────────────────────────────────────────────────

  List<Track> _orderedQueue() {
    if (!_isShuffle || _shuffleOrder.length != _queue.length) {
      return _queue;
    }
    return [for (final i in _shuffleOrder) _queue[i]];
  }

  void _rebuildShuffleOrder() {
    _shuffleOrder = List<int>.generate(_queue.length, (i) => i);
    _shuffleOrder.shuffle(_random);
    // Keep current track first in shuffle order when possible.
    if (_currentTrack != null) {
      final currentIndex = _queue.indexWhere((t) => t.id == _currentTrack!.id);
      if (currentIndex >= 0) {
        _shuffleOrder.remove(currentIndex);
        _shuffleOrder.insert(0, currentIndex);
      }
    }
  }

  /// Finds the next/previous track. When the current track is playable, skips
  /// non-playable demos so they cannot interrupt real audio.
  Track? _findRelativeTrack(int direction) {
    if (_queue.isEmpty || _currentTrack == null) return null;
    final order = _orderedQueue();
    final start = order.indexWhere((t) => t.id == _currentTrack!.id);
    if (start < 0) return order.first;

    final preferPlayable = _currentTrack!.isPlayable;
    for (var step = 1; step <= order.length; step++) {
      final index = _wrapIndex(start + direction * step, order.length);
      final candidate = order[index];
      if (!preferPlayable || candidate.isPlayable) {
        return candidate;
      }
    }
    return null;
  }

  int _wrapIndex(int index, int length) => (index % length + length) % length;

  // ── Engine stream subscriptions ───────────────────────────────────────────

  void _subscribeToEngine() {
    _positionSub = _engine.positionStream.listen((pos) {
      _position = pos;
      final durMs = _duration.inMilliseconds;
      _progress = durMs > 0
          ? (pos.inMilliseconds / durMs).clamp(0.0, 1.0)
          : 0.0;
      notifyListeners();
    });

    _durationSub = _engine.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _stateSub = _engine.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      // Auto-advance queue on natural completion.
      if (state.processingState == ja.ProcessingState.completed) {
        _isPlaying = false;
        _handleTrackCompletion();
      }
      if (wasPlaying != _isPlaying) notifyListeners();
    });
  }

  Future<void> _handleTrackCompletion() async {
    switch (_repeatMode) {
      case RepeatMode.one:
        if (_currentTrack != null) await playTrack(_currentTrack!);
      case RepeatMode.all:
        await skipNext();
      case RepeatMode.none:
        // Advance to the next playable track when one remains; otherwise stop.
        final order = _orderedQueue();
        final idx = order.indexWhere((t) => t.id == _currentTrack?.id);
        if (idx >= 0 && idx < order.length - 1) {
          final next = _findRelativeTrack(1);
          if (next != null && next.id != _currentTrack?.id) {
            await playTrack(next);
            return;
          }
        }
        notifyListeners();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

/// App-facing name used by UI widgets. Distinct from `just_audio`'s
/// [ja.PlayerState] (engine processing/playing snapshot).
typedef PlayerState = MeloraPlayerState;
