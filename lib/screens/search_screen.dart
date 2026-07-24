import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/watchlist_provider.dart';
import '../services/jikan_service.dart';
import '../theme.dart';
import '../widgets/add_to_list_button.dart';
import '../widgets/cover_tile.dart';
import '../widgets/furigana_header.dart';
import '../widgets/screen_header.dart';

/// Search (さがす): a tab that searches the Jikan API and adds results to the
/// watchlist. While the query is empty it shows the current top-airing set so
/// covers appear immediately (FDS v1.1).
class SearchScreen extends StatefulWidget {
  /// [jikan] lets tests inject a fake service. When null the screen owns a
  /// real [JikanService] and disposes it (see [_SearchScreenState.dispose]).
  const SearchScreen({super.key, this.jikan});

  final JikanService? jikan;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// The search tab's mutually exclusive display states. Modeling them as one
/// sealed value (rather than separate `_loading` / `_error` / `_results`
/// fields) makes the invalid "error and results at once" combination
/// unrepresentable, so a stale failure can never mask a newer success —
/// consistent with the sealed-class style in `jikan_service.dart`.
sealed class _SearchState {
  const _SearchState();
}

/// A search is in flight; show a spinner.
class _SearchLoading extends _SearchState {
  const _SearchLoading();
}

/// The most recent search failed; [error] is the typed cause (or null for an
/// unexpected non-Jikan error), so we can suggest the right remedy.
class _SearchFailed extends _SearchState {
  const _SearchFailed(this.error);
  final JikanException? error;
}

/// A search completed. An empty [results] renders the "no results" message; a
/// non-empty one renders the list.
class _SearchResults extends _SearchState {
  const _SearchResults(this.results);
  final List<Anime> results;
}

class _SearchScreenState extends State<SearchScreen> {
  late final JikanService _jikan;
  late final bool _ownsJikan;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  /// The one source of truth for what the search area shows. Starts empty; while
  /// the query is blank `_buildIdle()` renders instead, so this is never seen
  /// blank on first paint.
  _SearchState _state = const _SearchResults([]);

  /// Monotonic token so a slow, stale response can never overwrite the
  /// state of a newer query.
  int _searchGeneration = 0;

  /// Idle-state content: the current top-airing ranking.
  List<Anime> _topAiring = [];
  bool _topLoading = true;
  JikanException? _topError;

  bool get _idle => _controller.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    // Own (and later dispose) the service only when the caller didn't inject
    // one — matching JikanService's own dispose-if-owned contract.
    _ownsJikan = widget.jikan == null;
    _jikan = widget.jikan ?? JikanService();
    _loadTopAiring();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    if (_ownsJikan) _jikan.dispose();
    super.dispose();
  }

  Future<void> _loadTopAiring() async {
    setState(() {
      _topLoading = true;
      _topError = null;
    });
    try {
      final results = await _jikan.topAiring();
      if (!mounted) return;
      setState(() {
        _topAiring = results;
        _topLoading = false;
      });
    } on JikanException catch (e) {
      if (!mounted) return;
      setState(() {
        _topError = e;
        _topLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _topError = null; // unexpected non-Jikan error → generic remedy
        _topLoading = false;
      });
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(query));
  }

  Future<void> _search(String query) async {
    final gen = ++_searchGeneration;
    if (query.trim().isEmpty) {
      setState(() => _state = const _SearchResults([]));
      return;
    }
    setState(() => _state = const _SearchLoading());
    try {
      final results = await _jikan.search(query);
      if (!mounted || gen != _searchGeneration) return;
      // Assigning the whole state wholly replaces any prior _SearchFailed, so a
      // superseded error can't linger behind these fresh results.
      setState(() => _state = _SearchResults(results));
    } on JikanException catch (e) {
      _fail(gen, e);
    } catch (_) {
      _fail(gen, null); // unexpected non-Jikan error → generic remedy
    }
  }

  void _fail(int gen, JikanException? error) {
    if (!mounted || gen != _searchGeneration) return;
    setState(() => _state = _SearchFailed(error));
  }

