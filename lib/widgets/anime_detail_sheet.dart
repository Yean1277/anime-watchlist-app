import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import 'cover_tile.dart';
import 'star_rating.dart';

/// Bottom sheet to edit one watchlist entry: status, episode progress, rating,
/// and removal. Reads the live item from [WatchlistProvider] so controls stay
/// in sync after each change.
class AnimeDetailSheet extends StatelessWidget {
  final String itemId;

  const AnimeDetailSheet({super.key, required this.itemId});

  static Future<void> show(BuildContext context, String itemId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AnimeDetailSheet(itemId: itemId),
    );
  }

  WatchlistItem? _find(WatchlistProvider provider) {
    for (final i in provider.items) {
      if (i.id == itemId) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final item = _find(provider);
    if (item == null) {
      return const SizedBox(height: 1);
    }
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CoverTile(
                  imageUrl: item.imageUrl,
                  title: item.title,
                  titleJapanese: item.titleJapanese,
                  seed: item.malId,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.titleJapanese != null &&
                          item.titleJapanese!.isNotEmpty)
                        Text(item.titleJapanese!,
                            style: TextStyle(color: subtitleColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _label('Status'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WatchStatus.values.map((s) {
                final selected = s == item.status;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : s.color,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: s.color.withOpacity(0.5)),
                  backgroundColor: s.color.withOpacity(0.10),
                  selectedColor: s.color,
                  onSelected: (_) =>
                      context.read<WatchlistProvider>().updateStatus(item, s),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _label('Episodes watched'),
            const SizedBox(height: 8),
            _EpisodeStepper(item: item),
            const SizedBox(height: 22),
            _label('Your rating'),
            const SizedBox(height: 8),
            StarRating(
              score: item.score,
              size: 32,
              onRate: (value) =>
                  context.read<WatchlistProvider>().updateScore(item, value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<WatchlistProvider>().remove(item);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove from list'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF9AA0A6),
        ),
      );
}

class _EpisodeStepper extends StatelessWidget {
  final WatchlistItem item;
  const _EpisodeStepper({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WatchlistProvider>();
    final total = item.episodes;
    final totalText = total != null ? '$total' : '?';

    return Row(
      children: [
        _RoundButton(
          icon: Icons.remove_rounded,
          onTap: item.episodesWatched > 0
              ? () => provider.updateProgress(item, item.episodesWatched - 1)
              : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${item.episodesWatched} / $totalText',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add_rounded,
          onTap: (total == null || item.episodesWatched < total)
              ? () => provider.updateProgress(item, item.episodesWatched + 1)
              : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface.withOpacity(0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: onTap == null
                ? scheme.onSurfaceVariant.withOpacity(0.4)
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
