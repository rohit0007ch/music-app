import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/online_catalog_repository.dart';
import 'package:melora_music/data/sources/jamendo_api_client.dart';
import 'package:melora_music/data/sources/jamendo_exceptions.dart';
import 'package:melora_music/viewmodels/discover_catalog_state.dart';

class _FakeRepo extends OnlineCatalogRepository {
  _FakeRepo() : super(client: JamendoApiClient(clientId: 'test'));

  List<Track> popular = const [];
  List<Track> searchResults = const [];
  List<Track> tagResults = const [];
  Object? throwOnLoad;
  Duration delay = Duration.zero;
  int searchCalls = 0;

  @override
  Future<List<Track>> popularTracks({int limit = 20, int offset = 0}) async {
    await Future<void>.delayed(delay);
    if (throwOnLoad != null) throw throwOnLoad!;
    return popular;
  }

  @override
  Future<List<Track>> searchTracks({
    String query = '',
    int limit = 20,
    int offset = 0,
  }) async {
    searchCalls++;
    await Future<void>.delayed(delay);
    if (throwOnLoad != null) throw throwOnLoad!;
    if (query.trim().isEmpty) return popular;
    return searchResults;
  }

  @override
  Future<List<Track>> tracksForTags({
    required String tags,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(delay);
    if (throwOnLoad != null) throw throwOnLoad!;
    return tagResults;
  }
}

Track _online(String id, {String title = 'T'}) => Track(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 100,
  paletteIndex: 0,
  source: TrackSource.online,
  streamUrl: 'https://cdn.example.com/$id.mp3',
  licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('needsConfig when Jamendo client id is missing', () async {
    final state = DiscoverCatalogState(
      repository: _FakeRepo(),
      isConfigured: false,
    );
    addTearDown(state.dispose);

    await state.loadPopular();

    expect(state.needsConfig, isTrue);
    expect(state.loading, isFalse);
    expect(state.tracks, isEmpty);
    expect(state.errorMessage, contains('JAMENDO_CLIENT_ID'));
  });

  test('loads popular tracks', () async {
    final repo = _FakeRepo()..popular = [_online('1'), _online('2')];
    final state = DiscoverCatalogState(repository: repo, isConfigured: true);
    addTearDown(state.dispose);

    await state.loadPopular();

    expect(state.loading, isFalse);
    expect(state.tracks.map((t) => t.id), ['1', '2']);
    expect(state.errorMessage, isNull);
  });

  test('search replaces popular results', () async {
    final repo = _FakeRepo()
      ..popular = [_online('p')]
      ..searchResults = [_online('s', title: 'Search Hit')];
    final state = DiscoverCatalogState(repository: repo, isConfigured: true);
    addTearDown(state.dispose);

    await state.loadPopular();
    await state.search('groove');

    expect(state.activeQuery, 'groove');
    expect(state.tracks.single.id, 's');
    expect(repo.searchCalls, greaterThan(0));
  });

  test('empty results clear tracks without error', () async {
    final repo = _FakeRepo()..searchResults = const [];
    final state = DiscoverCatalogState(repository: repo, isConfigured: true);
    addTearDown(state.dispose);

    await state.search('zzzz');

    expect(state.tracks, isEmpty);
    expect(state.errorMessage, isNull);
    expect(state.loading, isFalse);
  });

  test('maps failures to a friendly error message', () async {
    final repo = _FakeRepo()
      ..throwOnLoad = const JamendoHttpException('boom', statusCode: 500);
    final state = DiscoverCatalogState(repository: repo, isConfigured: true);
    addTearDown(state.dispose);

    await state.loadPopular();

    expect(state.tracks, isEmpty);
    expect(state.errorMessage, contains('Could not reach'));
    expect(state.errorMessage, isNot(contains('boom')));
  });

  test('stale responses do not overwrite newer results', () async {
    final repo = _FakeRepo()
      ..popular = [_online('slow')]
      ..searchResults = [_online('fast')]
      ..delay = const Duration(milliseconds: 80);

    final state = DiscoverCatalogState(repository: repo, isConfigured: true);
    addTearDown(state.dispose);

    final popularFuture = state.loadPopular();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repo.delay = Duration.zero;
    await state.search('new');
    await popularFuture;

    expect(state.tracks.map((t) => t.id), ['fast']);
    expect(state.activeQuery, 'new');
  });
}
