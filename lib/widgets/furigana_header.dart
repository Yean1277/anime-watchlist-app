import 'package:flutter/material.dart';

import '../theme.dart';

/// A section header in the 宵/YOI style: an optional furigana reading (small,
/// wide-tracked kana) sitting above the title, with an optional trailing action
/// aligned to the baseline. The furigana is decorative — the [title] always
/// carries the real meaning (spec §1.2). Keep ≤3 furigana per screen.
class FuriganaHeader extends StatelessWidget {
  const FuriganaHeader({
    super.key,
    required this.title,
    this.furigana,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
  });

  final String title;
  final String? furigana;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (furigana != null && furigana!.isNotEmpty) ...[
          Text(furigana!, style: AppText.furigana),
          const SizedBox(height: 3),
        ],
        Text(title, style: AppText.titleM),
      ],
    );

    return Padding(
      padding: padding,
      child: trailing == null
          ? Align(alignment: Alignment.centerLeft, child: head)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: head),
                trailing!,
              ],
            ),
    );
  }
}
