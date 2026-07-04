import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_label.dart';

/// Stats tab: summary cards and a per-status breakdown, computed live from the
/// watchlist.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const int _minutesPerEpisode = 24;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final episodes = provider.totalEpisodesWatched;
    final minutes = episodes * _minutesPerEpisode;
    final watchTime = minutes >= 60 ? '${minutes ~/ 60}h' : '${minutes}m';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            ScreenHeader(
              title: 'Stats',
              subtitle: '$minutes minutes well spent. probably.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$episodes',
                          label: 'Episodes watched',
                          color: kAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: watchTime,
                          label: 'Total watch time',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${provider.countFor(WatchStatus.watching)}',
                          label: 'Currently watching',
                          color: WatchStatus.watching.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '${provider.countFor(WatchStatus.completed)}',
                          label: 'Finished',
                          color: WatchStatus.completed.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SectionLabel(
              text: 'By status',
              padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _StatusBreakdown(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _StatCard({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColorFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: color ?? scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColorFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: WatchStatus.values.map((s) {
          final count = counts[s]!;
          final fraction = max == 0 ? 0.0 : count / max;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(s.shortLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation(s.color),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text('$count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
