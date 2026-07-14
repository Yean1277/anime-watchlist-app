import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/cover_tile.dart';
import '../widgets/episode_grid.dart';
import '../widgets/filter_pill.dart';
import '../widgets/furigana_header.dart';
import '../widgets/progress_ring.dart';
import '../widgets/star_rating.dart';

/// Full-page 詳細 (spec §3 / detail): a cover hero, a progress-ring card, the
/// episode grid, status + rating editors, and a sticky matcha CTA that records
/// the next episode. Replaces the old bottom sheet.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.itemId});

  final String itemId;

  static Future<void> open(BuildContext context, String itemId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(itemId: itemId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    WatchlistItem? item;
    for (final i in provider.items) {
      if (i.id == itemId) {
        item = i;
        break;
      }
    }
    if (item == null) {
      // Removed while open — just pop back.
      return const Scaffold(body: SizedBox.shrink());
    }
    final it = item;
    final total = it.episodes;
    final watched = it.episodesWatched;
    final complete = total != null && watched >= total;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Hero(item: it)),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: _body(context, it),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),
          _RecordCta(item: it, complete: complete),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WatchlistItem it) {
    final total = it.episodes;
    final watched = it.episodesWatched;
    final progress = (total == null || total == 0) ? 0.0 : watched / total;
    final pct = (progress * 100).round();
    final int? left =
        total == null ? null : (total - watched).clamp(0, total).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(it.title,
            style: AppText.display,
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        if (it.titleJapanese != null && it.titleJapanese!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(it.titleJapanese!, style: AppText.caption),
        ],
        const SizedBox(height: 12),
        _meta(it),
        const SizedBox(height: 14),
        _progressCard(context, it, progress, pct, left),
        FuriganaHeader(
          title: 'Episodes',
          furigana: 'わすう',
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 12),
          trailing: total == null
              ? null
              : Text('tap to fill', style: AppText.label),
        ),
        if (total == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Episode count unknown.', style: AppText.caption),
          )
        else
          EpisodeGrid(
            total: total,
            watched: watched,
            onSet: (n) =>
                context.read<WatchlistProvider>().updateProgress(it, n),
          ),
        const FuriganaHeader(
          title: 'Status',
          furigana: 'じょうたい',
          padding: EdgeInsets.fromLTRB(2, 22, 2, 12),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WatchStatus.values.map((s) {
            return FilterPill(
              label: s.label,
              selected: s == it.status,
              onTap: () =>
                  context.read<WatchlistProvider>().updateStatus(it, s),
            );
          }).toList(),
        ),
        const FuriganaHeader(
          title: 'Your rating',
          furigana: 'ひょうか',
          padding: EdgeInsets.fromLTRB(2, 22, 2, 12),
        ),
        StarRating(
          score: it.score,
          size: 30,
          onRate: (v) => context.read<WatchlistProvider>().updateScore(it, v),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await context.read<WatchlistProvider>().remove(it);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD19A9E),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Remove from list', style: AppText.body),
          ),
        ),
      ],
    );
  }

  Widget _meta(WatchlistItem it) {
    final chips = <String>[
      if (it.episodes != null) '${it.episodes} eps',
      it.status.label,
      if (it.score != null) '★ ${it.score}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.border),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(c, style: AppText.label),
              ))
          .toList(),
    );
  }

  Widget _progressCard(BuildContext context, WatchlistItem it, double progress,
      int pct, int? left) {
    final total = it.episodes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 82,
            semanticsValue:
                '${it.episodesWatched} / ${total ?? '?'} episodes watched',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${it.episodesWatched}', style: AppText.numXL),
                Text(total != null ? '/ $total' : '/ ?',
                    style: AppText.caption.copyWith(fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('しんちょく', style: AppText.furigana),
                const SizedBox(height: 5),
                Text('Progress', style: AppText.titleS),
                const SizedBox(height: 6),
                Text(
                  left == null
                      ? '$pct% watched.'
                      : left == 0
                          ? 'All caught up. Nicely done.'
                          : '$left episode${left == 1 ? '' : 's'} to go · $pct%',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-bleed cover hero with back/like buttons and a scrim into the bg.
class _Hero extends StatelessWidget {
  const _Hero({required this.item});
  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 212,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cover(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x2615171A), AppColor.bg],
                stops: [0.30, 1.0],
              ),
            ),
          ),
          Positioned(
            top: topPad + 8,
            left: 8,
            child: CircleIconButton(
              icon: Icons.arrow_back_rounded,
              scrim: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: topPad + 8,
            right: 8,
            child: CircleIconButton(
              icon: Icons.favorite_rounded,
              scrim: true,
              iconColor: AppColor.secondary,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _cover() {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    if (hasImage) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => CoverTile(
        imageUrl: null,
        title: item.title,
        titleJapanese: item.titleJapanese,
        seed: item.malId,
        size: 212,
        radius: 0,
      );
}

/// Sticky footer button: records the next episode with a ripple + rising
/// "記録しました" float. Reduce-motion skips the flourishes.
class _RecordCta extends StatefulWidget {
  const _RecordCta({required this.item, required this.complete});
  final WatchlistItem item;
  final bool complete;

  @override
  State<_RecordCta> createState() => _RecordCtaState();
}

class _RecordCtaState extends State<_RecordCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.float,
  );
  int _recorded = 0;
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _record() {
    final it = widget.item;
    final total = it.episodes;
    final next = it.episodesWatched + 1;
    if (total != null && it.episodesWatched >= total) return;

    HapticFeedback.selectionClick();
    context.read<WatchlistProvider>().updateProgress(it, next);

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      setState(() => _recorded = next);
      _c.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.complete) {
      return _footerWrap(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text('Finished — every episode watched',
              style: AppText.titleS.copyWith(color: AppColor.accent)),
        ),
      );
    }

    final next = widget.item.episodesWatched + 1;

    return _footerWrap(
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Rising float text.
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              if (_c.isDismissed) return const SizedBox.shrink();
              final t = _c.value;
              final opacity = t < 0.3 ? (t / 0.3) : (1 - (t - 0.3) / 0.7);
              return Positioned(
                top: -6 - t * 20,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0).toDouble(),
                  child: Text('Ep $_recorded recorded · 記録しました',
                      style: AppText.caption.copyWith(
                          color: AppColor.accent,
                          fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
          GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: _record,
            child: AnimatedScale(
              scale: _down ? 0.97 : 1,
              duration: AppMotion.press,
              curve: AppMotion.curve,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.accent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppColor.ctaGlow,
                ),
                child: Text('Ep $next watched',
                    style: AppText.titleS.copyWith(
                        color: AppColor.onAccent,
                        fontSize: 14,
                        letterSpacing: .3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerWrap(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Semantics(button: true, child: child),
        ),
      ),
    );
  }
}
