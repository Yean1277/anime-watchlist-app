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

    test('dbValues match the SQL check constraint', () {
      final values = WatchStatus.values.map((s) => s.dbValue).toSet();
      expect(values, {
        'plan_to_watch',
        'watching',
        'completed',
        'dropped',
      });
    });
  });

  group('WatchlistItem', () {
    final json = {
      'id': 'abc-123',
      'mal_id': 20,
      'title': 'Naruto',
      'image_url': 'https://example.com/naruto.jpg',
      'episodes': 220,
      'status': 'watching',
    };

    test('fromJson parses all fields', () {
      final item = WatchlistItem.fromJson(json);
      expect(item.id, 'abc-123');
      expect(item.malId, 20);
      expect(item.title, 'Naruto');
      expect(item.imageUrl, 'https://example.com/naruto.jpg');
      expect(item.episodes, 220);
      expect(item.status, WatchStatus.watching);
    });

    test('toInsertJson omits server-managed columns', () {
      final item = WatchlistItem.fromJson(json);
      final insert = item.toInsertJson();
      expect(insert.containsKey('id'), isFalse);
      expect(insert.containsKey('user_id'), isFalse);
      expect(insert['mal_id'], 20);
      expect(insert['status'], 'watching');
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
