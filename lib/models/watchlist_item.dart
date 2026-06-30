import 'package:flutter/material.dart';

/// The status of an anime in the user's watchlist.
enum WatchStatus {
  planToWatch,
  watching,
  completed,
  dropped;

  /// The value stored in the database (matches the SQL `check` constraint).
  String get dbValue {
    switch (this) {
      case WatchStatus.planToWatch:
        return 'plan_to_watch';
      case WatchStatus.watching:
        return 'watching';
      case WatchStatus.completed:
        return 'completed';
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
      case WatchStatus.dropped:
        return 'Dropped';
    }
  }

  /// Accent color used by status pills (matches the redesign palette).
  Color get color {
    switch (this) {
      case WatchStatus.planToWatch:
        return const Color(0xFF6C5CE7); // purple
      case WatchStatus.watching:
        return const Color(0xFF10B981); // green
      case WatchStatus.completed:
        return const Color(0xFF3B82F6); // blue
      case WatchStatus.dropped:
        return const Color(0xFFEF4444); // red
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

/// A single row in the `watchlist` Supabase table.
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

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      malId: json['mal_id'] as int,
      title: json['title'] as String,
      titleJapanese: json['title_japanese'] as String?,
      imageUrl: json['image_url'] as String?,
      episodes: json['episodes'] as int?,
      episodesWatched: (json['episodes_watched'] as int?) ?? 0,
      score: json['score'] as int?,
      status: WatchStatus.fromDb(json['status'] as String),
    );
  }

  /// Columns sent on insert. `id`, `user_id`, and `created_at` are filled by
  /// database defaults (`user_id` defaults to `auth.uid()`).
  Map<String, dynamic> toInsertJson() {
    return {
      'mal_id': malId,
      'title': title,
      'title_japanese': titleJapanese,
      'image_url': imageUrl,
      'episodes': episodes,
      'episodes_watched': episodesWatched,
      'score': score,
      'status': status.dbValue,
    };
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
