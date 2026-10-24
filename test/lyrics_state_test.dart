import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/lyrics_repository.dart';
import 'package:melora_music/viewmodels/lyrics_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _track({
  String id = 'online_1',
  String title = 'Song',
  String artist = 'Artist',
}) {
  return Track(
    id: id,
    title: title,
    artist: artist,
    album: 'Album',
    durationSeconds: 180,
    paletteIndex: 0,
    source: TrackSource.online,
    streamUrl: 'https://cdn.example.com/$id.mp3',
  );
}

class _FakeLyricsRepository implements LyricsRepository {
  LyricsResult? result;
  Object? throwOnFetch;
  Duration delay = Duration.zero;
  int fetchCalls = 0;
  final List<String> requestedIds = [];

  @override
  Future<LyricsResult?> fetchForTrack(Track track) async {
    fetchCalls++;
    requestedIds.add(track.id);
    await Future<void>.delayed(delay);
    if (throwOnFetch != null) throw throwOnFetch!;
    return result;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LyricsResult.activeLineIndex', () {
    test('selects the latest timed line at or before position', () {
      final result = LyricsResult(
        trackId: '1',
        sourceName: 'test',
        lines: const [
          LyricLine(text: 'a', start: Duration(seconds: 0)),
          LyricLine(text: 'b', start: Duration(seconds: 5)),
          LyricLine(text: 'c', start: Duration(seconds: 10)),
        ],
      );
      expect(result.activeLineIndex(const Duration(seconds: 0)), 0);
      expect(result.activeLineIndex(const Duration(seconds: 6)), 1);
      expect(result.activeLineIndex(const Duration(seconds: 10)), 2);
    });
  });

  group('LrclibLyricsRepository parsers', () {
    test('parseSyncedLyrics extracts timed lines', () {
      const raw = '[00:12.00]Hello\n[00:15.50]World\n';
      final lines = LrclibLyricsRepository.parseSyncedLyrics(raw);
      expect(lines.map((l) => l.text), ['Hello', 'World']);
      expect(lines.first.start, const Duration(seconds: 12));
      expect(lines.last.start, const Duration(seconds: 15, milliseconds: 500));
    });

    test('parsePlainLyrics drops blank lines', () {
      final lines = LrclibLyricsRepository.parsePlainLyrics('A\n\nB\n');
      expect(lines.map((l) => l.text), ['A', 'B']);
      expect(lines.every((l) => !l.isTimed), isTrue);
    });
  });

  group('LyricsState', () {
    test('loading → ready on success', () async {
      final repo = _FakeLyricsRepository()
        ..result = LyricsResult(
          trackId: 'online_1',
          sourceName: 'fake',
          lines: const [LyricLine(text: 'Line')],
        );
      final state = LyricsState(repository: repo);
      addTearDown(state.dispose);

      final future = state.loadForTrack(_track());
      expect(state.status, LyricsStatus.loading);
      await future;

      expect(state.status, LyricsStatus.ready);
      expect(state.result!.lines.single.text, 'Line');
    });

    test('unavailable when repository returns null', () async {
      final repo = _FakeLyricsRepository()..result = null;
      final state = LyricsState(repository: repo);
      addTearDown(state.dispose);

      await state.loadForTrack(_track());
      expect(state.status, LyricsStatus.unavailable);
    });

    test('error state surfaces provider message and retry works', () async {
      final repo = _FakeLyricsRepository()
        ..throwOnFetch = const LyricsProviderException('network down');
      final state = LyricsState(repository: repo);
      addTearDown(state.dispose);

      await state.loadForTrack(_track());
      expect(state.status, LyricsStatus.error);
      expect(state.errorMessage, 'network down');

      repo.throwOnFetch = null;
      repo.result = LyricsResult(
        trackId: 'online_1',
        sourceName: 'fake',
        lines: const [LyricLine(text: 'Ok')],
      );
      await state.retry(_track());
      expect(state.status, LyricsStatus.ready);
      expect(repo.fetchCalls, 2);
    });

    test('missing metadata yields unavailable without fetching', () async {
      final repo = _FakeLyricsRepository();
      final state = LyricsState(repository: repo);
      addTearDown(state.dispose);

      await state.loadForTrack(_track(title: ' ', artist: 'Artist'));
      expect(state.status, LyricsStatus.unavailable);
      expect(repo.fetchCalls, 0);
    });

    test('stale response cannot replace lyrics for newer track', () async {
      final repo = _FakeLyricsRepository()
        ..delay = const Duration(milliseconds: 40);
      final state = LyricsState(repository: repo);
      addTearDown(state.dispose);

      repo.result = LyricsResult(
        trackId: 'online_old',
        sourceName: 'fake',
        lines: const [LyricLine(text: 'Old')],
      );
      final slow = state.loadForTrack(_track(id: 'online_old', title: 'Old'));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      repo.delay = Duration.zero;
      repo.result = LyricsResult(
        trackId: 'online_new',
        sourceName: 'fake',
        lines: const [LyricLine(text: 'New')],
      );
      await state.loadForTrack(_track(id: 'online_new', title: 'New'));
      await slow;

      expect(state.trackId, 'online_new');
      expect(state.result!.lines.single.text, 'New');
    });

    test('lyrics failure does not affect playback state', () async {
      final repo = _FakeLyricsRepository()
        ..throwOnFetch = const LyricsProviderException('boom');
      final lyrics = LyricsState(repository: repo);
      addTearDown(lyrics.dispose);

      final player = MeloraPlayerState();
      addTearDown(player.dispose);
      final track = _track();
      player.debugSetCurrentTrack(track, isPlaying: true);
      player.setQueue([track]);
      final queueBefore = player.queue.map((t) => t.id).toList();

      await lyrics.loadForTrack(track);

      expect(lyrics.status, LyricsStatus.error);
      // Lyrics must not clear current track or mutate the queue.
      expect(player.currentTrack?.id, track.id);
      expect(player.queue.map((t) => t.id), queueBefore);
      expect(player.error, isNull);
    });
  });
}
