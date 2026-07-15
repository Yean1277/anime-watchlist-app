import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/watchlist_item.dart';
import 'watchlist_repository.dart';

/// CRUD operations against the `user_anime` table (joined with the `anime`
/// cache table for display fields), plus the `add-to-watchlist` Edge Function
/// for inserts.
///
/// Every query filters by the signed-in (anonymous) user's id explicitly:
/// the `user_anime` SELECT policy intentionally also exposes other users'
/// public libraries, so RLS is a safety net here, not the scoping mechanism.
class WatchlistService implements WatchlistRepository {
  final SupabaseClient _client;

  WatchlistService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  SupabaseQueryBuilder get _table => _client.from('user_anime');

  /// Non-null by construction: main.dart signs in before creating the service.
  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<List<WatchlistItem>> fetchAll() async {
    final rows = await _table
        .select('*, anime(*)')
        .eq('user_id', _uid)
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
      // it directly instead of trusting a null entry. The user_id filter is
      // what makes .single() safe: without it, another user publicly tracking
      // the same anime would make this query return multiple rows.
      final existing = await _table
          .select('*, anime(*)')
          .eq('user_id', _uid)
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
    await _table
        .update({'status': status.dbValue})
        .eq('user_id', _uid)
        .eq('anime_id', int.parse(id));
  }

  @override
  Future<void> updateProgress(String id, int episodesWatched) async {
    await _table
        .update({'episodes_watched': episodesWatched})
        .eq('user_id', _uid)
        .eq('anime_id', int.parse(id));
  }

  @override
  Future<void> updateScore(String id, int? score) async {
    await _table
        .update({'score': score})
        .eq('user_id', _uid)
        .eq('anime_id', int.parse(id));
  }

  @override
  Future<void> remove(String id) async {
    await _table.delete().eq('user_id', _uid).eq('anime_id', int.parse(id));
  }
}
