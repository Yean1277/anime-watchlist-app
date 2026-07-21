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
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// Why a search failed, so the UI can suggest the right remedy.
enum _SearchError { rateLimited, network, other }

class _SearchScreenState extends State<SearchScreen> {
  final JikanService _jikan = JikanService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Anime> _results = [];
  bool _loading = false;
  _SearchError? _error;

  /// Monotonic token so a slow, stale response can never overwrite the
  /// results (or cleared state) of a newer query.
  int _searchGeneration = 0;

  /// Idle-state content: the current top-airing ranking.
  List<Anime> _topAiring = [];
  bool _topLoading = true;
  _SearchError? _topError;

  bool get _idle => _controller.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _loadTopAiring();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _jikan.dispose();
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
    } on JikanRateLimitException {
      if (!mounted) return;
      setState(() {
        _topError = _SearchError.rateLimited;
        _topLoading = false;
      });
    } on JikanNetworkException {
      if (!mounted) return;
      setState(() {
        _topError = _SearchError.network;
        _topLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _topError = _SearchError.other;
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
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _jikan.search(query);
      if (!mounted || gen != _searchGeneration) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on JikanRateLimitException {
      _fail(gen, _SearchError.rateLimited);
    } on JikanNetworkException {
      _fail(gen, _SearchError.network);
    } catch (_) {
      _fail(gen, _SearchError.other);
    }
  }

  void _fail(int gen, _SearchError error) {
    if (!mounted || gen != _searchGeneration) return;
    setState(() {
      _error = error;
      _loading = false;
    });
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
          return const FuriganaHeader(
              furigana: 'ほうそうちゅう', title: 'Top airing');
        }
        return _resultRow(_topAiring[index - 1]);
      },
    );
  }

  Widget _buildSearch() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColor.accent));
    }
    if (_error != null) {
      return _errorMessage(_error!,
          onRetry: () => _search(_controller.text));
    }
    if (_results.isEmpty) {
      return _message(
        icon: Icons.travel_explore_rounded,
        furigana: 'みつかりません',
        title: 'No results for "${_controller.text.trim()}"',
        body: 'Try a different word.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 110),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultRow(_results[index]),
    );
  }

  Widget _errorMessage(_SearchError error, {required VoidCallback onRetry}) {
    switch (error) {
      case _SearchError.rateLimited:
        return _message(
          icon: Icons.hourglass_top_rounded,
          furigana: 'ちょっとまって',
          title: 'Too many requests.',
          body: 'MyAnimeList is rate-limiting us — wait a moment, '
              'then try again.',
          onRetry: onRetry,
        );
      case _SearchError.network:
        return _message(
          icon: Icons.cloud_off_rounded,
          furigana: 'つうしんエラー',
          title: "Couldn't reach MyAnimeList.",
          body: 'Check your connection and try again.',
          onRetry: onRetry,
        );
      case _SearchError.other:
        return _message(
          icon: Icons.cloud_off_rounded,
          furigana: 'つうしんエラー',
          title: 'Something went wrong.',
          body: 'Try again in a moment.',
          onRetry: onRetry,
        );
    }
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
