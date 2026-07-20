# Architecture

A technical reference for how the anime watchlist app is structured and how data
flows through it. For *why* these choices were made, see
[DECISIONS.md](DECISIONS.md); for setup, see [SETUP.md](../SETUP.md); for the
network contracts (endpoints, error codes, retry/timeout policies), see
[API_DESIGN.md](API_DESIGN.md).

## Layered overview

```
┌─────────────────────────────────────────────────────────────┐
│  UI layer                                                     │
│  screens/ (WatchlistScreen, SearchScreen)                     │
│  widgets/ (WatchlistCard, StatusChip)                         │
└───────────────▲───────────────────────────┬─────────────────┘
                │ watch / read               │ method calls
                │ (notifyListeners)          ▼
┌─────────────────────────────────────────────────────────────┐
│  State layer                                                  │
│  providers/WatchlistProvider  (ChangeNotifier)                │
│   • holds List<WatchlistItem>, loading, error                 │
│   • optimistic add / updateStatus / remove + rollback         │
└───────────────▲───────────────────────────┬─────────────────┘
                │                            │
                │                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Service layer                                                │
│  services/WatchlistService  →  Supabase (Postgres + RLS)      │
│  services/JikanService      →  Jikan API (HTTP)               │
└─────────────────────────────────────────────────────────────┘
                │                            │
                ▼                            ▼
          Supabase project              api.jikan.moe
```

The UI never performs I/O directly. It depends only on `WatchlistProvider`, which
in turn depends on the two services. This keeps screens declarative and makes the
services independently testable.

## Data flows

### a. App launch / bootstrap (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. `dotenv.load()` reads `.env` (a declared Flutter asset).
3. `Supabase.initialize(url, anonKey)` configures the client.
4. If there is no existing session, `auth.signInAnonymously()` creates a
   device-scoped anonymous user.
5. `runApp` mounts `ChangeNotifierProvider(create: WatchlistProvider()..load())`,
   so the watchlist begins loading immediately.

### b. Search and add (`SearchScreen` → `JikanService` → `WatchlistProvider`)

1. User types; input is debounced ~450ms. A generation token drops stale
   responses so a slow request can't overwrite newer results.
2. `JikanService.search(query)` GETs
   `…/anime?q=<query>&limit=20&sfw=true` (retrying 429/5xx/network errors
   with a short backoff, honoring small `Retry-After` values), maps `data[]`
   to `Anime` — skipping malformed entries — and de-duplicates by `mal_id`.
   Failures surface as typed `JikanException`s so the UI can tell a rate
   limit from a connectivity problem.
3. Results render as tiles. Items already in the list show a check instead of an
   add button (`WatchlistProvider.contains(malId)`).
4. Tapping add calls `WatchlistProvider.add(anime)` (defaults to *Plan to Watch*),
   which invokes the `add-to-watchlist` Edge Function via `WatchlistService` and
   prepends the returned item.

### c. Status change with optimistic update (`WatchlistCard` → `WatchlistProvider`)

1. User picks a new status from the card's menu.
2. `WatchlistProvider.updateStatus(item, status)` updates the in-memory item and
   calls `notifyListeners()` **immediately** — the card moves tabs at once.
3. It then awaits `WatchlistService.updateStatus(id, status)`.
4. On failure, the previous value is **restored** and the error surfaced — the UI
   reverts. `remove()` follows the same optimistic + rollback pattern.

## Data model

`WatchlistItem` is built from a `user_anime` row joined with its cached `anime`
row (`.select('*, anime(*)')`; schema in [SETUP.md](../SETUP.md)):

| Column | Table | Type | Maps to | Notes |
| --- | --- | --- | --- | --- |
| `anime_id` | `user_anime` | bigint | `malId` (and `id`, as `malId.toString()`) | FK → `anime.mal_id`; part of the composite PK |
| `user_id` | `user_anime` | uuid | — (not in model) | set explicitly to `auth.uid()`; RLS key |
| `status` | `user_anime` | `watch_status` enum | `status` | one of the `WatchStatus.dbValue` strings |
| `episodes_watched` | `user_anime` | int | `episodesWatched` | |
| `score` | `user_anime` | smallint (1-10) | `score` | nullable; MAL scale — the UI's 1-5 stars map via `scoreStars` / `starsToScore` (×2) |
| `created_at` | `user_anime` | timestamptz | — | ordering (newest first) |
| `title` / `title_japanese` | `anime` | text | `title` / `titleJapanese` | |
| `image_url` | `anime` | text | `imageUrl` | cover art |
| `episodes` | `anime` | int | `episodes` | nullable |

`user_anime` has no single-column id — its primary key is `(user_id, anime_id)` —
so `WatchlistItem.id` is derived from `malId`, which is unique within one user's
list. `WatchStatus` is the source of truth for status values: `dbValue` produces
the snake_case strings stored in the `watch_status` Postgres enum; `fromDb` parses
them back (falling back to `planToWatch`). The enum also carries the UI `label`
and `color`.

The `anime` table is a shared Jikan cache (keyed by `mal_id`) populated by the
`add-to-watchlist` Edge Function, not written directly by the app.

## Security model

- **Row Level Security** is enabled on every table. `user_anime` requires
  `auth.uid() = user_id` for insert/update/delete, so a user can only ever
  modify their own rows. The **select** policy is deliberately wider: it also
  exposes libraries whose owner opted in via `profiles.is_library_public`
  (default `false`). Because of that, the service layer filters every read
  (and, for consistency, every write) by the signed-in user's id — RLS is the
  safety net, not the scoping mechanism. `anime` (and its related cache
  tables) are select-only for the `anon` role.
- Because `anime` isn't writable by the app, adding a new entry goes through the
  `add-to-watchlist` Edge Function: it authenticates the caller's JWT, fetches/
  upserts the `anime` row using the `service_role` key (bypassing RLS, server-side
  only), then writes `user_anime` using the caller's own identity so RLS still
  applies to that write. See `supabase/functions/add-to-watchlist/index.ts`.
- A database trigger (`handle_new_user`) creates a `profiles` row for every new
  `auth.users` row (including anonymous sign-ins), satisfying `user_anime`'s FK
  to `profiles` with no app-side code.
- The **`anon` key is a public client key** and is safe to ship in the app; it does
  not grant data access on its own — RLS does the enforcement. The
  `service_role` key used by the Edge Function is never exposed to the client;
  it's injected server-side by Supabase.

## Directory map

```
lib/
├── main.dart                      # bootstrap (flow a)
├── theme.dart                     # Material 3 theme
├── models/
│   ├── anime.dart                 # Jikan result
│   └── watchlist_item.dart        # DB row + WatchStatus enum
├── services/
│   ├── jikan_service.dart         # search (flow b)
│   └── watchlist_service.dart     # Supabase CRUD
├── providers/
│   └── watchlist_provider.dart    # state + optimistic sync (flow c)
├── screens/
│   ├── watchlist_screen.dart      # tabs + list + FAB
│   └── search_screen.dart         # debounced search + add
└── widgets/
    ├── watchlist_card.dart        # row UI
    └── status_chip.dart           # status label
test/
└── watchlist_item_test.dart       # status serialization tests
```
