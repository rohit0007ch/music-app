import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/viewmodels/player_state.dart';

Track _demo(String id) => Track(
  id: id,
  title: 'Demo $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
  paletteIndex: 0,
);

Track _local(String id) => Track(
  id: id,
  title: 'Local $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
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

  test('setQueue replaces the playback queue', () {
    final tracks = [_local('1'), _local('2')];
    player.setQueue(tracks);
    expect(player.queue.map((t) => t.id), ['1', '2']);
  });

  test('relative skip from playable track peeks past demo entries', () {
    final playableA = _local('a');
    final demo = _demo('demo');
    final playableB = _local('b');

    player.setQueue([playableA, demo, playableB]);
    player.debugSetCurrentTrack(playableA, isPlaying: true);
    // Enable wrap so previous from the first track can reach the last.
    player.cycleRepeat(); // none -> all

    expect(player.debugPeekRelative(1)?.id, playableB.id);
    expect(player.debugPeekRelative(-1)?.id, playableB.id);
  });

  test('toggleShuffle enables shuffle flag', () {
    expect(player.isShuffle, isFalse);
    player.toggleShuffle();
    expect(player.isShuffle, isTrue);
    player.toggleShuffle();
    expect(player.isShuffle, isFalse);
  });

  test('cycleRepeat walks none → all → one → none', () {
    expect(player.repeatMode, RepeatMode.none);
    player.cycleRepeat();
    expect(player.repeatMode, RepeatMode.all);
    player.cycleRepeat();
    expect(player.repeatMode, RepeatMode.one);
    player.cycleRepeat();
    expect(player.repeatMode, RepeatMode.none);
  });
}
