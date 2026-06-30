# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project documentation set:
  - `CLAUDE.md` — guidance for AI/dev sessions (commands, architecture, conventions).
  - `CHANGELOG.md` — this file.
  - `docs/DECISIONS.md` — ADR-style log of key technical decisions.
  - `docs/ARCHITECTURE.md` — layered architecture, data flows, data & security model.
- **Demo mode**: the app now runs without Supabase credentials, using an
  in-memory store so the UI is browsable (starts empty, changes don't persist).
  A `WatchlistRepository` interface backs both the Supabase and in-memory stores,
  and a banner indicates when demo mode is active.
- **Web deployment**: `.github/workflows/deploy-web.yml` builds the Flutter web
  app and publishes it to GitHub Pages (demo mode by default; optional
  `SUPABASE_URL`/`SUPABASE_ANON_KEY` secrets enable a connected build).
- Optional `--dart-define` support for Supabase config (alternative to `.env`).

### Changed
- `main.dart` now detects whether Supabase is configured and selects the backend
  accordingly; `.env` is optional at runtime.

## [0.1.0] - 2026-06-29

Initial build of the anime watchlist app.

### Added
- Flutter app scaffold (Material 3) targeting iOS and Android.
- Anime search via the Jikan API (`JikanService`) with cover art and episode counts.
- Status tracking with four statuses (Plan to Watch / Watching / Completed /
  Dropped) and per-status filter tabs on the home screen.
- Cloud-synced watchlist stored in Supabase with Row Level Security
  (`WatchlistService`, `watchlist` table).
- Anonymous authentication so each device gets a private list with no sign-up.
- `WatchlistProvider` state management with optimistic add/update/remove and
  rollback on failure.
- Configuration via `flutter_dotenv` (`.env`), with `.env.example` placeholders.
- Unit tests for `WatchStatus` serialization and `WatchlistItem` mapping.
- `README.md` (overview/quickstart) and `SETUP.md` (Supabase setup, SQL schema,
  RLS policies, and end-to-end verification steps).

[Unreleased]: https://github.com/Yean1277/anime-watchlist-app/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Yean1277/anime-watchlist-app/releases/tag/v0.1.0