  Future<void> _add(Anime anime) async {
    final provider = context.read<WatchlistProvider>();
    try {
      await provider.add(anime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColor.surfaceRaised,
          content: Text('Added "${anime.title}"',
              style: AppText.body),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add: $e', style: AppText.body)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              furigana: 'さがす',
              title: 'Search',
              subtitle: 'Find shows on MyAnimeList',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _searchField(),
            ),
            Expanded(child: _idle ? _buildIdle() : _buildSearch()),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TextField(
        controller: _controller,
        style: AppText.body.copyWith(fontSize: 14),
        cursorColor: AppColor.accent,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search MyAnimeList…',
          hintStyle: AppText.body.copyWith(color: AppColor.textMuted),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColor.textMuted),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColor.textMuted),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {}); // refresh clear button + idle/search switch
          _onQueryChanged(value);
        },
        onSubmitted: _search,
      ),
    );
  }

  /// Empty query: the top-airing ranking, so the tab is never a blank page.
  Widget _buildIdle() {
    if (_topLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColor.accent));
    }
    if (_topError != null) {
      return _errorMessage(_topError!, onRetry: _loadTopAiring);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: _topAiring.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const FuriganaHeader(furigana: 'ほうそうちゅう', title: 'Top airing');
        }
        return _resultRow(_topAiring[index - 1]);
      },
    );
  }

  Widget _buildSearch() {
    switch (_state) {
      case _SearchLoading():
        return const Center(
            child: CircularProgressIndicator(color: AppColor.accent));
      case _SearchFailed(:final error):
        return _errorMessage(error, onRetry: () => _search(_controller.text));
      case _SearchResults(:final results):
        if (results.isEmpty) {
          return _message(
            icon: Icons.travel_explore_rounded,
            furigana: 'みつかりません',
            title: 'No results for "${_controller.text.trim()}"',
            body: 'Try a different word.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 110),
          itemCount: results.length,
          itemBuilder: (context, index) => _resultRow(results[index]),
        );
    }
  }

  /// Maps the typed failure to a remedy the user can act on. Switching over the
  /// `sealed` [JikanException] keeps this exhaustive — a new subtype becomes a
  /// compile error here rather than silently reusing the generic fallback. The
  /// `null` arm covers an unexpected non-Jikan error. Raw status codes are kept
  /// out of the copy (they're for logs); nothing here blames the user.
  Widget _errorMessage(JikanException? error, {required VoidCallback onRetry}) {
    return switch (error) {
      JikanRateLimitException() => _message(
          icon: Icons.hourglass_top_rounded,
          furigana: 'ちょっとまって',
          title: 'Too many requests.',
          body: 'MyAnimeList is rate-limiting us — wait a moment, '
              'then try again.',
          onRetry: onRetry,
        ),
      JikanNetworkException() => _message(
          icon: Icons.cloud_off_rounded,
          furigana: 'つうしんエラー',
          title: "Couldn't reach MyAnimeList.",
          body: 'Check your connection and try again.',
          onRetry: onRetry,
        ),
      JikanApiException() => _message(
          icon: Icons.dns_rounded,
          furigana: 'サーバーエラー',
          title: 'MyAnimeList is having trouble.',
          body: 'Their servers hiccuped — try again shortly.',
          onRetry: onRetry,
        ),
      null => _message(
          icon: Icons.error_outline_rounded,
          furigana: 'エラー',
          title: 'Something went wrong.',
          body: 'Try again in a moment.',
          onRetry: onRetry,
        ),
    };
  }

  Widget _resultRow(Anime anime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CoverTile(
            imageUrl: anime.imageUrl,
            title: anime.title,
            titleJapanese: anime.titleJapanese,
            seed: anime.malId,
            size: 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anime.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleS),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (anime.score != null) ...[
                      const Icon(Icons.star_rounded,
                          color: AppColor.accent, size: 13),
                      const SizedBox(width: 3),
                      Text('${anime.score}', style: AppText.caption),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        anime.episodes != null
                            ? '${anime.episodes} episodes'
                            : 'Episodes unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AddToListButton(anime: anime, onTap: () => _add(anime)),
        ],
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String furigana,
    required String title,
    required String body,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColor.textMuted.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(furigana, style: AppText.furigana.copyWith(fontSize: 9)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: AppText.titleS),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: AppText.caption),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text('Retry',
                    style: AppText.titleS.copyWith(color: AppColor.accent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
