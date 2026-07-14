import 'package:flutter/material.dart';

import '../theme.dart';

/// A 5-star rating row. Read-only by default; pass [onRate] to make it tappable
/// (tapping the same star again clears the rating).
class StarRating extends StatelessWidget {
  final int? score;
  final double size;
  final ValueChanged<int?>? onRate;

  const StarRating({
    super.key,
    required this.score,
    this.size = 16,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final filled = score ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1;
        final icon = Icon(
          value <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: value <= filled
              ? AppColor.accent
              : AppColor.textMuted.withOpacity(0.5),
        );
        if (onRate == null) return icon;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onRate!(value == score ? null : value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: icon,
          ),
        );
      }),
    );
  }
}
