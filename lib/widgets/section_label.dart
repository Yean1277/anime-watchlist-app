import 'package:flutter/material.dart';

/// An uppercase, letter-spaced section label, optionally with a trailing
/// widget on the opposite end (e.g. a count).
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionLabel({
    super.key,
    required this.text,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
    return Padding(
      padding: padding,
      child: trailing == null
          ? Align(alignment: Alignment.centerLeft, child: label)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [label, trailing!],
            ),
    );
  }
}
