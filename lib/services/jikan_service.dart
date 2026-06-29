import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/anime.dart';

/// Searches anime via the free Jikan API (MyAnimeList).
class JikanService {
  static const String _base = 'https://api.jikan.moe/v4';

  /// Returns up to 20 SFW anime matching [query].
  /// Returns an empty list for a blank query or any API/parse error.
  Future<List<Anime>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse(
      '$_base/anime?q=${Uri.encodeQueryComponent(trimmed)}&limit=20&sfw=true',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Jikan API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>?) ?? [];

    // De-duplicate by mal_id (Jikan can return repeats across relations).
    final seen = <int>{};
    final results = <Anime>[];
    for (final item in data) {
      final anime = Anime.fromJson(item as Map<String, dynamic>);
      if (seen.add(anime.malId)) {
        results.add(anime);
      }
    }
    return results;
  }
}
