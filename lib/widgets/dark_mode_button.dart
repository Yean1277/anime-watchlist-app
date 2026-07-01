import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme.dart';

/// Circular light/dark toggle used in screen headers.
class DarkModeButton extends StatelessWidget {
  const DarkModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: cardColorFor(context),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.read<ThemeProvider>().toggle(context),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 22,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
