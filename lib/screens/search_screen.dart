import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/watchlist_provider.dart';
import '../services/jikan_service.dart';

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
    final provider = context.watch<WatchlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search anime'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search MyAnimeList…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
              onChanged: (value) {
                setState(() {}); // refresh clear button
                _onQueryChanged(value);
              },
              onSubmitted: _search,
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(WatchlistProvider provider) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Search failed: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text('Type a title to search.'),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final anime = _results[index];
        final alreadyAdded = provider.contains(anime.malId);
        return ListTile(
          leading: SizedBox(
            width: 44,
            height: 62,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: anime.imageUrl != null
                  ? Image.network(
                      anime.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade300),
                    )
                  : Container(color: Colors.grey.shade300),
            ),
          ),
          title: Text(anime.title),
          subtitle: Text(
            anime.episodes != null ? '${anime.episodes} episodes' : 'Episodes unknown',
          ),
          trailing: alreadyAdded
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _add(anime),
                ),
        );
      },
    );
  }
}
