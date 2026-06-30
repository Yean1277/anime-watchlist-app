import 'package:flutter/material.dart';

import '../models/watchlist_item.dart';
import '../theme.dart';
import 'cover_tile.dart';
import 'star_rating.dart';
import 'status_pill.dart';

/// A list row for one watchlist entry: cover, titles, status pill and either
/// episode progress or a star rating. Tapping opens the detail editor.
class AnimeCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;

  const AnimeCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      color: cardColorFor(context),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CoverTile(
                imageUrl: item.imageUrl,
                title: item.title,
                titleJapanese: item.titleJapanese,
                seed: item.malId,
                size: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.titleJapanese != null &&
                        item.titleJapanese!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.titleJapanese!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusPill(status: item.status, compact: true),
                        const SizedBox(width: 10),
                        Expanded(child: _trailingInfo(context, subtitleColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subtitleColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailingInfo(BuildContext context, Color subtitleColor) {
    if (item.status == WatchStatus.completed && item.score != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: StarRating(score: item.score, size: 15),
      );
    }
    final total = item.episodes != null ? '${item.episodes}' : '?';
    return Text(
      '${item.episodesWatched}/$total ep',
      style: TextStyle(
        fontSize: 13,
        color: subtitleColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
