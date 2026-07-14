import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A circular progress ring with round stroke caps (round ends are "the soft"
/// — spec §1.3/§5.3). Animates via a single tween on the one app curve; never
/// repaints every frame. Set [onAccent] when placed on a matcha surface.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 82,
    this.onAccent = false,
    this.child,
    this.semanticsValue,
  });

  final double progress; // 0..1
  final double size;
  final bool onAccent;
  final Widget? child;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final double end = progress.clamp(0.0, 1.0).toDouble();
    final double stroke = (size * 0.085).clamp(3.0, 8.0).toDouble();
    final ring = SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: reduceMotion ? end : 0.0, end: end),
        duration: reduceMotion ? Duration.zero : AppMotion.ring,
        curve: AppMotion.curve,
        builder: (_, p, __) => CustomPaint(
          painter: _RingPainter(
            p,
            stroke: stroke,
            track: onAccent ? const Color(0x29171B16) : AppColor.track,
            fill: onAccent ? AppColor.onAccent : AppColor.accent,
          ),
          child: Center(child: child),
        ),
      ),
    );
    if (semanticsValue == null) return ring;
    return Semantics(value: semanticsValue, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.p,
      {required this.stroke, required this.track, required this.fill});

  final double p;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas c, Size s) {
    final r = (s.width - stroke) / 2;
    final center = Offset(s.width / 2, s.height / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round // round — non-negotiable
      ..color = fill;

    c.drawCircle(center, r, base);
    if (p > 0) {
      c.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2,
          2 * math.pi * p, false, prog);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.p != p || old.fill != fill || old.track != track;
}
