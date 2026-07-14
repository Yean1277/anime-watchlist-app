import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// A circular icon button. Default sits on a surface disc (headers: add, back).
/// The [scrim] variant is a blurred ink disc for placing over cover art (detail
/// hero back/like buttons). Hotzone is kept ≥44 via an outer [SizedBox].
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool scrim;
  final Color? iconColor;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.scrim = false,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scrim ? AppColor.scrim : AppColor.surface,
        shape: BoxShape.circle,
        border: scrim ? null : Border.all(color: AppColor.border),
      ),
      child: Icon(icon,
          size: 20, color: iconColor ?? AppColor.text),
    );

    final button = Pressable(
      scale: .90,
      onTap: onTap,
      child: scrim
          ? ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: disc,
              ),
            )
          : disc,
    );

    // Keep the visual size but guarantee a ≥44 touch target.
    return SizedBox(
      width: size < 44 ? 44 : size,
      height: size < 44 ? 44 : size,
      child: Center(child: button),
    );
  }
}
