import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/watchlist_card.dart';
import 'search_screen.dart';

/// The home screen: a tabbed list of the user's anime, filtered by status.
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  // null = "All"; the rest map 1:1 to WatchStatus.
  static const List<WatchStatus?> _tabs = [
    null,
    WatchStatus.watching,
    WatchStatus.planToWatch,
    WatchStatus.completed,
    WatchStatus.dropped,
  ];

  String _tabLabel(WatchStatus? status) => status?.label ?? 'All';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Anime Watchlist'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _tabs.map((s) => Tab(text: _tabLabel(s))).toList(),
          ),
        ),
        body: Consumer<WatchlistProvider>(
          builder: (context, provider, _) {
            if (provider.loading && provider.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.items.isEmpty) {
              return _ErrorState(
                message: provider.error!,
                onRetry: provider.load,
              );
            }
            return TabBarView(
              children:
                  _tabs.map((status) => _StatusList(status: status)).toList(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add anime'),
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  final WatchStatus? status;
  const _StatusList({required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final items = provider.itemsFor(status);

    if (items.isEmpty) {
      return _EmptyState(status: status);
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return WatchlistCard(
            item: item,
            onStatusChanged: (s) => _guard(
              context,
              () => provider.updateStatus(item, s),
            ),
            onDelete: () => _confirmDelete(context, provider, item),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WatchlistProvider provider,
    WatchlistItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove anime?'),
        content: Text('Remove "${item.title}" from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _guard(context, () => provider.remove(item));
    }
  }

  Future<void> _guard(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final WatchStatus? status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == null ? 'your watchlist' : '"${status!.label}"';
    return ListView(
      // ListView so RefreshIndicator/scroll still works on empty tabs.
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.movie_filter_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Nothing in $label yet.\nTap "Add anime" to search.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Could not load your watchlist.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
