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

class _SearchScreenState extends State<SearchScreen> {
  final JikanService _jikan = JikanService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Anime> _results = [];
  bool _loading = false;
  String? _error;

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
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _add(Anime anime) async {
    final provider = context.read<WatchlistProvider>();
    try {
      await provider.add(anime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${anime.title}" to your watchlist')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add: $e')),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _searchField(context)),
                ],
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cardColorFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search MyAnimeList…',
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: scheme.onSurfaceVariant),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {}); // refresh clear button
          _onQueryChanged(value);
        },
        onSubmitted: _search,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _message(
        context,
        icon: Icons.cloud_off_rounded,
        text: 'Search failed. Check your connection\nand try again.',
      );
    }
    if (_results.isEmpty) {
      return _message(
        context,
        icon: Icons.travel_explore_rounded,
        text: _controller.text.trim().isEmpty
            ? 'Search MyAnimeList for shows\nto add to your library.'
            : 'No results for "${_controller.text.trim()}".',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) => _resultRow(context, _results[index]),
    );
  }

  Widget _resultRow(BuildContext context, Anime anime) {
    final scheme = Theme.of(context).colorScheme;
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
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (anime.score != null) ...[
                      const Icon(Icons.star_rounded,
                          color: kStarAmber, size: 14),
                      const SizedBox(width: 3),
                      Text('${anime.score}',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        anime.episodes != null
                            ? '${anime.episodes} episodes'
                            : 'Episodes unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
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

  Widget _message(BuildContext context,
      {required IconData icon, required String text}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
