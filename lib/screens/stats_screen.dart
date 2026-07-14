import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/furigana_header.dart';
import '../widgets/progress_ring.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_block.dart';
import '../widgets/week_chart.dart';

/// Stats (記録): totals, this-season completion ring, a weekly chart, and a
/// per-status breakdown — computed live from the watchlist.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const int _minutesPerEpisode = 24;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final episodes = provider.totalEpisodesWatched;
    final hours = (episodes * _minutesPerEpisode) ~/ 60;

    final tracked = provider.count;
    final completed = provider.countFor(WatchStatus.completed);
    final rate = tracked == 0 ? 0.0 : completed / tracked;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            const ScreenHeader(
              furigana: 'きろく',
              title: 'Stats',
              subtitle: 'Your quiet late-night tally',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StatBlock(entries: [
                StatEntry('$episodes', 'Episodes'),
                StatEntry('$tracked', 'Shows'),
                StatEntry('${hours}h', 'Hours'),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SeasonCard(
                  rate: rate, completed: completed, tracked: tracked),
            ),
            const FuriganaHeader(furigana: 'しゅうかん', title: 'This week'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  border: Border.all(color: AppColor.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                // TODO: the app tracks no per-day watch history yet — this is a
                // placeholder distribution. Wire real data once events exist.
                child: const WeekChart(
                  values: [.34, .20, .52, .28, .88, .70, .46],
                ),
              ),
            ),
            const FuriganaHeader(furigana: 'じょうたい', title: 'By status'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _StatusBreakdown(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one matcha-filled block on this screen: season completion ring.
class _SeasonCard extends StatelessWidget {
  const _SeasonCard(
      {required this.rate, required this.completed, required this.tracked});

  final double rate;
  final int completed;
  final int tracked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColor.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColor.accentGlow,
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: rate,
            size: 72,
            onAccent: true,
            child: Text('${(rate * 100).round()}%',
                style: AppText.numM.copyWith(color: AppColor.onAccent)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('かんそうりつ',
                    style:
                        AppText.furigana.copyWith(color: const Color(0x80171B16))),
                const SizedBox(height: 5),
                Text('Completion rate',
                    style: AppText.titleS.copyWith(color: AppColor.onAccent)),
                const SizedBox(height: 6),
                Text(
                  tracked == 0
                      ? 'Add a few shows to start tracking.'
                      : '$completed of $tracked shows finished.',
                  style: AppText.caption
                      .copyWith(color: AppColor.onAccent.withOpacity(0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final WatchlistProvider provider;
  const _StatusBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final s in WatchStatus.values) s: provider.countFor(s),
    };
    final max = counts.values.fold(0, (m, c) => c > m ? c : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: WatchStatus.values.map((s) {
          final count = counts[s]!;
          final fraction = max == 0 ? 0.0 : count / max;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(s.shortLabel, style: AppText.caption),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: AppColor.slotEmpty,
                      valueColor: AlwaysStoppedAnimation(s.color),
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text('$count',
                      textAlign: TextAlign.right, style: AppText.numS),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
