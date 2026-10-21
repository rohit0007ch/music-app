import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melora_music/data/repositories/online_catalog_repository.dart';
import 'package:melora_music/data/sources/jamendo_api_client.dart';
import 'package:melora_music/data/sources/jamendo_exceptions.dart';

void main() {
  group('JamendoApiClient', () {
    test('throws when client id is not configured', () async {
      final client = JamendoApiClient(
        clientId: '',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => client.fetchTracks(),
        throwsA(isA<JamendoConfigException>()),
      );
    });

    test('parses a successful tracks document', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient((request) async {
          expect(request.url.path, endsWith('/tracks/'));
          expect(request.url.queryParameters['client_id'], 'test-client');
          expect(request.url.queryParameters['include'], 'licenses');
          expect(request.url.queryParameters.containsKey('action'), isFalse);
          return http.Response(
            jsonEncode({
              'headers': {'status': 'success', 'code': 0, 'error_message': ''},
              'results': [
                {
                  'id': 10,
                  'name': 'Song',
                  'artist_name': 'Artist',
                  'album_name': 'Album',
                  'duration': 100,
                  'audio': 'https://cdn.example.com/a.mp3',
                  'license_ccurl':
                      'https://creativecommons.org/licenses/by/3.0/',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final results = await client.fetchTracks(search: 'song');
      expect(results, hasLength(1));
      expect(results.first['id'], 10);
    });

    test('throws on non-success HTTP status', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient((_) async => http.Response('nope', 503)),
      );

      expect(
        () => client.fetchTracks(),
        throwsA(
          isA<JamendoHttpException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('throws on malformed JSON', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient((_) async => http.Response('{not-json', 200)),
      );

      expect(() => client.fetchTracks(), throwsA(isA<JamendoParseException>()));
    });

    test('throws when API headers.status is not success', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'headers': {
                'status': 'failed',
                'code': 5,
                'error_message': 'bad request',
              },
              'results': [],
            }),
            200,
          ),
        ),
      );

      expect(
        () => client.fetchTracks(),
        throwsA(
          isA<JamendoApiException>()
              .having((e) => e.message, 'message', 'bad request')
              .having((e) => e.code, 'code', 5),
        ),
      );
    });

    test('throws on timeout', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      expect(() => client.fetchTracks(), throwsA(isA<JamendoHttpException>()));
    });

    test('returns empty list when results is empty', () async {
      final client = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'headers': {'status': 'success', 'code': 0},
              'results': [],
            }),
            200,
          ),
        ),
      );

      expect(await client.fetchTracks(), isEmpty);
    });
  });

  group('OnlineCatalogRepository', () {
    test('filters out tracks without stream URLs', () async {
      final api = JamendoApiClient(
        clientId: 'test-client',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'headers': {'status': 'success', 'code': 0},
              'results': [
                {
                  'id': 1,
                  'name': 'Playable',
                  'artist_name': 'A',
                  'album_name': 'B',
                  'duration': 50,
                  'audio': 'https://cdn.example.com/ok.mp3',
                },
                {
                  'id': 2,
                  'name': 'No Audio',
                  'artist_name': 'A',
                  'album_name': 'B',
                  'duration': 50,
                  'audio': '',
                },
              ],
            }),
            200,
          ),
        ),
      );

      final repo = OnlineCatalogRepository(client: api);
      final tracks = await repo.searchTracks(query: 'x');

      expect(tracks, hasLength(1));
      expect(tracks.single.id, 'online_1');
      expect(tracks.single.isPlayable, isTrue);
      expect(tracks.single.localUri, isNull);
      expect(tracks.single.streamUrl, startsWith('https://'));
    });
  });
}
