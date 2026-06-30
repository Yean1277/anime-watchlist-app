import '../models/anime.dart';
import '../models/watchlist_item.dart';

/// Abstraction over watchlist persistence so the app can run against either
/// Supabase (production) or an in-memory store (demo mode, no backend).
///
/// Implementations: [WatchlistService] (Supabase) and
/// [InMemoryWatchlistRepository] (demo).
abstract class WatchlistRepository {
  Future<List<WatchlistItem>> fetchAll();
  Future<WatchlistItem> add(Anime anime, WatchStatus status);
  Future<void> updateStatus(String id, WatchStatus status);
  Future<void> updateProgress(String id, int episodesWatched);
  Future<void> updateScore(String id, int? score);
  Future<void> remove(String id);
}
