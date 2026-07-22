import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:anime_watchlist_app/models/anime.dart';
import 'package:anime_watchlist_app/providers/watchlist_provider.dart';
import 'package:anime_watchlist_app/screens/search_screen.dart';
import 'package:anime_watchlist_app/services/in_memory_watchlist_repository.dart';
import 'package:anime_watchlist_app/services/jikan_service.dart';

/// A [JikanService] whose search outcome the test controls. `topAiring` is
/// stubbed empty (the idle tab isn't under test); `search` fails while
/// [failNext] is true, otherwise returns [_result].
class _FakeJikanService extends JikanService {
  bool failNext = true;

  static const _result = Anime(malId: 20, title: 'Naruto');

  @override
  Future<List<Anime>> search(String query) async {
    if (failNext) throw const JikanNetworkException();
    return const [_result];
  }

  @override
  Future<List<Anime>> topAiring({int limit = 25}) async => const [];
}

void main() {
  // Regression for issue #16: a stale search error must not survive a later
  // success. Modeling the search area as one sealed _SearchState means a fresh
  // _SearchResults wholly replaces any prior _SearchFailed.
  testWidgets(
    'a successful retry replaces the stale error with fresh results',
    (tester) async {
      final jikan = _FakeJikanService();
      final provider = WatchlistProvider(InMemoryWatchlistRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<WatchlistProvider>.value(
          value: provider,
          child: MaterialApp(home: SearchScreen(jikan: jikan)),
        ),
      );
      await tester.pump(); // let the (empty) top-airing load settle

      // Run a search that fails: the error screen should show.
      await tester.enterText(find.byType(TextField), 'naruto');
      await tester.pump(const Duration(milliseconds: 500)); // fire the debounce
      await tester.pump(); // drain the failed search
      expect(find.text("Couldn't reach MyAnimeList."), findsOneWidget);
      expect(find.text('Naruto'), findsNothing);

      // Retry, now succeeding: fresh results must replace the stale error.
      jikan.failNext = false;
      await tester.tap(find.text('Retry'));
      await tester.pump(); // drain the successful search
      expect(find.text('Naruto'), findsOneWidget);
      expect(find.text("Couldn't reach MyAnimeList."), findsNothing);
    },
  );
}
