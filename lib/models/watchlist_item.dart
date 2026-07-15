import 'package:flutter/material.dart';

/// The status of an anime in the user's watchlist.
enum WatchStatus {
  planToWatch,
  watching,
  completed,
  onHold,
  dropped;

  /// The value stored in the database (matches the `watch_status` enum type).
  String get dbValue {
    switch (this) {
      case WatchStatus.planToWatch:
        return 'plan_to_watch';
      case WatchStatus.watching:
        return 'watching';
      case WatchStatus.completed:
        return 'completed';
      case WatchStatus.onHold:
        return 'on_hold';
      case WatchStatus.dropped:
        return 'dropped';
    }
  }

  /// Full human-readable label.
  String get label {
    switch (this) {
      case WatchStatus.planToWatch:
        return 'Plan to Watch';
      case WatchStatus.watching:
        return 'Watching';
      case WatchStatus.completed:
        return 'Completed';
      case WatchStatus.onHold:
        return 'On Hold';
      case WatchStatus.dropped:
        return 'Dropped';
    }
  }

  /// Short label used by compact chips/pills.
  String get shortLabel {
    switch (this) {
      case WatchStatus.planToWatch:
        return 'Plan';
      case WatchStatus.watching:
        return 'Watching';
      case WatchStatus.completed:
        return 'Completed';
      case WatchStatus.onHold:
        return 'On Hold';
      case WatchStatus.dropped:
        return 'Dropped';
    }
  }

  /// Muted status tone, harmonized with the 宵/YOI palette (soft, low-contrast).
  /// Matcha is reserved for the active "watching" state; the rest are quiet.
  Color get color {
    switch (this) {
      case WatchStatus.planToWatch:
        return const Color(0xFF8C918B); // 鼠 nezumi — quiet
      case WatchStatus.watching:
        return const Color(0xFFB9D4A0); // 抹茶 matcha — active
      case WatchStatus.completed:
        return const Color(0xFF9FC6C2); // muted teal
      case WatchStatus.onHold:
        return const Color(0xFFC9B98F); // muted gold
      case WatchStatus.dropped:
        return const Color(0xFFD19A9E); // muted rose
    }
  }

  /// Parse a database string back into a [WatchStatus].
  static WatchStatus fromDb(String value) {
    return WatchStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => WatchStatus.planToWatch,
    );
  }
}

/// A watchlist entry: a `user_anime` row joined with its cached `anime` row.
///
/// `user_anime` has no single-column id (its primary key is the composite
/// `(user_id, anime_id)`), so [id] is derived from [malId] — unique within a
/// single user's list — to keep it a stable, app-wide identity.
class WatchlistItem {
  final String id;
  final int malId;
  final String title;
  final String? titleJapanese;
  final String? imageUrl;
  final int? episodes;
  final int episodesWatched;
  final int? score;
  final WatchStatus status;

  const WatchlistItem({
    required this.id,
    required this.malId,
    required this.title,
    this.titleJapanese,
    this.imageUrl,
    this.episodes,
    this.episodesWatched = 0,
    this.score,
    required this.status,
  });

  /// [score] is stored on MAL's 1–10 scale (the DB check enforces it), while
  /// the UI rates in 1–5 stars. These two members are the only place that
  /// mapping lives.
  int? get scoreStars =>
      score == null ? null : (score! / 2).round().clamp(1, 5).toInt();

  /// Converts a 1–5 star rating to the 1–10 DB scale.
  static int starsToScore(int stars) => (stars * 2).clamp(1, 10).toInt();

  /// Parses a `user_anime` row fetched with `.select('*, anime(*)')`.
  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    final anime = json['anime'] as Map<String, dynamic>? ?? const {};
    final malId = json['anime_id'] as int;
    return WatchlistItem(
      id: malId.toString(),
      malId: malId,
      title: (anime['title'] ?? 'Unknown') as String,
      titleJapanese: anime['title_japanese'] as String?,
      imageUrl: anime['image_url'] as String?,
      episodes: anime['episodes'] as int?,
      episodesWatched: (json['episodes_watched'] as int?) ?? 0,
      score: json['score'] as int?,
      status: WatchStatus.fromDb(json['status'] as String),
    );
  }

  WatchlistItem copyWith({
    WatchStatus? status,
    int? episodesWatched,
    int? score,
    bool clearScore = false,
  }) {
    return WatchlistItem(
      id: id,
      malId: malId,
      title: title,
      titleJapanese: titleJapanese,
      imageUrl: imageUrl,
      episodes: episodes,
      episodesWatched: episodesWatched ?? this.episodesWatched,
      score: clearScore ? null : (score ?? this.score),
      status: status ?? this.status,
    );
  }
}
