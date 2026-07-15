import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../services/jikan_service.dart';
import '../theme.dart';
import '../widgets/add_to_list_button.dart';
import '../widgets/cover_tile.dart';
import '../widgets/filter_pill.dart';
import '../widgets/furigana_header.dart';
import '../widgets/screen_header.dart';
import 'search_screen.dart';

/// Discover (探す): a search entry, genre filters, a spotlight hero, and the
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
    } on JikanRateLimitException {
      if (!mounted) return;
      setState(() {
        _error = 'Jikan is rate-limiting requests. Pull to retry in a moment.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't reach Jikan. Pull to retry.";
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
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColor.accent,
          backgroundColor: AppColor.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              const ScreenHeader(
                furigana: 'さがす',
                title: 'Discover',
                subtitle: "What everyone's bingeing this cour",
              ),
              _searchBar(context),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColor.accent)),
                )
              else if (_error != null)
                _errorState(context)
              else ...[
                _genreChips(),
                if (_filtered.isNotEmpty) _spotlight(context, _filtered.first),
                const FuriganaHeader(furigana: 'こんしゅう', title: 'Top this week'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColor.surface,
            border: Border.all(color: AppColor.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColor.textMuted),
              const SizedBox(width: 12),
              Text('Search anime…', style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreChips() {
    final genres = ['All', ..._topGenres];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
    final genre =
        anime.genres.isNotEmpty ? anime.genres.first.toUpperCase() : 'SPOTLIGHT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (anime.imageUrl != null)
                Image.network(anime.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroGradient(anime))
              else
                _heroGradient(anime),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x3315171A), Color(0xF215171A)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColor.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('#1 THIS WEEK',
                          style: AppText.label
                              .copyWith(color: AppColor.onAccent)),
                    ),
                    const Spacer(),
                    Text('$genre · SPOTLIGHT', style: AppText.label),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display.copyWith(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AddToListButton(anime: anime, big: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (anime.score != null) ...[
                          const Icon(Icons.star_rounded,
                              color: AppColor.accent, size: 16),
                          const SizedBox(width: 4),
                          Text('${anime.score}', style: AppText.numS),
                          const SizedBox(width: 14),
                        ],
                        if (anime.episodes != null) ...[
                          Text('${anime.episodes} eps', style: AppText.caption),
                          const SizedBox(width: 14),
                        ],
                        Text(anime.airing ? 'Airing' : 'Finished',
                            style: AppText.caption),
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
      [const Color(0xFF3E5B7E), const Color(0xFF20303F)],
      [const Color(0xFF6E8F73), const Color(0xFF26332B)],
      [const Color(0xFF8B6A72), const Color(0xFF2A1E22)],
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

  Widget _rankRow(BuildContext context, int rank, Anime anime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('$rank',
                style: AppText.numM.copyWith(
                  color: rank <= 3 ? AppColor.accent : AppColor.textMuted,
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
                        anime.genres.isNotEmpty ? anime.genres.first : '',
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
          const Icon(Icons.cloud_off_rounded,
              size: 52, color: AppColor.textMuted),
          const SizedBox(height: 16),
          Text(_error ?? "Couldn't reach Jikan. Pull to retry.",
              textAlign: TextAlign.center, style: AppText.caption),
        ],
      ),
    );
  }
}
