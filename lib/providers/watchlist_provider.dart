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

  /// Items filtered by [status], or all items when [status] is null.
  List<WatchlistItem> itemsFor(WatchStatus? status) {
    if (status == null) return items;
    return _items.where((i) => i.status == status).toList();
  }

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
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final previous = _items[index];
    // Optimistic update, rolled back on failure.
    _items[index] = previous.copyWith(status: status);
    notifyListeners();
    try {
      await _repository.updateStatus(item.id, status);
    } catch (e) {
      _items[index] = previous;
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
