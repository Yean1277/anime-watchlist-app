/// A search/top result from the Jikan API (https://docs.api.jikan.moe).
class Anime {
  final int malId;
  final String title;
  final String? titleJapanese;
  final String? imageUrl;
  final int? episodes;
  final double? score;
  final bool airing;
  final List<String> genres;

  const Anime({
    required this.malId,
    required this.title,
    this.titleJapanese,
    this.imageUrl,
    this.episodes,
    this.score,
    this.airing = false,
    this.genres = const [],
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final genresJson = (json['genres'] as List<dynamic>?) ?? const [];
    return Anime(
      malId: (json['mal_id'] as num).toInt(),
      title: json['title'] is String ? json['title'] as String : 'Unknown',
      titleJapanese: json['title_japanese'] as String?,
      imageUrl: jpg?['image_url'] as String?,
      episodes: (json['episodes'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble(),
      airing: (json['airing'] as bool?) ?? false,
      genres: genresJson
          .map((g) => (g as Map<String, dynamic>)['name'] as String? ?? '')
          .where((g) => g.isNotEmpty)
          .toList(),
    );
  }
}
