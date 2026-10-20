import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _demo(String id) => Track(
  id: id,
  title: 'Demo $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 180,
  paletteIndex: 0,
);

Track _localPlayable(String id) => Track(
  id: id,
  title: 'Local $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 180,
  paletteIndex: 1,
  source: TrackSource.local,
  localUri: 'content://media/external/audio/media/$id',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeloraPlayerState player;

  setUp(() {
    player = MeloraPlayerState();
  });

  tearDown(() {
    player.dispose();
  });

  test('selecting a demo track does not start playback', () async {
    final demo = MockData.tracks.first;
    expect(demo.isPlayable, isFalse);

    final started = await player.playTrack(demo);

    expect(started, isFalse);
    expect(player.isPlaying, isFalse);
    expect(player.currentTrack?.id, demo.id);
    expect(player.userMessage, MeloraPlayerState.demoNotPlayableMessage);
  });

  test('demo selection does not replace a playable current track', () async {
    final playable = _localPlayable('local-1');
    final demo = _demo('demo-1');

    player.debugSetCurrentTrack(playable, isPlaying: true);
    expect(player.isCurrentPlayable, isTrue);

    final started = await player.playTrack(demo);

    expect(started, isFalse);
    // Demo must not replace the playable current track (engine stream may
    // clear isPlaying in tests — identity is the contract under test).
    expect(player.currentTrack?.id, playable.id);
    expect(player.isCurrentPlayable, isTrue);
    expect(player.takeUserMessage(), MeloraPlayerState.demoNotPlayableMessage);
  });

  test('demo can become current when nothing playable is loaded', () async {
    final first = _demo('a');
    final second = _demo('b');

    await player.playTrack(first);
    expect(player.currentTrack?.id, first.id);

    player.takeUserMessage();
    await player.playTrack(second);

    expect(player.currentTrack?.id, second.id);
    expect(player.isPlaying, isFalse);
  });

  test('togglePlayPause on demo sets message and does not play', () async {
    await player.playTrack(_demo('demo'));
    player.takeUserMessage();

    await player.togglePlayPause();

    expect(player.isPlaying, isFalse);
    expect(player.takeUserMessage(), MeloraPlayerState.demoNotPlayableMessage);
  });
}
