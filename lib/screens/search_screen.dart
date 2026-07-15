import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/watchlist_provider.dart';
import '../services/jikan_service.dart';
import '../theme.dart';
import '../widgets/add_to_list_button.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/cover_tile.dart';

/// Search the Jikan API and add results to the watchlist.
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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _searchField()),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
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
        autofocus: true,
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
          setState(() {}); // refresh clear button
          _onQueryChanged(value);
        },
        onSubmitted: _search,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.accent));
    }
    switch (_error) {
      case _SearchError.rateLimited:
        return _message(
          icon: Icons.hourglass_top_rounded,
          furigana: 'ちょっとまって',
          title: 'Too many requests.',
          body: 'MyAnimeList is rate-limiting us — wait a moment, '
              'then keep typing.',
        );
      case _SearchError.network:
        return _message(
          icon: Icons.cloud_off_rounded,
          furigana: 'つうしんエラー',
          title: "Search failed.",
          body: 'Check your connection and try again.',
        );
      case _SearchError.other:
        return _message(
          icon: Icons.cloud_off_rounded,
          furigana: 'つうしんエラー',
          title: 'Something went wrong.',
          body: 'Try again in a moment.',
        );
      case null:
        break;
    }
    if (_results.isEmpty) {
      final q = _controller.text.trim();
      return _message(
        icon: Icons.travel_explore_rounded,
        furigana: q.isEmpty ? 'さがす' : 'みつかりません',
        title: q.isEmpty ? 'Find shows to track' : 'No results for "$q"',
        body: q.isEmpty
            ? 'Search MyAnimeList and add to your library.'
            : 'Try a different word.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultRow(_results[index]),
    );
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
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
          ],
        ),
      ),
    );
  }
}
