import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/jikan_service.dart';
import '../theme.dart';
import '../widgets/add_to_list_button.dart';
import '../widgets/cover_tile.dart';
import '../widgets/filter_pill.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';
import 'search_screen.dart';

/// Discover tab: a search entry point, genre filters, a spotlight hero, and the
/// current top-airing ranking from Jikan.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final JikanService _jikan = JikanService();
  List<Anime> _all = [];
  bool _loading = true;
  String? _error;
  String? _genre; // null = All

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _jikan.topAiring();
      if (!mounted) return;
      setState(() {
        _all = results;
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

  List<String> get _topGenres {
    final counts = <String, int>{};
    for (final a in _all) {
      for (final g in a.genres) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(6).toList();
  }

  List<Anime> get _filtered => _genre == null
      ? _all
      : _all.where((a) => a.genres.contains(_genre)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const ScreenHeader(
                title: 'Discover',
                subtitle: "What's everyone bingeing this cour",
              ),
              _searchBar(context),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _errorState(context)
              else ...[
                _genreChips(context),
                if (_filtered.isNotEmpty) _spotlight(context, _filtered.first),
                _sectionLabel(context),
                ..._filtered.asMap().entries.map(
                      (e) => _rankRow(context, e.key + 1, e.value),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: cardColorFor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('Search anime…',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreChips(BuildContext context) {
    final genres = ['All', ..._topGenres];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final g = genres[i];
          final isAll = g == 'All';
          return FilterPill(
            label: g,
            selected: isAll ? _genre == null : _genre == g,
            onTap: () => setState(() => _genre = isAll ? null : g),
          );
        },
      ),
    );
  }

  Widget _spotlight(BuildContext context, Anime anime) {
    final genre = anime.genres.isNotEmpty ? anime.genres.first.toUpperCase() : 'SPOTLIGHT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (anime.imageUrl != null)
                Image.network(anime.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroGradient(anime))
              else
                _heroGradient(anime),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black26, Colors.black87],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('🔥 #1 THIS WEEK',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text('$genre · SPOTLIGHT',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AddToListButton(anime: anime, big: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (anime.score != null) ...[
                          const Icon(Icons.star_rounded,
                              color: kStarAmber, size: 18),
                          const SizedBox(width: 4),
                          Text('${anime.score}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 14),
                        ],
                        if (anime.episodes != null) ...[
                          Text('${anime.episodes} eps',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 14),
                        ],
                        Text(anime.airing ? 'Airing' : 'Finished',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroGradient(Anime anime) {
    final palette = [
      [const Color(0xFF7F53AC), const Color(0xFF201335)],
      [const Color(0xFF11998E), const Color(0xFF0A2A28)],
      [const Color(0xFF8B1E3F), const Color(0xFF2A0E16)],
    ];
    final c = palette[anime.malId.abs() % palette.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c,
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context) {
    return const SectionLabel(text: 'Top this week');
  }

  Widget _rankRow(BuildContext context, int rank, Anime anime) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? kAccent : scheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(width: 8),
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
                        anime.genres.isNotEmpty ? anime.genres.first : '',
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
          AddToListButton(anime: anime),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.cloud_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Could not reach Jikan. Pull to retry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
