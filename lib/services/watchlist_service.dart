import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/watchlist_item.dart';
import 'watchlist_repository.dart';

/// CRUD operations against the `user_anime` table (joined with the `anime`
/// cache table for display fields), plus the `add-to-watchlist` Edge Function
/// for inserts.
///
/// Row Level Security scopes every query to the signed-in (anonymous) user,
/// so no explicit `user_id` filtering is needed here.
class WatchlistService implements WatchlistRepository {
  final SupabaseClient _client;

  WatchlistService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  SupabaseQueryBuilder get _table => _client.from('user_anime');

  @override
  Future<List<WatchlistItem>> fetchAll() async {
    final rows = await _table
        .select('*, anime(*)')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => WatchlistItem.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds [anime] with the given [status] via the `add-to-watchlist` Edge
  /// Function, which fetches/caches the anime row from Jikan (service_role)
  /// before writing `user_anime` under the caller's own identity (RLS still
  /// applies to that write).
  @override
  Future<WatchlistItem> add(Anime anime, WatchStatus status) async {
    try {
      final response = await _client.functions.invoke(
        'add-to-watchlist',
        body: {'mal_id': anime.malId, 'status': status.dbValue},
      );
      final data = response.data as Map<String, dynamic>;
      final entry = data['entry'] as Map<String, dynamic>?;
      if (entry != null) {
        return WatchlistItem.fromJson(entry);
      }
      // already_in_list: true - the upsert skipped an existing row, so fetch
      // it directly instead of trusting a null entry.
      final existing = await _table
          .select('*, anime(*)')
          .eq('anime_id', anime.malId)
          .single();
      return WatchlistItem.fromJson(existing);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = (details is Map && details['error'] is String)
          ? details['error'] as String
          : 'Could not add anime (${e.status})';
      throw Exception(message);
    }
  }

  @override
  Future<void> updateStatus(String id, WatchStatus status) async {
    await _table.update({'status': status.dbValue}).eq('anime_id', int.parse(id));
  }

  @override
  Future<void> updateProgress(String id, int episodesWatched) async {
    await _table
        .update({'episodes_watched': episodesWatched})
        .eq('anime_id', int.parse(id));
  }

  @override
  Future<void> updateScore(String id, int? score) async {
    await _table.update({'score': score}).eq('anime_id', int.parse(id));
  }

  @override
  Future<void> remove(String id) async {
    await _table.delete().eq('anime_id', int.parse(id));
  }
}
