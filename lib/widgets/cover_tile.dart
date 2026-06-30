import 'package:flutter/material.dart';

/// A rounded anime cover. Shows the real Jikan image when available, otherwise
/// a deterministic gradient tile with a single glyph (kanji/initial), matching
/// the redesign's stylized look.
class CoverTile extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? titleJapanese;
  final int seed;
  final double size;

  const CoverTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.seed,
    this.titleJapanese,
    this.size = 64,
  });

  // A few tasteful two-stop gradients; picked deterministically by [seed].
  static const List<List<Color>> _gradients = [
    [Color(0xFF6D8BFF), Color(0xFF2BD4D4)],
    [Color(0xFF8B1E3F), Color(0xFF3D1E2E)],
    [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF7F53AC), Color(0xFF647DEE)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF4E54C8), Color(0xFF8F94FB)],
  ];

  String get _glyph {
    final source = (titleJapanese != null && titleJapanese!.trim().isNotEmpty)
        ? titleJapanese!.trim()
        : title.trim();
    return source.isEmpty ? '?' : source.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final gradient = _gradients[seed.abs() % _gradients.length];

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _glyph,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
