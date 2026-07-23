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
| `lib/services/watchlist_service.dart` | Supabase CRUD on `user_anime` + `add-to-watchlist` Edge Function calls |
| `lib/providers/watchlist_provider.dart` | In-memory state + Supabase sync (optimistic) |
| `lib/screens/home_shell.dart` | 3-tab shell (Library / Search / Settings) with the floating pill nav |
| `lib/screens/library_screen.dart` | Home: hero, status filter pills, watchlist cards |
| `lib/screens/search_screen.dart` | Search tab: debounced Jikan search, top-airing idle state, tap to add |
| `lib/screens/settings_screen.dart` | Settings: profile summary, achievements, about |
| `lib/screens/detail_screen.dart` | Show detail: status, episode progress, star rating |
| `lib/widgets/anime_card.dart` | List row: cover, title, status, progress |
| `test/watchlist_item_test.dart` | Unit tests for status serialization |

## Conventions

- **Optimistic updates**: `WatchlistProvider` mutates local state and calls
  `notifyListeners()` immediately, then writes to Supabase and **rolls back** on
  failure. Keep this pattern for new mutations.
- **Status strings**: the DB stores snake_case (`plan_to_watch`, …). Always go
  through `WatchStatus.dbValue` / `WatchStatus.fromDb` — never hard-code strings.
- **Secrets**: only in `.env` (git-ignored). Never commit real keys. The `anon`
  key is a public client key; data is protected by RLS, not by hiding the key.
- **User scoping**: services filter every `user_anime` query by the signed-in
  user's id (`.eq('user_id', …)`). RLS write policies are own-row only, but the
  select policy also exposes opted-in public libraries — RLS is the safety net,
  not the scoping mechanism.
- **Score scale**: the DB stores scores on MAL's 1–10 scale; the UI's 1–5 stars
  map through `WatchlistItem.scoreStars` / `WatchlistItem.starsToScore` (×2).

## Gotchas

- `.env` is declared as a Flutter asset in `pubspec.yaml`, so it **must exist**
  before `flutter run`/build (copy from `.env.example`).
- Anonymous sign-ins must be **enabled** in the Supabase dashboard
  (Authentication → Providers → Anonymous), or launch fails with an `AuthException`.
- The Jikan API rate-limits bursts (~3 req/s). Search is debounced (~450ms),
  and `JikanService` retries 429/5xx/network errors with a short backoff
  (honoring small `Retry-After` values) before throwing a typed
  `JikanException` — the search UI distinguishes rate-limit from
  connectivity errors. Don't add raw `http.get` calls outside the service.
- Native `android/`/`ios/` folders are git-ignored and regenerated via
  `flutter create` (see Commands).
- Edits to `supabase/functions/add-to-watchlist/index.ts` only take effect
  after `supabase functions deploy add-to-watchlist` — merging alone deploys
  nothing. Keep the client tolerant of the previous response shape (see
  [docs/API_DESIGN.md](docs/API_DESIGN.md)).

## Branching

This repo follows **GitHub Flow**: `main` is always deployable, and all work happens
on short-lived, category-prefixed branches merged via PR — no long-lived `develop`
branch. Name branches `<category>/<short-kebab-description>` using the same
categories as commits (`feat/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`,
`ci/`). Full rules in [CONTRIBUTING.md](CONTRIBUTING.md).

## Documentation map

- [README.md](README.md) — overview & quickstart
- [CONTRIBUTING.md](CONTRIBUTING.md) — branching convention & PR workflow
- [SETUP.md](SETUP.md) — full setup + end-to-end verification
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — technical deep dive
- [docs/API_DESIGN.md](docs/API_DESIGN.md) — API contracts, error taxonomy, retry/timeout policies
- [docs/DECISIONS.md](docs/DECISIONS.md) — why the key choices were made
- [CHANGELOG.md](CHANGELOG.md) — what changed, by version


## Cloud session environment (Claude Code on the web)

This repo ships **Dart source only** — no native platform folders. In cloud
sessions, `web/` is generated at session start by
`scripts/flutter_bootstrap.sh` (SessionStart hook) and is gitignored.

### Rules

- **Never commit `web/`, `.dart_tool/`, `build/`, or `.env`.** They're
  generated per session and are in `.gitignore`.
- **Never run bare `flutter create`.** It overwrites `lib/main.dart` and
  `pubspec.yaml` with Flutter's template. The bootstrap script already runs it
  with a `git checkout -- lib/ pubspec.yaml` immediately after. If you must
  regenerate, follow the same pattern.
- **Don't edit `pubspec.yaml` to add deps by hand.** Use
  `flutter pub add <package>` so the lockfile stays consistent.

### Commands

| Task | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Unit tests | `flutter test` |
| Web build (verify compile) | `flutter build web --release` |
| Format | `dart format lib/ test/` |

Flutter lives at `/opt/flutter/bin` and is on `PATH`. If `flutter: command not
found`, run `export PATH="/opt/flutter/bin:$PATH"`.

### Verifying changes

There's no emulator or browser in a cloud session, so you can't click through
the UI. Verify with:

1. `flutter analyze` — must be clean
2. `flutter test` — must pass
3. `flutter build web --release` — catches compile errors `analyze` misses

Don't claim a UI change works without at least a successful web build.

### Backend

`.env` is empty by default → the app runs in **demo mode** (in-memory
watchlist, real Jikan API for search). Supabase calls are not exercised unless
`SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in the environment settings.
Assume demo mode when reasoning about runtime behaviour.
