import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/favorite_record.dart';
import 'package:melora_music/data/models/playlist_record.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/repositories/favorites_repository.dart';
import 'package:melora_music/data/repositories/online_catalog_repository.dart';
import 'package:melora_music/data/repositories/playlists_repository.dart';
import 'package:melora_music/data/sources/jamendo_api_client.dart';
import 'package:melora_music/data/sources/jamendo_exceptions.dart';
import 'package:melora_music/screens/discover/discover_screen.dart';
import 'package:melora_music/shared/widgets/melora_chip.dart';
import 'package:melora_music/theme/app_theme.dart';
import 'package:melora_music/viewmodels/discover_catalog_state.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';
import 'package:melora_music/viewmodels/playlists_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCatalogRepo extends OnlineCatalogRepository {
  _FakeCatalogRepo() : super(client: JamendoApiClient(clientId: 'test'));

  List<Track> popular = const [];
  List<Track> searchResults = const [];
  List<Track> tagResults = const [];
  Object? throwOnLoad;
  int popularCalls = 0;
  int searchCalls = 0;
  int tagCalls = 0;
  String? lastSearchQuery;
  String? lastTags;

  @override
  Future<List<Track>> popularTracks({int limit = 20, int offset = 0}) async {
    popularCalls++;
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
    lastSearchQuery = query;
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
    tagCalls++;
    lastTags = tags;
    if (throwOnLoad != null) throw throwOnLoad!;
    return tagResults;
  }
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<List<FavoriteRecord>> load() async => const [];

  @override
  Future<void> saveAll(List<FavoriteRecord> records) async {}
}

class _FakePlaylistsRepository implements PlaylistsRepository {
  @override
  Future<List<PlaylistRecord>> load() async => const [];

  @override
  Future<void> saveAll(List<PlaylistRecord> playlists) async {}
}

Track _online(String id, {String title = 'Track'}) => Track(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  durationSeconds: 120,
  paletteIndex: 0,
  source: TrackSource.online,
  streamUrl: 'https://cdn.example.com/$id.mp3',
  licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
);

Future<void> _pumpDiscover(
  WidgetTester tester, {
  required DiscoverCatalogState catalog,
  required MeloraPlayerState player,
  required FavoritesState favorites,
  required PlaylistsState playlists,
}) async {
  // Wide enough that mood-card rows do not overflow in layout tests.
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: DiscoverScreen(
          playerState: player,
          favoritesState: favorites,
          playlistsState: playlists,
          catalogState: catalog,
          onTrackTap: (_, {queueContext}) async {},
        ),
      ),
    ),
  );
  // DiscoverScreen.initState calls loadPopular; let it finish.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCatalogRepo repo;
  late DiscoverCatalogState catalog;
  late MeloraPlayerState player;
  late FavoritesState favorites;
  late PlaylistsState playlists;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakeCatalogRepo()..popular = [_online('pop', title: 'Popular Hit')];
    catalog = DiscoverCatalogState(repository: repo, isConfigured: true);
    player = MeloraPlayerState();
    favorites = FavoritesState(repository: _FakeFavoritesRepository());
    playlists = PlaylistsState(repository: _FakePlaylistsRepository());
  });

  tearDown(() {
    catalog.dispose();
    player.dispose();
    favorites.dispose();
    playlists.dispose();
  });

  testWidgets('submitting a query searches and shows results heading', (
    tester,
  ) async {
    repo.searchResults = [_online('s1', title: 'Search Hit')];

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    expect(find.text('Browse by Mood'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
    expect(find.text('Popular Hit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'groove');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.searchCalls, greaterThan(0));
    expect(repo.lastSearchQuery, 'groove');
    expect(catalog.activeQuery, 'groove');
    expect(find.text('Search Hit'), findsOneWidget);
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Browse by Mood'), findsNothing);
    expect(find.text('Trending Now'), findsNothing);
  });

  testWidgets('clearing search restores popular browse chrome', (tester) async {
    repo.searchResults = [_online('s1', title: 'Search Hit')];

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    await tester.enterText(find.byType(TextField), 'groove');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Search Hit'), findsOneWidget);

    final clear = find.byTooltip('Clear search');
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(catalog.activeQuery, isEmpty);
    expect(catalog.isFiltered, isFalse);
    expect(find.text('Popular Hit'), findsOneWidget);
    expect(find.text('Browse by Mood'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
    expect(find.text('Results'), findsNothing);
  });

  testWidgets('empty search results show empty state', (tester) async {
    repo.searchResults = const [];

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Show trending'), findsOneWidget);
  });

  testWidgets('retry after error reloads catalog', (tester) async {
    repo.throwOnLoad = const JamendoHttpException('boom', statusCode: 500);

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    expect(find.text('Couldn’t load music'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    repo.throwOnLoad = null;
    final popularBefore = repo.popularCalls;

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.popularCalls, greaterThan(popularBefore));
    expect(find.text('Popular Hit'), findsOneWidget);
    expect(find.text('Couldn’t load music'), findsNothing);
  });

  testWidgets('missing catalog configuration shows config state', (
    tester,
  ) async {
    catalog.dispose();
    catalog = DiscoverCatalogState(repository: repo, isConfigured: false);

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    expect(find.text('Catalog not configured'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('JAMENDO_CLIENT_ID'), findsOneWidget);
  });

  testWidgets('clear button exposes Clear search tooltip', (tester) async {
    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();

    expect(find.byTooltip('Clear search'), findsOneWidget);
  });

  testWidgets('genre filter hides mood browse and shows tagged heading', (
    tester,
  ) async {
    repo.tagResults = [_online('tag1', title: 'Tagged Hit')];

    await _pumpDiscover(
      tester,
      catalog: catalog,
      player: player,
      favorites: favorites,
      playlists: playlists,
    );

    expect(find.text('Browse by Mood'), findsOneWidget);

    // Genre chips include Electronic (from MockData.genres).
    final electronic = find.text('Electronic');
    await tester.ensureVisible(electronic);
    await tester.tap(electronic);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.tagCalls, greaterThan(0));
    expect(find.text('Tagged Hit'), findsOneWidget);
    expect(find.text('Tagged tracks'), findsOneWidget);
    expect(find.text('Browse by Mood'), findsNothing);
    expect(find.text('Trending Now'), findsNothing);
    // Genre chips remain (horizontal ListView may not keep off-screen chips
    // in the tree after ensureVisible scrolls).
    expect(find.byType(MeloraChip), findsWidgets);
    expect(find.text('Electronic'), findsOneWidget);
  });
}
