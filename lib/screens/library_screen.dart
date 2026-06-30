import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/theme_provider.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/anime_card.dart';
import '../widgets/anime_detail_sheet.dart';
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
    WatchStatus.dropped,
  ];

  String _filterLabel(WatchStatus? s) => s?.shortLabel ?? 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final items = provider.itemsFor(_filter);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context, provider)),
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

  Widget _header(BuildContext context, WatchlistProvider provider) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);
    final subtitle = provider.count == 1
        ? '1 show · keeping count'
        : '${provider.count} shows · keeping count';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Library',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          _circleButton(
            context,
            icon: Icons.add_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _circleButton(
            context,
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () => context.read<ThemeProvider>().toggle(context),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E1E26) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 22, color: scheme.onSurface),
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
          final selected = f == _filter;
          final scheme = Theme.of(context).colorScheme;
          final count =
              f == null ? provider.count : provider.countFor(f);
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.onSurface : cardColorFor(context),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                '${_filterLabel(f)}${count > 0 ? '  $count' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.surface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, int count) {
    final label = _filter == null ? 'EVERYTHING' : _filter!.label.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          Text('$count show${count == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6C5CE7),
              )),
        ],
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
