import 'package:flutter_test/flutter_test.dart';

import 'package:anime_watchlist_app/models/anime.dart';
import 'package:anime_watchlist_app/models/watchlist_item.dart';
import 'package:anime_watchlist_app/providers/watchlist_provider.dart';
import 'package:anime_watchlist_app/services/watchlist_repository.dart';

/// Repository fake with a switchable failure mode, so tests can exercise the
/// provider's optimistic-apply / rollback contract.
class _FakeRepository implements WatchlistRepository {
  _FakeRepository(this.items);

  List<WatchlistItem> items;
  bool failing = false;

  void _maybeThrow() {
    if (failing) throw Exception('backend down');
  }

  @override
  Future<List<WatchlistItem>> fetchAll() async {
    _maybeThrow();
    return List.of(items);
  }

  @override
  Future<WatchlistItem> add(Anime anime, WatchStatus status) async {
    _maybeThrow();
    return WatchlistItem(
      id: anime.malId.toString(),
      malId: anime.malId,
      title: anime.title,
      status: status,
    );
  }

  @override
  Future<void> updateStatus(String id, WatchStatus status) async =>
      _maybeThrow();

  @override
  Future<void> updateProgress(String id, int episodesWatched) async =>
      _maybeThrow();

  @override
  Future<void> updateScore(String id, int? score) async => _maybeThrow();

  @override
  Future<void> remove(String id) async => _maybeThrow();
}

WatchlistItem _item(int malId,
    {WatchStatus status = WatchStatus.watching,
    int episodes = 12,
    int episodesWatched = 3}) {
  return WatchlistItem(
    id: malId.toString(),
    malId: malId,
    title: 'Show $malId',
    episodes: episodes,
    episodesWatched: episodesWatched,
    status: status,
  );
}

void main() {
  late _FakeRepository repository;
  late WatchlistProvider provider;

  setUp(() async {
    repository = _FakeRepository([_item(1), _item(2), _item(3)]);
    provider = WatchlistProvider(repository);
    await provider.load();
  });

  group('load', () {
    test('populates items and clears loading', () {
      expect(provider.items, hasLength(3));
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
    });

    test('sets error on failure instead of throwing', () async {
      repository.failing = true;
      await provider.load();
      expect(provider.error, contains('backend down'));
      expect(provider.loading, isFalse);
    });

    test('retry after a failure clears the error', () async {
      repository.failing = true;
      await provider.load();
      expect(provider.error, isNotNull);
      repository.failing = false;
      await provider.load();
      expect(provider.error, isNull);
      expect(provider.items, hasLength(3));
    });
  });

  group('optimistic mutations', () {
    test('updateStatus applies immediately on success', () async {
      await provider.updateStatus(provider.items.first, WatchStatus.completed);
      expect(provider.items.first.status, WatchStatus.completed);
      expect(provider.error, isNull);
    });

    test('updateStatus rolls back and rethrows on failure', () async {
      repository.failing = true;
      final original = provider.items.first;
      await expectLater(
        provider.updateStatus(original, WatchStatus.completed),
        throwsException,
      );
      expect(provider.items.first.status, original.status);
      expect(provider.error, contains('backend down'));
    });

    test('updateProgress clamps to the episode count and rolls back', () async {
      final item = provider.items.first; // 12 episodes
      await provider.updateProgress(item, 99);
      expect(provider.items.first.episodesWatched, 12);

      repository.failing = true;
      await expectLater(
        provider.updateProgress(provider.items.first, 5),
        throwsException,
      );
      expect(provider.items.first.episodesWatched, 12);
    });

    test('updateScore rolls back on failure', () async {
      repository.failing = true;
      final original = provider.items.first;
      await expectLater(provider.updateScore(original, 8), throwsException);
      expect(provider.items.first.score, original.score);
    });

    test('remove reinserts the item at its original index on failure',
        () async {
      repository.failing = true;
      final second = provider.items[1];
      await expectLater(provider.remove(second), throwsException);
      expect(provider.items, hasLength(3));
      expect(provider.items[1].id, second.id);
    });

    test('remove drops the item on success', () async {
      await provider.remove(provider.items[1]);
      expect(provider.items, hasLength(2));
    });
  });

  group('add', () {
    test('prepends the new item', () async {
      const anime = Anime(malId: 99, title: 'New Show');
      await provider.add(anime);
      expect(provider.items.first.malId, 99);
      expect(provider.items.first.status, WatchStatus.planToWatch);
    });

    test('is a no-op when the anime is already tracked', () async {
      const anime = Anime(malId: 1, title: 'Show 1');
      await provider.add(anime);
      expect(provider.items, hasLength(3));
    });
  });
}
