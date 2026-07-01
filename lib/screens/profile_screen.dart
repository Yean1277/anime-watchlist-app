import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import '../widgets/screen_header.dart';

/// You tab: profile summary and a few account/app rows.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final demo = provider.demoMode;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            ScreenHeader(
              title: 'You',
              subtitle: demo
                  ? 'Demo mode · changes reset on reload'
                  : 'Signed in anonymously · synced',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ProfileCard(demo: demo),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MenuCard(
                children: [
                  _MenuRow(
                    icon: Icons.collections_bookmark_outlined,
                    label: '${provider.count} shows tracked',
                  ),
                  _MenuRow(
                    icon: Icons.play_circle_outline,
                    label: '${provider.totalEpisodesWatched} episodes logged',
                  ),
                  _AppearanceRow(),
                  _MenuRow(
                    icon: Icons.info_outline,
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
  const _ProfileCard({required this.demo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColorFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: kAccent,
            child: Icon(
              demo ? Icons.person_outline : Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demo ? 'Guest' : 'Anonymous user',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  demo ? 'No account connected' : 'Private, device-scoped list',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i != children.length - 1) {
        divided.add(Divider(
          height: 1,
          indent: 56,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: cardColorFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: divided),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: kAccent),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded)
              : null),
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);
    return _MenuRow(
      icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      label: 'Appearance',
      onTap: () => context.read<ThemeProvider>().toggle(context),
      trailing: Text(
        isDark ? 'Dark' : 'Light',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
