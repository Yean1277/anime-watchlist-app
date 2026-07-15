import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/anime.dart';

/// Failures surfaced by [JikanService], typed so the UI can tell a rate limit
/// (wait and retry) apart from a connectivity problem (check the network).
sealed class JikanException implements Exception {
  const JikanException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Jikan replied 429 and retries were exhausted (or Retry-After was too long
/// to honor interactively). Waiting a moment and searching again will work.
class JikanRateLimitException extends JikanException {
  const JikanRateLimitException() : super('Jikan API rate limit exceeded');
}

/// The request never got a usable HTTP response (offline, DNS, timeout).
class JikanNetworkException extends JikanException {
  const JikanNetworkException() : super('Could not reach the Jikan API');
}

/// Jikan replied with a non-200 we don't retry, or an unparseable body.
class JikanApiException extends JikanException {
  const JikanApiException(this.statusCode)
      : super('Jikan API error: $statusCode');
  final int statusCode;
}

/// Searches anime via the free Jikan API (MyAnimeList).
///
/// Jikan rate-limits aggressively (~3 req/s, 60/min), so transient 429s are
/// normal. Requests are retried with a short backoff — honoring `Retry-After`
/// when it's small enough for an interactive search — before a typed
/// [JikanException] is thrown.
class JikanService {
  JikanService({
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
    this.maxAttempts = 3,
    this.retryBaseDelay = const Duration(milliseconds: 350),
    Future<void> Function(Duration delay)? sleep,
  })  : _client = client ?? http.Client(),
        _sleep = sleep ?? Future<void>.delayed;

  static const String _base = 'https://api.jikan.moe/v4';

  /// Never honor a server-requested wait longer than this: an interactive
  /// search should fail fast (with a truthful message) instead of stalling.
  static const Duration _maxHonoredRetryAfter = Duration(seconds: 2);

  final http.Client _client;
  final Duration timeout;
  final int maxAttempts;
  final Duration retryBaseDelay;
  final Future<void> Function(Duration delay) _sleep;

  /// Returns up to 20 SFW anime matching [query].
  /// Returns an empty list for a blank query.
  Future<List<Anime>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse(
      '$_base/anime?q=${Uri.encodeQueryComponent(trimmed)}&limit=20&sfw=true',
    );
    return _fetchList(uri);
  }

  /// Returns the current top-ranked airing anime (for the Discover tab).
  Future<List<Anime>> topAiring({int limit = 25}) async {
    final uri = Uri.parse('$_base/top/anime?filter=airing&limit=$limit&sfw=true');
    return _fetchList(uri);
  }

  Future<List<Anime>> _fetchList(Uri uri) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final isLastAttempt = attempt == maxAttempts - 1;
      final backoff = retryBaseDelay * (1 << attempt);

      http.Response response;
      try {
        response = await _client
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(timeout);
        // http >=1.0 wraps socket/DNS failures in ClientException on every
        // platform (incl. web), so no dart:io import is needed here.
      } on http.ClientException {
        if (isLastAttempt) throw const JikanNetworkException();
        await _sleep(backoff);
        continue;
      } on TimeoutException {
        if (isLastAttempt) throw const JikanNetworkException();
        await _sleep(backoff);
        continue;
      }

      if (response.statusCode == 200) {
        return _parseList(response);
      }

      if (response.statusCode == 429) {
        final retryAfter = _retryAfterDelay(response);
        if (isLastAttempt ||
            (retryAfter != null && retryAfter > _maxHonoredRetryAfter)) {
          throw const JikanRateLimitException();
        }
        await _sleep(retryAfter ?? backoff);
        continue;
      }

      if (response.statusCode >= 500) {
        if (isLastAttempt) throw JikanApiException(response.statusCode);
        await _sleep(backoff);
        continue;
      }

      // Remaining 4xx are our fault (bad query, gone endpoint) — retrying
      // won't heal them.
      throw JikanApiException(response.statusCode);
    }
    throw const JikanNetworkException(); // unreachable; loop always exits above
  }

  List<Anime> _parseList(http.Response response) {
    final List<dynamic> data;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      data = (body['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      // A 200 with a non-JSON body (e.g. an intermediary's error page) must
      // not escape as a FormatException.
      throw JikanApiException(response.statusCode);
    }

    // De-duplicate by mal_id (Jikan can return repeats across relations) and
    // skip malformed entries rather than failing the whole result set.
    final seen = <int>{};
    final results = <Anime>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      if (item['mal_id'] is! int) continue;
      final anime = Anime.fromJson(item);
      if (seen.add(anime.malId)) {
        results.add(anime);
      }
    }
    return results;
  }

  /// Parses an integer-seconds `Retry-After` header (the form Jikan uses).
  /// Returns null for absent or HTTP-date values.
  Duration? _retryAfterDelay(http.Response response) {
    final raw = response.headers['retry-after'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
