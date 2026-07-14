import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import 'cover_tile.dart';
import 'pressable.dart';

/// A watchlist list row (spec §2.2 ShowCard): `52 | 1fr | 34` grid — cover,
/// title + progress bar, and a trailing `＋` that records the next episode
/// (or a disabled `✓` when finished). Tapping the row opens the detail screen.
class AnimeCard extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;

  const AnimeCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = item.episodes;
    final watched = item.episodesWatched;
    final progress = (total == null || total == 0) ? 0.0 : watched / total;
    final complete = total != null && watched >= total;

    return Pressable(
      scale: .99,
      haptic: false,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border.all(color: AppColor.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CoverTile(
              imageUrl: item.imageUrl,
              title: item.title,
              titleJapanese: item.titleJapanese,
              seed: item.malId,
              size: 52,
              height: 66,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleS,
                  ),
                  if (item.titleJapanese != null &&
                      item.titleJapanese!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.titleJapanese!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                  const SizedBox(height: 9),
                  _progress(context, watched, total, progress),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _trailing(context, complete),
          ],
        ),
      ),
    );
  }

  Widget _progress(
      BuildContext context, int watched, int? total, double progress) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$watched', style: AppText.numS),
              TextSpan(
                text: total != null ? '/$total' : '/?',
                style: AppText.caption
                    .copyWith(fontFamily: 'Outfit', fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LayoutBuilder(
              builder: (context, c) {
                final double w =
                    (c.maxWidth * progress.clamp(0.0, 1.0)).toDouble();
                return Stack(
                  children: [
                    Container(height: 4, color: AppColor.track),
                    AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : AppMotion.bar,
                      curve: AppMotion.curve,
                      height: 4,
                      width: w,
                      decoration: BoxDecoration(
                        color: AppColor.accent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _trailing(BuildContext context, bool complete) {
    if (complete) {
      // Finished: non-interactive check, card stays at full brightness.
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.accent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 16, color: AppColor.accent),
          ),
        ),
      );
    }
    final next = item.episodesWatched + 1;
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Semantics(
          button: true,
          label: 'Record episode $next watched',
          child: Pressable(
            scale: .90,
            onTap: () => context
                .read<WatchlistProvider>()
                .updateProgress(item, next),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColor.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  size: 20, color: AppColor.accent),
            ),
          ),
        ),
      ),
    );
  }
}
