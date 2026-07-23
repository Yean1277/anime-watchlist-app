import 'package:flutter_test/flutter_test.dart';

import 'package:anime_watchlist_app/models/anime.dart';

void main() {
  group('Anime.fromJson', () {
    test('parses a full Jikan search entry', () {
      final anime = Anime.fromJson({
        'mal_id': 20,
        'title': 'Naruto',
        'title_japanese': 'ナルト',
        'images': {
          'jpg': {'image_url': 'https://example.com/naruto.jpg'},
        },
        'episodes': 220,
        'score': 7.99,
        'airing': false,
        'genres': [
          {'mal_id': 1, 'name': 'Action'},
          {'mal_id': 2, 'name': 'Adventure'},
        ],
      });
      expect(anime.malId, 20);
      expect(anime.title, 'Naruto');
      expect(anime.imageUrl, 'https://example.com/naruto.jpg');
      expect(anime.episodes, 220);
      expect(anime.score, 7.99);
      expect(anime.genres, ['Action', 'Adventure']);
    });

    test('tolerates null display fields and numeric ids decoded as num', () {
      final anime = Anime.fromJson({
        'mal_id': 20.0,
        'title': null,
        'images': null,
        'episodes': 220.0,
        'score': 8,
      });
      expect(anime.malId, 20);
      expect(anime.title, 'Unknown');
      expect(anime.imageUrl, isNull);
      expect(anime.episodes, 220);
      expect(anime.score, 8.0);
      expect(anime.airing, isFalse);
      expect(anime.genres, isEmpty);
    });

    test('drops genre entries without a name', () {
      final anime = Anime.fromJson({
        'mal_id': 1,
        'title': 'X',
        'genres': [
          {'mal_id': 1, 'name': 'Action'},
          {'mal_id': 2, 'name': null},
        ],
      });
      expect(anime.genres, ['Action']);
    });

    test('skips non-map genre entries and keeps well-formed ones', () {
      final anime = Anime.fromJson({
        'mal_id': 1,
        'title': 'X',
        'genres': [
          'Action', // bare string — not a genre object
          null, // null entry
          42, // number
          {'mal_id': 1, 'name': 'Adventure'},
        ],
      });
      expect(anime.genres, ['Adventure']);
    });

    test('returns normally with a missing mal_id, defaulting to 0', () {
      final anime = Anime.fromJson({
        'title': 'X',
        'genres': [
          {'mal_id': 1, 'name': 'Comedy'},
        ],
      });
      expect(anime.malId, 0);
      expect(anime.genres, ['Comedy']);
    });
  });
}
