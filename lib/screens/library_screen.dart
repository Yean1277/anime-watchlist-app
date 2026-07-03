import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/anime_card.dart';
import '../widgets/anime_detail_sheet.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/filter_pill.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';
import 'search_screen.dart';

/// The redesigned home tab: a bold header, scrollable status filter pills, and
/// a list of watchlist cards.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // null = "All".
  WatchStatus? _filter;

  static const List<WatchStatus?> _filters = [
    null,
    WatchStatus.watching,
    WatchStatus.planToWatch,
    WatchStatus.completed,
    WatchStatus.onHold,
    WatchStatus.dropped,
  ];

  String _filterLabel(WatchStatus? s) => s?.shortLabel ?? 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final items = provider.itemsFor(_filter);
    final subtitle = provider.count == 1
        ? '1 show · keeping count'
        : '${provider.count} shows · keeping count';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Library',
                  subtitle: subtitle,
                  actions: [
                    CircleIconButton(
                      icon: Icons.add_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _filterRow(context)),
              SliverToBoxAdapter(child: _sectionHeader(context, items.length)),
              if (provider.loading && provider.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return AnimeCard(
                        item: item,
                        onTap: () => AnimeDetailSheet.show(context, item.id),
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

  Widget _filterRow(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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

  Widget _sectionHeader(BuildContext context, int count) {
    final label = _filter == null ? 'Everything' : _filter!.label;
    return SectionLabel(
      text: label,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      trailing: Text(
        '$count show${count == 1 ? '' : 's'}',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: kAccent, letterSpacing: 0),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined,
              size: 64, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _filter == null
                ? 'Your library is empty.\nTap + to find anime to track.'
                : 'Nothing here yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
