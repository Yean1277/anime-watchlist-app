import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'circle_icon_button.dart';

/// Circular light/dark toggle used in screen headers.
class DarkModeButton extends StatelessWidget {
  const DarkModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);
    return CircleIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      onTap: () => context.read<ThemeProvider>().toggle(context),
    );
  }
}
