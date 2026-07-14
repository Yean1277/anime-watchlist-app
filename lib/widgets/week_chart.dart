import 'package:flutter/material.dart';

import '../theme.dart';

/// The 週間視聴 bar chart (spec §2.8): 7 bars, top corners rounder than the
/// bottom (6/6/3/3). The two tallest bars are matcha; Sunday (last) is sakura —
/// the only place sakura appears in a chart.
///
/// NOTE: the app tracks no per-day watch history yet, so callers currently pass
/// a derived/placeholder distribution. Wire real data once watch events exist.
class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.values, // 7 values, 0..1
    this.labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.height = 66,
  });

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Indices of the two tallest bars → matcha highlight.
    final ranked = List.generate(values.length, (i) => i)
      ..sort((a, b) => values[b].compareTo(values[a]));
    final peaks = ranked.take(2).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isSunday = i == values.length - 1;
                      final color = isSunday
                          ? AppColor.secondary
                          : peaks.contains(i)
                              ? AppColor.accent
                              : const Color(0x1AECEDE8); // 10%
                      final double h =
                          (values[i].clamp(0.0, 1.0) * height)
                              .clamp(4.0, height)
                              .toDouble();
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: reduceMotion ? Duration.zero : AppMotion.bar,
                          curve: AppMotion.curve,
                          height: h,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(fontSize: 9)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
