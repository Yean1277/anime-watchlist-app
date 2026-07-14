import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/furigana_header.dart';
import '../widgets/screen_header.dart';

/// You (設定): profile summary, derived achievements, and a couple of app rows.
/// The app is dark-only, so there's no appearance toggle.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final demo = provider.demoMode;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            ScreenHeader(
              furigana: 'せってい',
              title: 'You',
              subtitle: demo
                  ? 'Demo mode · changes reset on reload'
                  : 'Signed in anonymously · synced',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ProfileCard(demo: demo, episodes: provider.totalEpisodesWatched),
            ),
            const FuriganaHeader(furigana: 'じっせき', title: 'Achievements'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Achievements(provider: provider),
            ),
            const FuriganaHeader(furigana: 'アカウント', title: 'Account'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MenuCard(
                children: [
                  _MenuRow(
                    icon: Icons.collections_bookmark_rounded,
                    label: '${provider.count} shows tracked',
                  ),
                  _MenuRow(
                    icon: Icons.play_circle_outline,
                    label: '${provider.totalEpisodesWatched} episodes logged',
                  ),
                  _MenuRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Anime Watchlist',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Built with Flutter · data from the Jikan API (MyAnimeList).',
                    ),
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

class _ProfileCard extends StatelessWidget {
  final bool demo;
  final int episodes;
  const _ProfileCard({required this.demo, required this.episodes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF6E8F73),
                  AppColor.accent,
                  AppColor.secondary,
                  Color(0xFF6E8F73),
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.surfaceRaised,
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColor.textMuted, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(demo ? 'Guest' : 'Anonymous user',
                    style: AppText.titleL),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColor.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('$episodes episodes logged',
                      style: AppText.label.copyWith(color: AppColor.accent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A few achievement tags derived from real watchlist numbers (no fake data).
class _Achievements extends StatelessWidget {
  final WatchlistProvider provider;
  const _Achievements({required this.provider});

  @override
  Widget build(BuildContext context) {
    final completed = provider.countFor(WatchStatus.completed);
    final watching = provider.countFor(WatchStatus.watching);
    final episodes = provider.totalEpisodesWatched;

    final tags = <(_TagKind, String)>[
      if (watching > 0) (_TagKind.accent, 'Watching $watching'),
      if (completed > 0) (_TagKind.accent, 'Finished $completed'),
      if (episodes >= 50) (_TagKind.plain, '50+ episodes'),
      if (episodes >= 100) (_TagKind.plain, 'Century club'),
      if (provider.count >= 10) (_TagKind.plain, 'Collector'),
    ];
    if (tags.isEmpty) {
      tags.add((_TagKind.plain, 'Just getting started'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) {
        final accent = t.$1 == _TagKind.accent;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColor.surface,
            border: Border.all(
                color: accent
                    ? AppColor.accent.withOpacity(0.35)
                    : AppColor.border),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(t.$2,
              style: AppText.body.copyWith(
                  color: accent ? AppColor.accent : AppColor.text)),
        );
      }).toList(),
    );
  }
}

enum _TagKind { accent, plain }

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i != children.length - 1) {
        divided.add(const Divider(height: 1, indent: 52, color: AppColor.border));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(children: divided),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColor.accent, size: 22),
      title: Text(label, style: AppText.titleS),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColor.textMuted)
          : null,
    );
  }
}
