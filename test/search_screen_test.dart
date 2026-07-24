import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:anime_watchlist_app/models/anime.dart';
import 'package:anime_watchlist_app/providers/watchlist_provider.dart';
import 'package:anime_watchlist_app/screens/search_screen.dart';
import 'package:anime_watchlist_app/services/in_memory_watchlist_repository.dart';
import 'package:anime_watchlist_app/services/jikan_service.dart';

/// A [JikanService] whose search outcome the test controls. `topAiring` is
/// stubbed empty (the idle tab isn't under test); `search` throws [failWith]
/// while it is non-null, otherwise returns [_result].
class _FakeJikanService extends JikanService {
  /// The failure `search` throws. `null` makes the next search succeed.
  JikanException? failWith = const JikanNetworkException();

  static const _result = Anime(malId: 20, title: 'Naruto');

  @override
  Future<List<Anime>> search(String query) async {
    final failure = failWith;
    if (failure != null) throw failure;
    return const [_result];
  }

  @override
  Future<List<Anime>> topAiring({int limit = 25}) async => const [];
}

/// Pumps a [SearchScreen] wired to [jikan] inside the provider + MaterialApp
/// scaffolding it needs, then lets the (empty) top-airing load settle.
Future<void> _pumpSearch(WidgetTester tester, JikanService jikan) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<WatchlistProvider>.value(
      value: WatchlistProvider(InMemoryWatchlistRepository()),
      child: MaterialApp(home: SearchScreen(jikan: jikan)),
    ),
  );
  await tester.pump(); // let the (empty) top-airing load settle
}

/// Runs a search that fails with [failure] and drains it.
Future<void> _runFailingSearch(
  WidgetTester tester,
  _FakeJikanService jikan,
  JikanException failure,
) async {
  jikan.failWith = failure;
  await tester.enterText(find.byType(TextField), 'naruto');
  await tester.pump(const Duration(milliseconds: 500)); // fire the debounce
  await tester.pump(); // drain the failed search
}

void main() {
  // Regression for issue #16: a stale search error must not survive a later
  // success. Modeling the search area as one sealed _SearchState means a fresh
  // _SearchResults wholly replaces any prior _SearchFailed.
  testWidgets(
    'a successful retry replaces the stale error with fresh results',
    (tester) async {
      final jikan = _FakeJikanService();
      await _pumpSearch(tester, jikan);

      // Run a search that fails: the error screen should show.
      await _runFailingSearch(tester, jikan, const JikanNetworkException());
      expect(find.text("Couldn't reach MyAnimeList."), findsOneWidget);
      expect(find.text('Naruto'), findsNothing);

      // Retry, now succeeding: fresh results must replace the stale error.
      jikan.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pump(); // drain the successful search
      expect(find.text('Naruto'), findsOneWidget);
      expect(find.text("Couldn't reach MyAnimeList."), findsNothing);
    },
  );

  // Issue #20: each JikanException subtype must render its own copy — the UI
  // used to collapse them all into one generic "Something went wrong." message.
  group('each Jikan error type shows its own message', () {
    testWidgets('rate limit → wait-and-retry copy', (tester) async {
      final jikan = _FakeJikanService();
      await _pumpSearch(tester, jikan);
      await _runFailingSearch(tester, jikan, const JikanRateLimitException());

      expect(find.text('Too many requests.'), findsOneWidget);
      expect(find.text("Couldn't reach MyAnimeList."), findsNothing);
      expect(find.text('Something went wrong.'), findsNothing);
    });

    testWidgets('network → check-connection copy', (tester) async {
      final jikan = _FakeJikanService();
      await _pumpSearch(tester, jikan);
      await _runFailingSearch(tester, jikan, const JikanNetworkException());

      expect(find.text("Couldn't reach MyAnimeList."), findsOneWidget);
      expect(find.text('Too many requests.'), findsNothing);
      expect(find.text('Something went wrong.'), findsNothing);
    });

    testWidgets('API/5xx → upstream-server copy, not the generic message',
        (tester) async {
      final jikan = _FakeJikanService();
      await _pumpSearch(tester, jikan);
      await _runFailingSearch(tester, jikan, const JikanApiException(504));

      expect(find.text('MyAnimeList is having trouble.'), findsOneWidget);
      // The whole point of #20: a 504 must NOT read as generic/user error.
      expect(find.text('Something went wrong.'), findsNothing);
      expect(find.text("Couldn't reach MyAnimeList."), findsNothing);
    });
  });
}
