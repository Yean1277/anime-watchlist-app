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

  /// Human-readable label shown in the UI.
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

  /// Accent color used by the status chip.
  Color get color {
    switch (this) {
      case WatchStatus.planToWatch:
        return Colors.blueGrey;
      case WatchStatus.watching:
        return Colors.indigo;
      case WatchStatus.completed:
        return Colors.green;
      case WatchStatus.dropped:
        return Colors.redAccent;
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
  final String? imageUrl;
  final int? episodes;
  final WatchStatus status;

  const WatchlistItem({
    required this.id,
    required this.malId,
    required this.title,
    this.imageUrl,
    this.episodes,
    required this.status,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      malId: json['mal_id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
      episodes: json['episodes'] as int?,
      status: WatchStatus.fromDb(json['status'] as String),
    );
  }

  /// Columns sent on insert. `id`, `user_id`, and `created_at` are filled by
  /// database defaults (`user_id` defaults to `auth.uid()`).
  Map<String, dynamic> toInsertJson() {
    return {
      'mal_id': malId,
      'title': title,
      'image_url': imageUrl,
      'episodes': episodes,
      'status': status.dbValue,
    };
  }

  WatchlistItem copyWith({WatchStatus? status}) {
    return WatchlistItem(
      id: id,
      malId: malId,
      title: title,
      imageUrl: imageUrl,
      episodes: episodes,
      status: status ?? this.status,
    );
  }
}
