import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';
import 'pressable.dart';

/// A circular "add to watchlist" button that becomes a check once the anime is
/// on the list. [big] renders the larger on-image variant used by the Discover
/// spotlight. [onTap] overrides the default add action (e.g. to show feedback);
/// the added state is always read from [WatchlistProvider].
class AddToListButton extends StatelessWidget {
  final Anime anime;
  final bool big;
  final VoidCallback? onTap;

  const AddToListButton({
    super.key,
    required this.anime,
    this.big = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final added = context.watch<WatchlistProvider>().contains(anime.malId);
    final visual = big ? 48.0 : 34.0;

    final Widget disc;
    if (added) {
      disc = Container(
        width: visual,
        height: visual,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: big ? AppColor.onAccent.withOpacity(0.18)
              : AppColor.accent.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded,
            color: big ? AppColor.onAccent : AppColor.accent,
            size: big ? 22 : 18),
      );
    } else {
      disc = Container(
        width: visual,
        height: visual,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: big ? AppColor.onAccent : AppColor.surfaceRaised,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add_rounded,
            color: big ? const Color(0xFFEDF2E6) : AppColor.accent,
            size: big ? 24 : 20),
      );
    }

    final button = added
        ? disc
        : Semantics(
            button: true,
            label: 'Add ${anime.title} to watchlist',
            child: Pressable(
              scale: .90,
              onTap: onTap ?? () => context.read<WatchlistProvider>().add(anime),
              child: disc,
            ),
          );

    // ≥44 hotzone around the 34px visual.
    return SizedBox(
      width: visual < 44 ? 44 : visual,
      height: visual < 44 ? 44 : visual,
      child: Center(child: button),
    );
  }
}
