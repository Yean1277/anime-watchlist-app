import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  /// When the current list entrance began. Cards only get an entrance
  /// animation while inside [AppMotion.entranceWindow] of this moment, so
  /// provider rebuilds and scroll-backs after the entrance render statically
  /// instead of replaying the stagger.
  DateTime _entranceStart = DateTime.now();
  bool _wasInitialLoading = false;

  bool get _inEntranceWindow =>
      DateTime.now().difference(_entranceStart) < AppMotion.entranceWindow;

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

  void _selectFilter(WatchStatus? f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _entranceStart = DateTime.now(); // replay the stagger for the new list
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final items = provider.itemsFor(_filter);
    final hero = _filter == null ? _heroItem(provider) : null;
    final subtitle = provider.count == 1
        ? '1 show · keeping count'
        : '${provider.count} shows · keeping count';

    // Start the list entrance when the initial load finishes. Plain field
    // writes — we're already inside build, no setState needed.
    final isInitialLoading = provider.loading && provider.items.isEmpty;
    if (_wasInitialLoading && !isInitialLoading) {
      _entranceStart = DateTime.now();
    }
    _wasInitialLoading = isInitialLoading;

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
              SliverToBoxAdapter(
                child: ClipRect(
                  child: AnimatedSize(
                    duration: reduceMotion ? Duration.zero : AppMotion.base,
                    curve: AppMotion.curve,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: reduceMotion ? Duration.zero : AppMotion.base,
                      switchInCurve: AppMotion.curve,
                      switchOutCurve: AppMotion.curve,
                      child: hero == null
                          // Full width so AnimatedSize only animates height.
                          ? const SizedBox(
                              key: ValueKey('no-hero'),
                              width: double.infinity,
                            )
                          : Padding(
                              key: ValueKey('hero-${hero.id}'),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 4),
                              child: HeroCard(
                                item: hero,
                                onWatched: () => provider.updateProgress(
                                    hero, hero.episodesWatched + 1),
                                onTap: () =>
                                    DetailScreen.open(context, hero.id),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _filterRow(provider)),
              SliverToBoxAdapter(
                child: FuriganaHeader(
                  furigana: _filter == WatchStatus.watching ? 'しちょうちゅう' : null,
                  title: _filter == null ? 'Everything' : _filter!.label,
                  trailing: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : AppMotion.fade,
                    switchInCurve: AppMotion.curve,
                    switchOutCurve: AppMotion.curve,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .4),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '${items.length}',
                      key: ValueKey(items.length),
                      style: AppText.numS,
                    ),
                  ),
                ),
              ),
              if (isInitialLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: reduceMotion
                        ? const CircularProgressIndicator(
                            color: AppColor.accent)
                        : const CircularProgressIndicator(
                                color: AppColor.accent)
                            .animate()
                            .fadeIn(
                                duration: AppMotion.base,
                                curve: AppMotion.curve),
                  ),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: reduceMotion
                      ? _emptyState()
                      : _emptyState()
                          // Keyed per filter: replays when hopping between two
                          // empty filters, not on unrelated provider rebuilds.
                          .animate(
                              key: ValueKey(
                                  'empty-${_filter?.name ?? 'all'}'))
                          .fadeIn(
                              duration: AppMotion.base, curve: AppMotion.curve)
                          .slideY(
                              begin: .02,
                              end: 0,
                              duration: AppMotion.base,
                              curve: AppMotion.curve),
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
                      final card = AnimeCard(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => DetailScreen.open(context, item.id),
                      );
                      // Entrance stagger: first screenful only, and only while
                      // the entrance window is open — later rebuilds (provider
                      // updates, scroll-back) render the bare card.
                      if (reduceMotion ||
                          i >= AppMotion.staggerCap ||
                          !_inEntranceWindow) {
                        return card;
                      }
                      return card
                          .animate(
                            // Filter in the key forces a fresh element — and
                            // thus a replay — on filter change, even for items
                            // present under both filters.
                            key: ValueKey(
                                'entrance-${_filter?.name ?? 'all'}-${item.id}'),
                            delay: AppMotion.staggerStep * i,
                          )
                          .fadeIn(
                              duration: AppMotion.base, curve: AppMotion.curve)
                          .slideY(
                              begin: .06,
                              end: 0,
                              duration: AppMotion.base,
                              curve: AppMotion.curve);
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
            onTap: () => _selectFilter(f),
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
