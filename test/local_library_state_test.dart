import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/local_library_service.dart';
import 'package:melora_music/viewmodels/local_library_state.dart';

class _FakeLocalLibraryService extends LocalLibraryService {
  _FakeLocalLibraryService()
    : super(channel: const MethodChannel('test/local_library'));

  LocalLibraryPermission status = LocalLibraryPermission.granted;
  List<Track> songs = const [];
  Object? throwOnLoad;
  bool openSettingsCalled = false;

  @override
  Future<LocalLibraryPermission> permissionStatus() async => status;

  @override
  Future<LocalLibraryPermission> ensurePermission() async => status;

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<List<Track>> loadSongs() async {
    if (throwOnLoad != null) throw throwOnLoad!;
    return songs;
  }
}

Track _local(String id) => Track(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 0,
  source: TrackSource.local,
  localId: 1,
  localUri: 'content://media/external/audio/media/1',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('denied permission shows message without songs', () async {
    final service = _FakeLocalLibraryService()
      ..status = LocalLibraryPermission.denied;
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionGranted, isFalse);
    expect(state.permissionPermanentlyDenied, isFalse);
    expect(state.songs, isEmpty);
    expect(state.error, contains('permission'));
    expect(state.hasLoadError, isFalse);
  });

  test('permanently denied exposes Settings path', () async {
    final service = _FakeLocalLibraryService()
      ..status = LocalLibraryPermission.permanentlyDenied;
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionPermanentlyDenied, isTrue);
    expect(state.permissionGranted, isFalse);
    expect(state.error, contains('Settings'));

    await state.openSettings();
    expect(service.openSettingsCalled, isTrue);
  });

  test('loads songs when permission is granted', () async {
    final service = _FakeLocalLibraryService()
      ..songs = [_local('local_1'), _local('local_2')];
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionGranted, isTrue);
    expect(state.songs.map((t) => t.id), ['local_1', 'local_2']);
    expect(state.error, isNull);
    expect(state.hasLoadError, isFalse);
  });

  test('empty library is not treated as an error', () async {
    final service = _FakeLocalLibraryService()..songs = const [];
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionGranted, isTrue);
    expect(state.songs, isEmpty);
    expect(state.error, isNull);
    expect(state.hasLoadError, isFalse);
  });

  test('scan failure keeps permission and exposes retryable error', () async {
    final service = _FakeLocalLibraryService()
      ..throwOnLoad = const LocalLibraryException(
        'Could not read the music library. Please try again.',
        debugDetail: 'QUERY_FAILED: boom',
      );
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionGranted, isTrue);
    expect(state.permissionPermanentlyDenied, isFalse);
    expect(state.songs, isEmpty);
    expect(state.error, 'Could not read the music library. Please try again.');
    expect(state.error, isNot(contains('QUERY_FAILED')));
    expect(state.error, isNot(contains('boom')));
    expect(state.hasLoadError, isTrue);
  });

  test('soft permission check uses status without requesting', () async {
    final service = _FakeLocalLibraryService()
      ..status = LocalLibraryPermission.denied;
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load(requestPermission: false);

    expect(state.permissionGranted, isFalse);
    expect(state.permissionPermanentlyDenied, isFalse);
    expect(state.hasLoadError, isFalse);
    expect(state.error, contains('permission'));
  });

  test('retry after scan failure can recover songs', () async {
    final service = _FakeLocalLibraryService()
      ..throwOnLoad = const LocalLibraryException(
        'Could not read the music library. Please try again.',
        debugDetail: 'QUERY_FAILED',
      );
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();
    expect(state.hasLoadError, isTrue);

    service
      ..throwOnLoad = null
      ..songs = [_local('local_recovered')];
    await state.load(requestPermission: false);

    expect(state.permissionGranted, isTrue);
    expect(state.hasLoadError, isFalse);
    expect(state.error, isNull);
    expect(state.songs.single.id, 'local_recovered');
  });

  test('unexpected errors stay UI-safe and remain retryable', () async {
    final service = _FakeLocalLibraryService()
      ..throwOnLoad = StateError('socket exploded');
    final state = LocalLibraryState(service: service);
    addTearDown(state.dispose);

    await state.load();

    expect(state.permissionGranted, isTrue);
    expect(state.hasLoadError, isTrue);
    expect(state.error, 'Could not load local songs. Please try again.');
    expect(state.error, isNot(contains('socket exploded')));
  });
}
