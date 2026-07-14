import 'package:flutter/material.dart';

import '../theme.dart';

/// A selectable status/genre chip (spec §2.5): full-radius, matcha ink when
/// selected, quiet surface when not. Switches on the base motion curve.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final text = (count != null && count! > 0) ? '$label  $count' : label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColor.accent : AppColor.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected ? null : Border.all(color: AppColor.border),
        ),
        child: Text(
          text,
          style: AppText.body.copyWith(
            color: selected ? AppColor.onAccent : AppColor.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
