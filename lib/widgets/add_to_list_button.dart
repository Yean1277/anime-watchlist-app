import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/watchlist_provider.dart';
import '../theme.dart';

/// A circular "add to watchlist" button that turns into a check once the
/// anime is on the list. [big] renders the larger on-image variant used by
/// the Discover spotlight. [onTap] overrides the default add action (e.g. to
/// show a snackbar); the added state is always read from [WatchlistProvider].
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
    if (added) {
      return Icon(Icons.check_circle,
          color: big ? Colors.white : kSuccess, size: big ? 40 : 28);
    }
    return Material(
      color: big ? kAccent : kAccent.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => context.read<WatchlistProvider>().add(anime),
        child: Padding(
          padding: EdgeInsets.all(big ? 12 : 6),
          child: Icon(Icons.add,
              color: big ? Colors.white : kAccent, size: big ? 24 : 22),
        ),
      ),
    );
  }
}
