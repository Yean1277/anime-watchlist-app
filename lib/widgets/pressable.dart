import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// App-wide press feedback: a gentle scale-down on tap + selection haptic.
/// No bounce/overshoot — "soft" means slow, round, low-contrast (spec §1.5).
///
/// Honors reduce-motion: when animations are disabled the scale is skipped.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = .965,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback onTap;

  /// Press-down scale. Primary buttons use .965; small round buttons/cells .90.
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down && !reduceMotion ? widget.scale : 1,
        duration: AppMotion.press,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
