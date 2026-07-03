import 'package:flutter_test/flutter_test.dart';

import 'package:anime_watchlist_app/models/watchlist_item.dart';

void main() {
  group('WatchStatus', () {
    test('dbValue round-trips through fromDb for every status', () {
      for (final status in WatchStatus.values) {
        expect(WatchStatus.fromDb(status.dbValue), status);
      }
    });

    test('fromDb falls back to planToWatch on unknown values', () {
      expect(WatchStatus.fromDb('not_a_status'), WatchStatus.planToWatch);
    });

    test('dbValues match the watch_status enum', () {
      final values = WatchStatus.values.map((s) => s.dbValue).toSet();
      expect(values, {
        'plan_to_watch',
        'watching',
        'completed',
        'on_hold',
        'dropped',
      });
    });
  });

  group('WatchlistItem', () {
    // Shape returned by `.from('user_anime').select('*, anime(*)')`: top-level
    // columns come from `user_anime`, nested `anime` comes from the joined
    // cache row.
    final json = {
      'anime_id': 20,
      'status': 'watching',
      'episodes_watched': 5,
      'score': null,
      'anime': {
        'mal_id': 20,
        'title': 'Naruto',
        'title_japanese': null,
        'image_url': 'https://example.com/naruto.jpg',
        'episodes': 220,
      },
    };

    test('fromJson parses all fields', () {
      final item = WatchlistItem.fromJson(json);
      expect(item.id, '20');
      expect(item.malId, 20);
      expect(item.title, 'Naruto');
      expect(item.imageUrl, 'https://example.com/naruto.jpg');
      expect(item.episodes, 220);
      expect(item.episodesWatched, 5);
      expect(item.status, WatchStatus.watching);
    });

    test('copyWith updates only the status', () {
      final item = WatchlistItem.fromJson(json);
      final updated = item.copyWith(status: WatchStatus.completed);
      expect(updated.status, WatchStatus.completed);
      expect(updated.malId, item.malId);
      expect(updated.title, item.title);
    });
  });
}
