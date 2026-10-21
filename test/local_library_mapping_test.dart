import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/services/local_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalLibraryService.mapSong', () {
    test('maps a song with content URI into a playable local Track', () {
      final track = LocalLibraryService.mapSong({
        'id': 42,
        'uri': 'content://media/external/audio/media/42',
        'title': 'Local Groove',
        'artist': 'Device Artist',
        'album': 'Phone Album',
        'durationMs': 125000,
        'genre': 'Jazz',
        'artworkUri': 'file:///tmp/melora_albumart_9.jpg',
      });

      expect(track, isNotNull);
      expect(track!.id, 'local_42');
      expect(track.source, TrackSource.local);
      expect(track.isPlayable, isTrue);
      expect(track.localUri, 'content://media/external/audio/media/42');
      expect(track.artworkUri, 'file:///tmp/melora_albumart_9.jpg');
      expect(track.durationSeconds, 125);
      expect(track.title, 'Local Groove');
      expect(track.artist, 'Device Artist');
    });

    test('omits blank, content://, and scheme-less artwork URIs', () {
      final blank = LocalLibraryService.mapSong({
        'id': 1,
        'uri': 'file:///tmp/a.mp3',
        'title': 'A',
        'artist': 'B',
        'album': 'C',
        'durationMs': 1000,
        'artworkUri': '   ',
      });
      expect(blank!.artworkUri, isNull);

      final content = LocalLibraryService.mapSong({
        'id': 2,
        'uri': 'file:///tmp/b.mp3',
        'title': 'A',
        'artist': 'B',
        'album': 'C',
        'durationMs': 1000,
        'artworkUri': 'content://media/external/audio/albumart/2',
      });
      expect(content!.artworkUri, isNull);

      final malformed = LocalLibraryService.mapSong({
        'id': 3,
        'uri': 'file:///tmp/c.mp3',
        'title': 'A',
        'artist': 'B',
        'album': 'C',
        'durationMs': 1000,
        'artworkUri': 'not-a-uri',
      });
      expect(malformed!.artworkUri, isNull);
    });

    test('keeps https artwork URIs used by online catalog covers', () {
      final track = LocalLibraryService.mapSong({
        'id': 9,
        'uri': 'file:///tmp/track.mp3',
        'title': 'A',
        'artist': 'B',
        'album': 'C',
        'durationMs': 1000,
        'artworkUri': 'https://img.jamendo.com/covers/1/cover.jpg',
      });
      expect(track!.artworkUri, 'https://img.jamendo.com/covers/1/cover.jpg');
    });

    test('accepts numeric ids delivered as strings', () {
      final track = LocalLibraryService.mapSong({
        'id': '7',
        'uri': 'file:///tmp/track.mp3',
        'title': 'File Only',
        'artist': 'A',
        'album': 'B',
        'durationMs': 60000,
      });

      expect(track, isNotNull);
      expect(track!.localUri, 'file:///tmp/track.mp3');
      expect(track.isPlayable, isTrue);
    });

    test('returns null when URI is missing or blank', () {
      expect(
        LocalLibraryService.mapSong({
          'id': 1,
          'title': 'Broken',
          'durationMs': 1000,
        }),
        isNull,
      );
      expect(
        LocalLibraryService.mapSong({
          'id': 1,
          'uri': '  ',
          'title': 'Broken',
          'durationMs': 1000,
        }),
        isNull,
      );
    });

    test('returns null when id is missing or unparsable', () {
      expect(
        LocalLibraryService.mapSong({
          'uri': 'file:///tmp/x.mp3',
          'title': 'No Id',
          'durationMs': 1000,
        }),
        isNull,
      );
      expect(
        LocalLibraryService.mapSong({
          'id': 'not-a-number',
          'uri': 'file:///tmp/x.mp3',
          'title': 'Bad Id',
          'durationMs': 1000,
        }),
        isNull,
      );
    });

    test('replaces empty and <unknown> metadata with fallbacks', () {
      final track = LocalLibraryService.mapSong({
        'id': 5,
        'uri': 'file:///tmp/x.mp3',
        'title': '',
        'artist': '<unknown>',
        'album': '   ',
        'durationMs': 0,
      });

      expect(track!.title, 'Unknown title');
      expect(track.artist, 'Unknown artist');
      expect(track.album, 'Unknown album');
      expect(track.durationSeconds, 0);
    });
  });

  group('LocalLibraryService.loadSongs channel', () {
    const channelName = 'melora_music/local_library_test_channel';

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    test('maps channel song maps and skips invalid entries', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            call,
          ) async {
            expect(call.method, 'querySongs');
            return [
              {
                'id': 1,
                'uri': 'file:///tmp/ok.mp3',
                'title': 'OK',
                'artist': 'A',
                'album': 'B',
                'durationMs': 3000,
                'artworkUri': 'file:///tmp/art.jpg',
              },
              {'id': 2, 'title': 'No URI'},
              'not-a-map',
            ];
          });

      final service = LocalLibraryService(
        channel: const MethodChannel(channelName),
      );
      final tracks = await service.loadSongs();

      expect(tracks, hasLength(1));
      expect(tracks.single.id, 'local_1');
      expect(tracks.single.artworkUri, 'file:///tmp/art.jpg');
    });

    test('treats a null channel result as an empty library', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(channelName),
            (call) async => null,
          );

      final service = LocalLibraryService(
        channel: const MethodChannel(channelName),
      );
      expect(await service.loadSongs(), isEmpty);
    });

    test(
      'wraps PlatformException as a friendly LocalLibraryException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel(channelName), (
              call,
            ) async {
              throw PlatformException(
                code: 'QUERY_FAILED',
                message: 'native boom',
              );
            });

        final service = LocalLibraryService(
          channel: const MethodChannel(channelName),
        );

        try {
          await service.loadSongs();
          fail('expected LocalLibraryException');
        } on LocalLibraryException catch (e) {
          expect(e.message, contains('Could not read the music library'));
          expect(e.message, isNot(contains('native boom')));
          expect(e.debugDetail, contains('QUERY_FAILED'));
          expect(e.debugDetail, contains('native boom'));
        }
      },
    );

    test(
      'wraps MissingPluginException as a friendly LocalLibraryException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel(channelName), (
              call,
            ) async {
              throw MissingPluginException('No implementation found');
            });

        final service = LocalLibraryService(
          channel: const MethodChannel(channelName),
        );

        try {
          await service.loadSongs();
          fail('expected LocalLibraryException');
        } on LocalLibraryException catch (e) {
          expect(e.message, contains('not available'));
          expect(e.message, isNot(contains('No implementation found')));
          expect(e.debugDetail, contains('No implementation found'));
        }
      },
    );
  });

  group('LocalLibraryException factories', () {
    test('maps PlatformException to friendly UI message with debug detail', () {
      final error = LocalLibraryException.fromPlatform(
        PlatformException(code: 'QUERY_FAILED', message: 'cursor boom'),
      );

      expect(error.message, contains('Could not read the music library'));
      expect(error.message, isNot(contains('cursor boom')));
      expect(error.debugDetail, contains('QUERY_FAILED'));
      expect(error.debugDetail, contains('cursor boom'));
    });

    test(
      'maps MissingPluginException without leaking plugin text to message',
      () {
        final error = LocalLibraryException.fromMissingPlugin(
          MissingPluginException(
            'No implementation found for method querySongs',
          ),
        );

        expect(error.message, contains('not available'));
        expect(error.message, isNot(contains('No implementation found')));
        expect(error.debugDetail, contains('No implementation found'));
      },
    );
  });
}
