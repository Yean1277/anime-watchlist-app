import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/watchlist_item.dart';
import 'watchlist_repository.dart';

/// CRUD operations against the `user_anime` table (joined with the `anime`
/// cache table for display fields), plus the `add-to-watchlist` Edge Function
/// for inserts. Contract details live in docs/API_DESIGN.md.
///
/// Every query filters by the signed-in (anonymous) user's id explicitly:
/// the `user_anime` SELECT policy intentionally also exposes other users'
/// public libraries, so RLS is a safety net here, not the scoping mechanism.
class WatchlistService implements WatchlistRepository {
  final SupabaseClient _client;

  WatchlistService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Plain table reads/writes should answer well within this.
  static const Duration _dbTimeout = Duration(seconds: 10);

  /// The Edge Function may retry Jikan server-side, so give it more room.
  static const Duration _functionTimeout = Duration(seconds: 20);

  SupabaseQueryBuilder get _table => _client.from('user_anime');

  /// main.dart signs in before creating the service, but a session can still
  /// be lost at runtime — fail with a clear message instead of a null crash.
  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in — cannot access the watchlist');
    }
    return user.id;
  }

  /// [WatchlistItem.id] is the mal_id as a string (see the model); anything
  /// else means the caller mixed in ids from another repository.
  int _animeId(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null) {
      throw ArgumentError.value(id, 'id', 'not a numeric watchlist item id');
    }
    return parsed;
  }

  @override
  Future<List<WatchlistItem>> fetchAll() async {
    final rows = await _table
        .select('*, anime(*)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .timeout(_dbTimeout);
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
      ).timeout(_functionTimeout);
      final data = response.data;
      final entry = data is Map<String, dynamic>
          ? data['entry'] as Map<String, dynamic>?
          : null;
      if (entry != null) {
        return WatchlistItem.fromJson(entry);
      }
      // Deployed functions since the duplicate-path fix always return the
      // entry, but tolerate a null from an older deployment by fetching the
      // row directly. The user_id filter is what makes .single() safe:
      // without it, another user publicly tracking the same anime would make
      // this query return multiple rows.
      final existing = await _table
          .select('*, anime(*)')
          .eq('user_id', _uid)
          .eq('anime_id', anime.malId)
          .single()
          .timeout(_dbTimeout);
      return WatchlistItem.fromJson(existing);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = (details is Map && details['error'] is String)
          ? details['error'] as String
          : 'Could not add anime (${e.status})';
      throw Exception(message);
    } on TimeoutException {
      throw Exception('Adding timed out — check your connection and retry');
    }
  }

  @override
  Future<void> updateStatus(String id, WatchStatus status) async {
    await _table
        .update({'status': status.dbValue})
        .eq('user_id', _uid)
        .eq('anime_id', _animeId(id))
        .timeout(_dbTimeout);
  }

  @override
  Future<void> updateProgress(String id, int episodesWatched) async {
    await _table
        .update({'episodes_watched': episodesWatched})
        .eq('user_id', _uid)
        .eq('anime_id', _animeId(id))
        .timeout(_dbTimeout);
  }

  @override
  Future<void> updateScore(String id, int? score) async {
    await _table
        .update({'score': score})
        .eq('user_id', _uid)
        .eq('anime_id', _animeId(id))
        .timeout(_dbTimeout);
  }

  @override
  Future<void> remove(String id) async {
    await _table
        .delete()
        .eq('user_id', _uid)
        .eq('anime_id', _animeId(id))
        .timeout(_dbTimeout);
  }
}
