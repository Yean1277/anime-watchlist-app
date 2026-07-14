import 'package:flutter/material.dart';

import '../theme.dart';

/// A rounded anime cover. Shows the real Jikan image when available, otherwise
/// a soft deterministic gradient tile with a single glyph (kanji/initial). A
/// 35% ink scrim is layered on every cover so mixed source art reads uniformly
/// against the dark canvas (spec §5.5).
class CoverTile extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? titleJapanese;
  final int seed;
  final double size;

  /// Optional explicit height; when null the tile is a [size]×[size] square.
  final double? height;
  final double? radius;

  const CoverTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.seed,
    this.titleJapanese,
    this.size = 64,
    this.height,
    this.radius,
  });

  // Soft, low-chroma two-stop gradients; picked deterministically by [seed] and
  // tuned to sit quietly in the 宵/YOI palette.
  static const List<List<Color>> _gradients = [
    [Color(0xFF3E5B7E), Color(0xFF25323F)],
    [Color(0xFF6E8F73), Color(0xFF2E3A31)],
    [Color(0xFF8B6A72), Color(0xFF3A2A2E)],
    [Color(0xFF5A6B86), Color(0xFF2A3140)],
    [Color(0xFF7C7E9A), Color(0xFF32333F)],
    [Color(0xFF9A8E6E), Color(0xFF3B372B)],
    [Color(0xFF6E7E86), Color(0xFF2E353A)],
  ];

  String get _glyph {
    final source = (titleJapanese != null && titleJapanese!.trim().isNotEmpty)
        ? titleJapanese!.trim()
        : title.trim();
    return source.isEmpty ? '?' : source.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? AppRadius.sm);
    final gradient = _gradients[seed.abs() % _gradients.length];

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _glyph,
          style: AppText.titleL.copyWith(
            color: AppColor.text.withOpacity(0.92),
            fontSize: size * 0.42,
          ),
        ),
      ),
    );

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return SizedBox(
      width: size,
      height: height ?? size,
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              )
            else
              fallback,
            // Uniform 35% ink scrim from top → bottom.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x5915171A)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
