import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/anime_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/filter_pill.dart';
import '../widgets/furigana_header.dart';
import '../widgets/hero_card.dart';
import '../widgets/pressable.dart';
import '../widgets/screen_header.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

/// Home (一覧): a greeting header, a "continue watching" hero, status filter
/// pills, and the watchlist as ShowCards.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  WatchStatus? _filter; // null = All

  static const List<WatchStatus?> _filters = [
    null,
    WatchStatus.watching,
    WatchStatus.planToWatch,
    WatchStatus.completed,
    WatchStatus.onHold,
    WatchStatus.dropped,
  ];

  String _filterLabel(WatchStatus? s) => s?.shortLabel ?? 'All';

  /// The show to surface in the hero: the first in-progress "watching" title.
  WatchlistItem? _heroItem(WatchlistProvider p) {
    final watching = p.itemsFor(WatchStatus.watching);
    for (final i in watching) {
      if (i.episodes == null || i.episodesWatched < i.episodes!) return i;
    }
    return watching.isNotEmpty ? watching.first : null;
  }

  void _openSearch() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final items = provider.itemsFor(_filter);
    final hero = _filter == null ? _heroItem(provider) : null;
    final subtitle = provider.count == 1
        ? '1 show · keeping count'
        : '${provider.count} shows · keeping count';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: provider.load,
          color: AppColor.accent,
          backgroundColor: AppColor.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  furigana: 'ホーム',
                  title: 'Your shows',
                  subtitle: subtitle,
                  actions: [
                    CircleIconButton(
                        icon: Icons.add_rounded, onTap: _openSearch),
                  ],
                ),
              ),
              if (hero != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: HeroCard(
                      item: hero,
                      onWatched: () => provider.updateProgress(
                          hero, hero.episodesWatched + 1),
                      onTap: () => DetailScreen.open(context, hero.id),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: _filterRow(provider)),
              SliverToBoxAdapter(
                child: FuriganaHeader(
                  furigana: _filter == WatchStatus.watching ? 'しちょうちゅう' : null,
                  title: _filter == null ? 'Everything' : _filter!.label,
                  trailing: Text('${items.length}', style: AppText.numS),
                ),
              ),
              if (provider.loading && provider.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColor.accent),
                  ),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpace.cardGap),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return AnimeCard(
                        item: item,
                        onTap: () => DetailScreen.open(context, item.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterRow(WatchlistProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          return FilterPill(
            label: _filterLabel(f),
            selected: f == _filter,
            count: f == null ? provider.count : provider.countFor(f),
            onTap: () => setState(() => _filter = f),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    final isAll = _filter == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isAll ? 'まだ何も追っていません' : 'なにもありません',
              style: AppText.furigana.copyWith(fontSize: 9)),
          const SizedBox(height: 12),
          Text(
            isAll ? "You're not tracking anything yet." : 'Nothing here yet.',
            textAlign: TextAlign.center,
            style: AppText.titleS,
          ),
          const SizedBox(height: 6),
          Text(
            isAll
                ? 'Find a show and start keeping count.'
                : 'Try a different filter.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
          if (isAll) ...[
            const SizedBox(height: 18),
            Pressable(
              onTap: _openSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.accent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppColor.ctaGlow,
                ),
                child: Text('Add a show',
                    style: AppText.titleS.copyWith(color: AppColor.onAccent)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
