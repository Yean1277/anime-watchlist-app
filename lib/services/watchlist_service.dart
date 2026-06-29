import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/watchlist_item.dart';

/// CRUD operations against the `watchlist` table.
///
/// Row Level Security scopes every query to the signed-in (anonymous) user,
/// so no explicit `user_id` filtering is needed here.
class WatchlistService {
  final SupabaseClient _client;

  WatchlistService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  SupabaseQueryBuilder get _table => _client.from('watchlist');

  Future<List<WatchlistItem>> fetchAll() async {
    final rows = await _table.select().order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => WatchlistItem.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds [anime] with the given [status] and returns the inserted row.
  Future<WatchlistItem> add(Anime anime, WatchStatus status) async {
    final payload = {
      'mal_id': anime.malId,
      'title': anime.title,
      'image_url': anime.imageUrl,
      'episodes': anime.episodes,
      'status': status.dbValue,
    };
    final inserted = await _table.insert(payload).select().single();
    return WatchlistItem.fromJson(inserted);
  }

  Future<void> updateStatus(String id, WatchStatus status) async {
    await _table.update({'status': status.dbValue}).eq('id', id);
  }

  Future<void> remove(String id) async {
    await _table.delete().eq('id', id);
  }
}
