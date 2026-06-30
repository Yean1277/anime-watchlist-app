# Architecture

A technical reference for how the anime watchlist app is structured and how data
flows through it. For *why* these choices were made, see
[DECISIONS.md](DECISIONS.md); for setup, see [SETUP.md](../SETUP.md).

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

1. User types; input is debounced ~450ms.
2. `JikanService.search(query)` GETs
   `…/anime?q=<query>&limit=20&sfw=true`, maps `data[]` to `Anime`, and
   de-duplicates by `mal_id`.
3. Results render as tiles. Items already in the list show a check instead of an
   add button (`WatchlistProvider.contains(malId)`).
4. Tapping add calls `WatchlistProvider.add(anime)` (defaults to *Plan to Watch*),
   which inserts via `WatchlistService` and prepends the new item.

### c. Status change with optimistic update (`WatchlistCard` → `WatchlistProvider`)

1. User picks a new status from the card's menu.
2. `WatchlistProvider.updateStatus(item, status)` updates the in-memory item and
   calls `notifyListeners()` **immediately** — the card moves tabs at once.
3. It then awaits `WatchlistService.updateStatus(id, status)`.
4. On failure, the previous value is **restored** and the error surfaced — the UI
   reverts. `remove()` follows the same optimistic + rollback pattern.

## Data model

The single Supabase table `watchlist` (schema in [SETUP.md](../SETUP.md)) maps to
`WatchlistItem`:

| Column | Type | Maps to | Notes |
| --- | --- | --- | --- |
| `id` | uuid | `WatchlistItem.id` | server default `gen_random_uuid()` |
| `user_id` | uuid | — (not in model) | server default `auth.uid()`; RLS key |
| `mal_id` | int | `malId` | MyAnimeList id; unique per user |
| `title` | text | `title` | |
| `image_url` | text | `imageUrl` | cover art |
| `episodes` | int | `episodes` | nullable |
| `status` | text | `status` | one of the `WatchStatus.dbValue` strings |
| `created_at` | timestamptz | — | ordering (newest first) |

`WatchStatus` is the source of truth for status values. `dbValue` produces the
snake_case strings stored in the DB and required by the table's `check`
constraint; `fromDb` parses them back (falling back to `planToWatch`). The enum
also carries the UI `label` and `color`. Server-managed columns (`id`, `user_id`,
`created_at`) are never sent on insert — see `WatchlistItem.toInsertJson()`.

## Security model

- **Row Level Security** is enabled on `watchlist`, with select/insert/update/delete
  policies all requiring `auth.uid() = user_id`. A user can only ever read or
  modify their own rows, so the service layer needs no manual `user_id` filtering.
- `user_id` defaults to `auth.uid()` at the database, so inserts can't spoof another
  user's id.
- The **`anon` key is a public client key** and is safe to ship in the app; it does
  not grant data access on its own — RLS does the enforcement. Real secrets (none
  required for this app beyond the project URL/anon key) would still live only in
  the git-ignored `.env`.

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
