import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';
import 'library_screen.dart';

/// The app's top-level shell: a persistent bottom navigation bar over the four
/// tabs. Only Library is fully built; the rest are styled placeholders.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    LibraryScreen(),
    ComingSoonScreen(
      title: 'Discover',
      subtitle: "What's everyone bingeing this cour",
      icon: Icons.explore_outlined,
    ),
    ComingSoonScreen(
      title: 'Stats',
      subtitle: 'Your watch habits, visualized',
      icon: Icons.bar_chart_rounded,
    ),
    ComingSoonScreen(
      title: 'You',
      subtitle: 'Profile & settings',
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
