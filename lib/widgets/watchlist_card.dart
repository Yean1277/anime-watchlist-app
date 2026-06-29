import 'package:flutter/material.dart';

import '../models/watchlist_item.dart';
import 'status_chip.dart';

/// A list row showing one watchlist entry, with an inline status selector
/// and a delete action.
class WatchlistCard extends StatelessWidget {
  final WatchlistItem item;
  final ValueChanged<WatchStatus> onStatusChanged;
  final VoidCallback onDelete;

  const WatchlistCard({
    super.key,
    required this.item,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.episodes != null
                        ? '${item.episodes} episodes'
                        : 'Episodes unknown',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusChip(status: item.status),
                      const Spacer(),
                      _StatusMenu(
                        current: item.status,
                        onSelected: onStatusChanged,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? imageUrl;
  const _Cover({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 60,
        height: 85,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
              )
            : const _CoverPlaceholder(),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  final WatchStatus current;
  final ValueChanged<WatchStatus> onSelected;

  const _StatusMenu({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WatchStatus>(
      icon: const Icon(Icons.edit_outlined),
      tooltip: 'Change status',
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => WatchStatus.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
    );
  }
}
