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

/// Outcome of a single HTTP attempt inside the retry loop.
///
/// Modeling each attempt as one of three results — succeed, retry, or give up —
/// lets the retry/backoff plumbing live in one place instead of being repeated
/// for every failure mode (network, timeout, 429, 5xx).
sealed class _Attempt {
  const _Attempt();
}

/// The request succeeded; [anime] is the parsed result set.
class _Success extends _Attempt {
  const _Success(this.anime);
  final List<Anime> anime;
}

/// The request failed transiently. Wait [delay] (falling back to the caller's
/// backoff when null) and try again — unless this was the final attempt, in
/// which case [onExhausted] is thrown.
class _Retry extends _Attempt {
  const _Retry({required this.onExhausted, this.delay});
  final Duration? delay;
  final JikanException onExhausted;
}

/// The request failed in a way retrying can't heal; throw [error] immediately.
class _Fail extends _Attempt {
  const _Fail(this.error);
  final JikanException error;
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
        _ownsClient = client == null,
        _sleep = sleep ?? Future<void>.delayed;

  static const String _base = 'https://api.jikan.moe/v4';

  /// Never honor a server-requested wait longer than this: an interactive
  /// search should fail fast (with a truthful message) instead of stalling.
  static const Duration _maxHonoredRetryAfter = Duration(seconds: 2);

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final int maxAttempts;
  final Duration retryBaseDelay;
  final Future<void> Function(Duration delay) _sleep;

  /// Returns up to 20 SFW anime matching [query].
  /// Returns an empty list for a blank query.
  Future<List<Anime>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse('$_base/anime').replace(queryParameters: {
      'q': trimmed,
      'limit': '20',
      'sfw': 'true',
    });
    return _fetchList(uri);
  }

  /// Returns the current top-ranked airing anime (for the Discover tab).
  ///
  /// [limit] is clamped to Jikan's supported 1–25 range, so out-of-range
  /// callers get a sane request instead of an API-side rejection.
  Future<List<Anime>> topAiring({int limit = 25}) async {
    final safeLimit = limit.clamp(1, 25);
    final uri = Uri.parse('$_base/top/anime').replace(queryParameters: {
      'filter': 'airing',
      'limit': '$safeLimit',
      'sfw': 'true',
    });
    return _fetchList(uri);
  }

  /// Drives the retry loop: classify each attempt, then either return, wait and
  /// retry, or throw. All the backoff bookkeeping lives here — [_classify] only
  /// decides what a given response/error *means*.
  Future<List<Anime>> _fetchList(Uri uri) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final isLastAttempt = attempt == maxAttempts - 1;
      final backoff = retryBaseDelay * (1 << attempt);

      final result = await _classify(uri);
      switch (result) {
        case _Success(:final anime):
          return anime;
        case _Fail(:final error):
          throw error;
        case _Retry(:final delay, :final onExhausted):
          if (isLastAttempt) throw onExhausted;
          await _sleep(delay ?? backoff);
      }
    }
    throw const JikanNetworkException(); // unreachable; loop always exits above
  }

  /// Performs one HTTP attempt and maps the response (or thrown error) onto an
  /// [_Attempt]. Contains no retry/sleep logic — that's [_fetchList]'s job.
  Future<_Attempt> _classify(Uri uri) async {
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      // http >=1.0 wraps socket/DNS failures in ClientException on every
      // platform (incl. web), so no dart:io import is needed here.
    } on http.ClientException {
      return const _Retry(onExhausted: JikanNetworkException());
    } on TimeoutException {
      return const _Retry(onExhausted: JikanNetworkException());
    }

    final status = response.statusCode;

    if (status == 200) {
      return _Success(_parseList(response));
    }

    if (status == 429) {
      final retryAfter = _retryAfterDelay(response);
      // A Retry-After we can't honor interactively means give up now.
      if (retryAfter != null && retryAfter > _maxHonoredRetryAfter) {
        return const _Fail(JikanRateLimitException());
      }
      return _Retry(
        delay: retryAfter,
        onExhausted: const JikanRateLimitException(),
      );
    }

    if (status >= 500) {
      return _Retry(onExhausted: JikanApiException(status));
    }

    // Remaining 4xx are our fault (bad query, gone endpoint) — retrying
    // won't heal them.
    return _Fail(JikanApiException(status));
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

  /// Closes the underlying [http.Client] — but only if this service created it.
  /// When a client was injected, its lifecycle belongs to the caller, so
  /// closing it here would be a surprise; that case is deliberately a no-op.
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
