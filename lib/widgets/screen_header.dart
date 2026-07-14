import 'package:flutter/material.dart';

import '../theme.dart';

/// A consistent page header: an optional furigana reading, a big display title,
/// a muted subtitle, and any trailing actions. (The old dark-mode toggle is
/// gone — the app is dark-only.)
class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? furigana;
  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.furigana,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (furigana != null && furigana!.isNotEmpty) ...[
                  Text(furigana!, style: AppText.furigana),
                  const SizedBox(height: 4),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 10), a],
        ],
      ),
    );
  }
}
