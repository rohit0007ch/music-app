import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melora_music/data/featured/featured_song.dart';
import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/lyrics_repository.dart';
import 'package:melora_music/screens/home/home_screen.dart';
import 'package:melora_music/services/asset_audio_cache_io.dart';
import 'package:melora_music/services/audio_engine.dart';
import 'package:melora_music/viewmodels/lyrics_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

class _RecordingEngine extends AudioEngine {
  final List<String> playedIds = [];

  @override
  Future<void> play(Track track) async {
    // Validate source without writing temp files or decoding audio.
    AudioEngine.resolveAudioSource(track);
    playedIds.add(track.id);
  }
}

class _ByteBundle extends CachingAssetBundle {
  _ByteBundle(this.bytesByKey);
  final Map<String, List<int>> bytesByKey;

  @override
  Future<ByteData> load(String key) async {
    final bytes = bytesByKey[key];
    if (bytes == null) {
      throw FlutterError('Unable to load asset: "$key"');
    }
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

class _RemoteLyricsStub implements LyricsRepository {
  int fetchCalls = 0;
  final List<String> requestedIds = [];

  @override
  Future<LyricsResult?> fetchForTrack(Track track) async {
    fetchCalls++;
    requestedIds.add(track.id);
    return LyricsResult(
      trackId: track.id,
      sourceName: 'stub',
      lines: const [LyricLine(text: 'remote')],
    );
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeaturedSong metadata', () {
    test('uses a stable unique id and asset source', () {
      final track = FeaturedSong.track;
      expect(track.id, 'featured_dinesh_dalla');
      expect(track.id.startsWith('featured_'), isTrue);
      expect(track.title, 'Dinesh Dalla');
      expect(track.artist, 'Dinesh');
      expect(track.source, TrackSource.asset);
      expect(track.assetPath, 'assets/audio/dinesh.mp3');
      expect(track.artworkUri, 'assets/images/featured/dinesh_dalla.png');
      expect(track.isPlayable, isTrue);
      expect(track.playbackUri, 'assets/audio/dinesh.mp3');
    });
  });

  group('AudioEngine asset resolution', () {
    test('resolvePlaybackUri returns asset scheme for bundled path', () {
      final uri = AudioEngine.resolvePlaybackUri(FeaturedSong.track);
      expect(uri.scheme, 'asset');
      expect(uri.path, 'assets/audio/dinesh.mp3');
    });

    test('resolveAudioSource builds an asset-backed AudioSource', () {
      final source = AudioEngine.resolveAudioSource(FeaturedSong.track);
      expect(source, isA<UriAudioSource>());
      final uri = (source as UriAudioSource).uri;
      expect(uri.scheme, 'asset');
      expect(uri.toString(), contains('assets/audio/dinesh.mp3'));
    });

    test('rejects missing or non-assets paths', () {
      const missingPath = Track(
        id: 'featured_bad',
        title: 'Bad',
        artist: 'A',
        album: 'B',
        durationSeconds: 1,
        paletteIndex: 0,
        source: TrackSource.asset,
        assetPath: '',
      );
      expect(
        () => AudioEngine.resolveAudioSource(missingPath),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AudioEngine.resolveAudioSource(
          FeaturedSong.track.copyWith(assetPath: '/Users/me/song.mp3'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'prepareAudioSource materializes asset tracks to a file URI',
      () async {
        final dir = await Directory.systemTemp.createTemp('melora_asset_prep_');
        addTearDown(() {
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        });
        final bundle = _ByteBundle({
          FeaturedSong.audioAssetPath: List<int>.filled(64, 7),
        });

        // Override cache by materializing first, then building the source via
        // the same path the engine uses for playback.
        final file = await materializeAssetFile(
          trackId: FeaturedSong.id,
          assetPath: FeaturedSong.audioAssetPath,
          bundle: bundle,
          cacheDirectory: dir,
        );
        expect(await file.exists(), isTrue);
        expect(await file.length(), 64);

        final again = await materializeAssetFile(
          trackId: FeaturedSong.id,
          assetPath: FeaturedSong.audioAssetPath,
          bundle: bundle,
          cacheDirectory: dir,
        );
        expect(again.path, file.path);
        expect((await again.readAsBytes()).length, 64);
      },
    );

    test(
      'prepareAudioSource uses a file URI for featured assets on VM',
      () async {
        final source = await AudioEngine.prepareAudioSource(FeaturedSong.track);
        expect(source, isA<UriAudioSource>());
        final uri = (source as UriAudioSource).uri;
        expect(uri.scheme, 'file');
        expect(File(uri.toFilePath()).existsSync(), isTrue);
        expect(File(uri.toFilePath()).lengthSync(), greaterThan(1000));
      },
    );
  });

  group('Featured queue behavior', () {
    test('repeated playTrack does not duplicate the featured track', () async {
      final engine = _RecordingEngine();
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      player.setQueue([]);
      await player.playTrack(FeaturedSong.track);
      await player.playTrack(FeaturedSong.track);
      await player.playTrack(FeaturedSong.track);

      expect(player.queue.where((t) => t.id == FeaturedSong.id).length, 1);
      expect(engine.playedIds, everyElement(FeaturedSong.id));
      expect(engine.playedIds.length, 3);
    });
  });

  group('Featured bundled lyrics', () {
    test('parseBundledLyrics preserves sections and emojis', () {
      const sample = '[INTRO]\n\nLine one 😂\n\n[HOOK]\nFire 🔥\n';
      final lines = FeaturedSong.parseBundledLyrics(sample);
      expect(lines.map((l) => l.text).toList(), [
        '[INTRO]',
        '',
        'Line one 😂',
        '',
        '[HOOK]',
        'Fire 🔥',
      ]);
      expect(lines.every((l) => !l.isTimed), isTrue);
    });

    test(
      'MeloraLyricsRepository serves featured by id without remote',
      () async {
        final remote = _RemoteLyricsStub();
        final repo = MeloraLyricsRepository(remote: remote);
        addTearDown(repo.dispose);

        final result = await repo.fetchForTrack(FeaturedSong.track);
        expect(result, isNotNull);
        expect(result!.trackId, FeaturedSong.id);
        expect(result.sourceName, 'Bundled');
        expect(remote.fetchCalls, 0);

        final texts = result.lines.map((l) => l.text).toList();
        expect(texts, contains('[INTRO]'));
        expect(texts, contains('[VERSE 1]'));
        expect(texts, contains('[HOOK]'));
        expect(texts, contains('[VERSE 2]'));
        expect(texts, contains('[BRIDGE]'));
        expect(texts, contains('[FINAL HOOK]'));
        expect(texts, contains('[OUTRO]'));
        expect(texts.any((t) => t.contains('😂')), isTrue);
        expect(texts.any((t) => t.contains('🔥')), isTrue);
      },
    );

    test('switching tracks clears featured lyrics association', () async {
      final remote = _RemoteLyricsStub();
      final state = LyricsState(
        repository: MeloraLyricsRepository(remote: remote),
      );
      addTearDown(state.dispose);

      await state.loadForTrack(FeaturedSong.track);
      expect(state.status, LyricsStatus.ready);
      expect(state.result?.trackId, FeaturedSong.id);
      expect(state.result?.sourceName, 'Bundled');

      final other = Track(
        id: 'online_other',
        title: 'Other',
        artist: 'Someone',
        album: 'A',
        durationSeconds: 100,
        paletteIndex: 1,
        source: TrackSource.online,
        streamUrl: 'https://cdn.example.com/other.mp3',
      );
      await state.loadForTrack(other);
      expect(state.trackId, other.id);
      expect(state.result?.trackId, other.id);
      expect(state.result?.sourceName, 'stub');
      expect(state.result?.lines.first.text, 'remote');
      expect(remote.requestedIds, ['online_other']);
    });
  });

  group('FeaturedSongCard player state', () {
    testWidgets('play/pause label follows shared player state', (tester) async {
      final engine = _RecordingEngine();
      final player = MeloraPlayerState(engine: engine);
      addTearDown(player.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeaturedSongCard(
              playerState: player,
              onPlay: () => player.playTrack(FeaturedSong.track),
            ),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('FEATURED SONG'), findsOneWidget);
      expect(find.text('Dinesh Dalla'), findsOneWidget);
      expect(find.text('Local Song'), findsOneWidget);
      expect(find.text('Ready to play'), findsOneWidget);

      await player.playTrack(FeaturedSong.track);
      player.debugSetCurrentTrack(FeaturedSong.track, isPlaying: true);
      await tester.pump();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Now playing'), findsOneWidget);

      player.debugSetCurrentTrack(FeaturedSong.track, isPlaying: false);
      await tester.pump();
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('disposes animation controllers without throwing', (
      tester,
    ) async {
      final player = MeloraPlayerState(engine: _RecordingEngine());
      addTearDown(player.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeaturedSongCard(playerState: player, onPlay: () async {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
