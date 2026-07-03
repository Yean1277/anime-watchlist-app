import 'package:flutter/material.dart';

import '../theme.dart';

/// A circular icon button on a card-colored disc, used in screen headers
/// (dark-mode toggle, add, back).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: cardColorFor(context),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 22, color: scheme.onSurface),
        ),
      ),
    );
  }
}
