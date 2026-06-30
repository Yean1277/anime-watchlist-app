import 'package:flutter/foundation.dart';

import '../models/anime.dart';
import '../models/watchlist_item.dart';
import '../services/watchlist_repository.dart';

/// Holds the user's watchlist in memory and keeps the backing
/// [WatchlistRepository] (Supabase or in-memory demo) in sync.
class WatchlistProvider extends ChangeNotifier {
  final WatchlistRepository _repository;

  /// True when running without Supabase credentials (data is not persisted).
  final bool demoMode;

  WatchlistProvider(this._repository, {this.demoMode = false});

  List<WatchlistItem> _items = [];
  bool _loading = false;
  String? _error;

  List<WatchlistItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  int get count => _items.length;

  /// Items filtered by [status], or all items when [status] is null.
  List<WatchlistItem> itemsFor(WatchStatus? status) {
    if (status == null) return items;
    return _items.where((i) => i.status == status).toList();
  }

  int countFor(WatchStatus status) =>
      _items.where((i) => i.status == status).length;

  /// Total episodes the user has marked watched across the whole list.
  int get totalEpisodesWatched =>
      _items.fold(0, (sum, i) => sum + i.episodesWatched);

  bool contains(int malId) => _items.any((i) => i.malId == malId);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.fetchAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Adds [anime] to the list. No-op if it's already present.
  Future<void> add(Anime anime,
      {WatchStatus status = WatchStatus.planToWatch}) async {
    if (contains(anime.malId)) return;
    final item = await _repository.add(anime, status);
    _items = [item, ..._items];
    notifyListeners();
  }

  Future<void> updateStatus(WatchlistItem item, WatchStatus status) async {
    if (item.status == status) return;
    await _mutate(item, item.copyWith(status: status),
        () => _repository.updateStatus(item.id, status));
  }

  Future<void> updateProgress(WatchlistItem item, int episodesWatched) async {
    final clamped = episodesWatched < 0
        ? 0
        : (item.episodes != null && episodesWatched > item.episodes!
            ? item.episodes!
            : episodesWatched);
    if (clamped == item.episodesWatched) return;
    await _mutate(item, item.copyWith(episodesWatched: clamped),
        () => _repository.updateProgress(item.id, clamped));
  }

  Future<void> updateScore(WatchlistItem item, int? score) async {
    if (score == item.score) return;
    await _mutate(
        item,
        item.copyWith(score: score, clearScore: score == null),
        () => _repository.updateScore(item.id, score));
  }

  /// Applies [updated] optimistically, runs [persist], and rolls back on error.
  Future<void> _mutate(WatchlistItem original, WatchlistItem updated,
      Future<void> Function() persist) async {
    final index = _items.indexWhere((i) => i.id == original.id);
    if (index == -1) return;
    _items[index] = updated;
    notifyListeners();
    try {
      await persist();
    } catch (e) {
      _items[index] = original;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(WatchlistItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final removed = _items[index];
    _items.removeAt(index);
    notifyListeners();
    try {
      await _repository.remove(item.id);
    } catch (e) {
      _items.insert(index, removed);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
