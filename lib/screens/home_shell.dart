import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/pressable.dart';
import 'discover_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

/// The app shell: four tabs behind a floating, blurred pill nav (spec §2.6).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    LibraryScreen(),
    DiscoverScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavItem(Icons.collections_bookmark_rounded, 'Library'),
    _NavItem(Icons.search_rounded, 'Discover'),
    _NavItem(Icons.insights_rounded, 'Stats'),
    _NavItem(Icons.person_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _PillNav(
        index: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _PillNav extends StatelessWidget {
  const _PillNav({
    required this.index,
    required this.items,
    required this.onTap,
  });

  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xE61E2126), // surface @ 90%
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColor.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavButton(
                      item: items[i],
                      selected: i == index,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColor.accent : AppColor.textMuted;
    return Pressable(
      scale: .90,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Container(
          // ≥44 hotzone.
          constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppText.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              // Selected marker: a small matcha dot (not an underline).
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? AppColor.accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
