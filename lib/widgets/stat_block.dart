import 'package:flutter/material.dart';

import '../theme.dart';

/// One number+label pair for [StatBlock].
class StatEntry {
  const StatEntry(this.value, this.label);
  final String value;
  final String label;
}

/// Three-up stats row divided by hairline borders (spec §2.7): big Outfit
/// numbers over muted captions, on one surface card.
class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.entries});

  final List<StatEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        border: Border.all(color: AppColor.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 34, color: AppColor.border),
            Expanded(
              child: Column(
                children: [
                  Text(entries[i].value, style: AppText.numXL),
                  const SizedBox(height: 5),
                  Text(entries[i].label,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
