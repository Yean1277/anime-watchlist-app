import 'package:flutter/material.dart';

import 'dark_mode_button.dart';

/// A consistent page header: big bold title, subtitle, and a trailing
/// dark-mode toggle (plus any extra actions).
class ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 10),
          const DarkModeButton(),
        ],
      ),
    );
  }
}
