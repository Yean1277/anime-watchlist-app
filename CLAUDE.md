# CLAUDE.md

Guidance for Claude Code (and other AI/dev sessions) working in this repository.

## Project overview

A simple cross-platform (iOS + Android) **anime watchlist** app built with
**Flutter**, backed by **Supabase** (Postgres + Row Level Security), with anime
data from the free **Jikan API** (MyAnimeList). Users search anime and track them
by status — *Plan to Watch / Watching / Completed / Dropped*. Sign-in is
anonymous (no login screen), so each device gets its own private, cloud-synced
list.

## Commands

```bash
# One-time, after a fresh clone — generate the git-ignored native platform folders.
# flutter create overwrites lib/main.dart and pubspec.yaml, so restore them after.
flutter create --platforms=android,ios --org com.example .
git checkout -- lib/ pubspec.yaml

cp .env.example .env     # then fill in SUPABASE_URL and SUPABASE_ANON_KEY
flutter pub get          # install dependencies
flutter run              # build & run on a device/emulator/simulator
flutter test             # run unit tests
```

Full environment setup (Supabase project, SQL schema, enabling anonymous auth)
lives in [SETUP.md](SETUP.md).

## Architecture at a glance

```
UI (screens/, widgets/)  →  WatchlistProvider  →  services/  →  Supabase + Jikan
```

The UI never talks to the network directly. It reads from / calls
`WatchlistProvider` (a `ChangeNotifier`), which delegates persistence to
`WatchlistService` (Supabase CRUD) and search to `JikanService` (HTTP). See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for data-flow walkthroughs.

## Key files

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Bootstrap: load `.env`, init Supabase, anonymous sign-in, app root |
| `lib/theme.dart` | Material 3 theme |
| `lib/models/anime.dart` | Jikan search result model |
| `lib/models/watchlist_item.dart` | DB row model + `WatchStatus` enum (labels/colors/db strings) |
| `lib/services/jikan_service.dart` | `search(query)` against the Jikan API |
| `lib/services/watchlist_service.dart` | Supabase CRUD on the `watchlist` table |
| `lib/providers/watchlist_provider.dart` | In-memory state + Supabase sync (optimistic) |
| `lib/screens/watchlist_screen.dart` | Home: status filter tabs + list, FAB → search |
| `lib/screens/search_screen.dart` | Debounced Jikan search, tap to add |
| `lib/widgets/watchlist_card.dart` | List row: cover, title, status menu, delete |
| `lib/widgets/status_chip.dart` | Colored status label |
| `test/watchlist_item_test.dart` | Unit tests for status serialization |

## Conventions

- **Optimistic updates**: `WatchlistProvider` mutates local state and calls
  `notifyListeners()` immediately, then writes to Supabase and **rolls back** on
  failure. Keep this pattern for new mutations.
- **Status strings**: the DB stores snake_case (`plan_to_watch`, …). Always go
  through `WatchStatus.dbValue` / `WatchStatus.fromDb` — never hard-code strings.
- **Secrets**: only in `.env` (git-ignored). Never commit real keys. The `anon`
  key is a public client key; data is protected by RLS, not by hiding the key.
- **RLS scoping**: every `watchlist` query is automatically scoped to the
  signed-in user, so services do **not** filter by `user_id` manually.

## Gotchas

- `.env` is declared as a Flutter asset in `pubspec.yaml`, so it **must exist**
  before `flutter run`/build (copy from `.env.example`).
- Anonymous sign-ins must be **enabled** in the Supabase dashboard
  (Authentication → Providers → Anonymous), or launch fails with an `AuthException`.
- The Jikan API rate-limits bursts; search is debounced (~450ms) to be polite.
- Native `android/`/`ios/` folders are git-ignored and regenerated via
  `flutter create` (see Commands).

## Branch

Active development branch: `claude/anime-watchlist-app-i3vgx0`.

## Documentation map

- [README.md](README.md) — overview & quickstart
- [SETUP.md](SETUP.md) — full setup + end-to-end verification
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — technical deep dive
- [docs/DECISIONS.md](docs/DECISIONS.md) — why the key choices were made
- [CHANGELOG.md](CHANGELOG.md) — what changed, by version
