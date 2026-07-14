import 'package:flutter/material.dart';

import '../theme.dart';

/// The 話数 episode grid (spec §2.4): 7 columns of numbered cells. Tapping cell
/// N fills progress up to N in one go (not a per-cell toggle); tapping the last
/// filled cell steps back to N-1. The next unwatched cell shows an inset matcha
/// border.
class EpisodeGrid extends StatelessWidget {
  const EpisodeGrid({
    super.key,
    required this.total,
    required this.watched,
    required this.onSet,
  });

  final int total;
  final int watched;

  /// Called with the episode count the user wants to be "up to".
  final ValueChanged<int> onSet;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: total,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final ep = i + 1;
        final done = ep <= watched;
        final isNext = ep == watched + 1;

        final Color fill;
        final Color fg;
        if (done) {
          fill = AppColor.accent;
          fg = AppColor.onAccent;
        } else {
          fill = isNext ? Colors.transparent : AppColor.slotEmpty;
          fg = isNext ? AppColor.accent : AppColor.textMuted;
        }

        return Semantics(
          button: true,
          selected: done,
          label: 'Episode $ep',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Tap filled last cell → step back; otherwise fill up to here.
            onTap: () => onSet(ep == watched ? ep - 1 : ep),
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppMotion.base,
              curve: AppMotion.curve,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: isNext
                    ? Border.all(color: AppColor.accent, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text('$ep',
                  style: AppText.label.copyWith(
                    color: fg,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
          ),
        );
      },
    );
  }
}
