import 'package:flutter/material.dart';

import '../models/watchlist_item.dart';
import '../theme.dart';
import 'progress_ring.dart';
import 'pressable.dart';

/// The Home "continue watching" hero — the one large matcha-filled block on the
/// screen (spec §2.3). Ink text on the gradient, a ring on the right, and an
/// ink pill that records the next episode.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.item,
    required this.onWatched,
    required this.onTap,
  });

  final WatchlistItem item;

  /// Records the next episode (parent calls provider.updateProgress).
  final VoidCallback onWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = item.episodes;
    final watched = item.episodesWatched;
    final progress = (total == null || total == 0) ? 0.0 : watched / total;
    final pct = (progress * 100).round();
    final int next =
        (total == null) ? watched + 1 : (watched + 1).clamp(1, total).toInt();
    final int? left =
        total == null ? null : (total - watched).clamp(0, total).toInt();
    final complete = total != null && watched >= total;

    const ink = AppColor.onAccent;
    final inkSoft = ink.withOpacity(0.6);

    return Pressable(
      scale: .99,
      haptic: false,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          gradient: AppColor.accentGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppColor.accentGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('つづきをみる',
                style: AppText.furigana.copyWith(color: ink.withOpacity(0.5))),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleL.copyWith(color: ink),
                      ),
                      if (item.titleJapanese != null &&
                          item.titleJapanese!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.titleJapanese!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(color: inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ProgressRing(
                  progress: progress,
                  size: 62,
                  onAccent: true,
                  semanticsValue:
                      '$watched / ${total ?? '?'} episodes watched',
                  child: Text('$pct%',
                      style: AppText.numM.copyWith(color: ink)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: complete
                      ? _completePill(inkSoft)
                      : _watchPill(context, next),
                ),
                if (left != null) ...[
                  const SizedBox(width: 10),
                  Text('$left left',
                      style: AppText.caption.copyWith(color: inkSoft)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _watchPill(BuildContext context, int next) {
    return Semantics(
      button: true,
      label: 'Record episode $next watched',
      child: Pressable(
        onTap: onWatched,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColor.onAccent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  size: 15, color: Color(0xFFEDF2E6)),
              const SizedBox(width: 6),
              Text('Ep $next watched',
                  style: AppText.titleS.copyWith(
                      color: const Color(0xFFEDF2E6), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completePill(Color inkSoft) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColor.onAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, size: 15, color: AppColor.onAccent),
          const SizedBox(width: 6),
          Text('Finished',
              style: AppText.titleS
                  .copyWith(color: AppColor.onAccent, fontSize: 13)),
        ],
      ),
    );
  }
}
