/// A search result from the Jikan API (https://docs.api.jikan.moe).
class Anime {
  final int malId;
  final String title;
  final String? imageUrl;
  final int? episodes;

  const Anime({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.episodes,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    return Anime(
      malId: json['mal_id'] as int,
      title: (json['title'] ?? 'Unknown') as String,
      imageUrl: jpg?['image_url'] as String?,
      episodes: json['episodes'] as int?,
    );
  }
}
