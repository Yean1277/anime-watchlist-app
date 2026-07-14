import 'package:flutter/material.dart';

import '../models/watchlist_item.dart';
import '../theme.dart';

/// A soft, rounded status pill with a leading dot, e.g. "● Watching". Uses the
/// status's muted YOI tone at low opacity.
class StatusPill extends StatelessWidget {
  final WatchStatus status;
  final bool compact;

  const StatusPill({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? status.shortLabel : status.label,
            style: AppText.label.copyWith(
              color: color,
              fontFamily: 'ZenMaruGothic',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
