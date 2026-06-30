import '../models/anime.dart';
import '../models/watchlist_item.dart';
import 'watchlist_repository.dart';

/// A non-persistent [WatchlistRepository] used in demo mode (when no Supabase
/// credentials are configured). State lives only in memory and resets on reload.
///
/// Starts empty but is fully functional: Jikan search still works, and items
/// can be added, re-statused, progressed, rated, and removed.
class InMemoryWatchlistRepository implements WatchlistRepository {
  final List<WatchlistItem> _items = [];
  int _counter = 0;

  int _indexOf(String id) => _items.indexWhere((i) => i.id == id);

  @override
  Future<List<WatchlistItem>> fetchAll() async => List.of(_items);

  @override
  Future<WatchlistItem> add(Anime anime, WatchStatus status) async {
    final item = WatchlistItem(
      id: 'demo-${_counter++}',
      malId: anime.malId,
      title: anime.title,
      titleJapanese: anime.titleJapanese,
      imageUrl: anime.imageUrl,
      episodes: anime.episodes,
      episodesWatched: 0,
      status: status,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<void> updateStatus(String id, WatchStatus status) async {
    final index = _indexOf(id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(status: status);
    }
  }

  @override
  Future<void> updateProgress(String id, int episodesWatched) async {
    final index = _indexOf(id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(episodesWatched: episodesWatched);
    }
  }

  @override
  Future<void> updateScore(String id, int? score) async {
    final index = _indexOf(id);
    if (index != -1) {
      _items[index] = _items[index]
          .copyWith(score: score, clearScore: score == null);
    }
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((i) => i.id == id);
  }
}
