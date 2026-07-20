# API Design

The contracts, error taxonomy, and stability policies of every network surface
the app touches. For how the layers fit together see
[ARCHITECTURE.md](ARCHITECTURE.md); for why the stack was chosen see
[DECISIONS.md](DECISIONS.md).

The app has three API surfaces:

| Surface | Client | Transport |
| --- | --- | --- |
| Jikan (MyAnimeList) search & rankings | `lib/services/jikan_service.dart` | Plain HTTPS (`http` package) |
| `add-to-watchlist` Edge Function | `lib/services/watchlist_service.dart` → `functions.invoke` | Supabase Functions |
| `user_anime` CRUD | `lib/services/watchlist_service.dart` | Supabase PostgREST |

The UI never calls any of these directly — everything goes through
`WatchlistProvider` (state) or the search screens (which own a `JikanService`).

## Identity & scale conventions

- **`mal_id` is the universal identity.** Jikan results, the `anime` cache
  table (`mal_id` PK), and `user_anime.anime_id` all share MyAnimeList's id
  namespace. `user_anime` has a composite primary key `(user_id, anime_id)` —
  no surrogate id — so the app-side `WatchlistItem.id` is `malId.toString()`,
  unique within one user's list.
- **Repository ids are stringly-typed but numeric for Supabase.** The
  `WatchlistRepository` interface passes `String id`; `WatchlistService`
  parses it back to the `anime_id` int and throws `ArgumentError` on anything
  non-numeric (ids from the in-memory demo repository are not interchangeable
  with Supabase ids).
- **Scores are stored 1–10 (MAL scale), rated 1–5 stars in the UI.** The only
  mapping lives in `WatchlistItem.scoreStars` (score ÷ 2, rounded, clamped
  1–5) and `WatchlistItem.starsToScore` (stars × 2). Star → score → star
  round-trips exactly; raw odd DB scores (e.g. 7) are lossy by design.
- **Status strings are snake_case** (`plan_to_watch`, `watching`, `completed`,
  `on_hold`, `dropped`), matching the `watch_status` Postgres enum. Always go
  through `WatchStatus.dbValue` / `WatchStatus.fromDb`; `fromDb` falls back to
  `planToWatch` on unknown values rather than crashing on a schema drift.

## Jikan client contract (`JikanService`)

### Endpoints

| Method | Endpoint | Used by |
| --- | --- | --- |
| `search(query)` | `GET /v4/anime?q=<query>&limit=20&sfw=true` | Search tab |
| `topAiring()` | `GET /v4/top/anime?filter=airing&limit=25&sfw=true` | Search idle state |

Blank queries short-circuit to an empty list without a request. Responses are
parsed into `Anime` (`lib/models/anime.dart`); malformed entries (missing
`mal_id`) are skipped rather than failing the whole result set, and results
are de-duplicated by `mal_id`.

### Stability policy

Jikan rate-limits aggressively (~3 req/s, 60/min), so transient failures are
treated as normal:

- **Timeout:** 6 s per request.
- **Retries:** up to 3 attempts total. 429, 5xx, timeouts, and socket/DNS
  errors are retried with exponential backoff (350 ms → 700 ms → give up).
- **`Retry-After`:** an integer-seconds header ≤ 2 s is honored instead of the
  backoff; a longer one fails fast with a truthful rate-limit error rather
  than stalling an interactive search.
- **Search debounce (~450 ms) + a generation token** in the search screen keep
  request volume down and drop stale responses.
- Raw `http.get` calls outside `JikanService` are forbidden (see CLAUDE.md) so
  this policy can't be bypassed.

### Exception taxonomy

All failures surface as a sealed `JikanException`:

| Exception | Meaning | UI treatment |
| --- | --- | --- |
| `JikanRateLimitException` | 429 after retries, or `Retry-After` too long | "rate limited — wait and retry" state |
| `JikanNetworkException` | No usable HTTP response (offline, DNS, timeout) | "check your connection" state |
| `JikanApiException(status)` | Non-retryable 4xx, retried-out 5xx, or unparseable 200 body | generic error state |

## Edge Function contract (`add-to-watchlist`)

Adding an anime is the one write that can't go straight to PostgREST: the
`anime` cache table is select-only for clients, so the function fetches/caches
the Jikan record server-side (with `service_role`), then writes `user_anime`
**as the caller** so RLS still applies. Source:
`supabase/functions/add-to-watchlist/index.ts`.

### Request

```
POST /functions/v1/add-to-watchlist
Authorization: Bearer <caller JWT>       (required)
Content-Type: application/json

{ "mal_id": 20, "status": "watching" }   ("status" optional, default "plan_to_watch")
```

### Success response — `200`

```json
{ "ok": true, "entry": { …user_anime row, "anime": { …cache row } }, "already_in_list": false }
```

- `entry` is the `user_anime` row selected with `*, anime(*)` — the same shape
  the client reads everywhere else, parseable by `WatchlistItem.fromJson`.
- **Idempotency:** re-adding an already-tracked anime is a no-op on the row
  (`ignoreDuplicates` upsert — it never resets an existing status back to
  `plan_to_watch`) and returns the *existing* row with
  `already_in_list: true`.
- **Compatibility note:** deployments older than the duplicate-path fix
  return `entry: null` when `already_in_list` is true. `WatchlistService.add`
  therefore still tolerates a null `entry` by fetching the row itself; keep
  that fallback until every environment has redeployed the function.

### Error responses

Errors are always `{ "error": "<message>" }` with these status codes:

| Status | Condition |
| --- | --- |
| 400 | Malformed JSON body, non-positive/non-integer `mal_id`, or unknown `status` |
| 401 | Missing `Authorization` header or invalid JWT |
| 404 | Anime id does not exist on MAL |
| 502 | Jikan returned a non-retryable error (or 5xx after retries) |
| 503 | Jikan rate-limited after server-side retries — retry later |
| 504 | Jikan did not respond within the server-side timeout |
| 500 | Anything else (DB write failure, unexpected exception) |

`WatchlistService.add` surfaces the `error` message from this body to the UI,
falling back to a generic message when the body isn't in this shape.

### Server-side stability policy

- **Jikan fetches** use an 8 s `AbortSignal` timeout and retry 429/5xx up to
  3 attempts with exponential backoff (400 ms base), honoring integer
  `Retry-After` values ≤ 2 s — mirroring the app-side `JikanService` policy.
- **Cache freshness:** the anime row is only re-fetched from Jikan when stale
  — older than 24 h for airing shows, 30 days for finished ones. A fresh cache
  hit adds an entry without touching Jikan at all.
- **Write ordering over transactions:** the multi-table write (anime → genres
  → user_anime) is not atomic, but ordered so partial failure is safe: the
  `anime` row must land before `user_anime` (FK), and genre-cache failures are
  logged and skipped rather than failing the user's add (they self-heal on the
  next sync).
- **Episode sync runs in the background** (`EdgeRuntime.waitUntil`) and never
  blocks or fails the response; its errors are logged and retried the next
  time the cache expires.

### Deployment

Changes to the function only take effect after
`supabase functions deploy add-to-watchlist` — merging to `main` does **not**
deploy it. The Flutter client is written to work against both the current and
previous response shape, so deploy order doesn't matter.

## Supabase data access (`WatchlistService`)

| Operation | Query |
| --- | --- |
| `fetchAll` | `user_anime.select('*, anime(*)').eq('user_id', uid).order('created_at', desc)` |
| `updateStatus` / `updateProgress` / `updateScore` | `user_anime.update({…}).eq('user_id', uid).eq('anime_id', id)` |
| `remove` | `user_anime.delete().eq('user_id', uid).eq('anime_id', id)` |

- **Every query filters by `user_id` explicitly.** The `user_anime` SELECT
  policy intentionally also exposes opted-in public libraries
  (`profiles.is_library_public`, default `false`), so RLS is the *safety net*,
  not the scoping mechanism — forgetting the filter would leak other users'
  public rows into the UI, not just rely on RLS to hide them. Write policies
  are own-row only.
- **Timeouts:** 10 s on table reads/writes, 20 s on the Edge Function call
  (it may be retrying Jikan server-side). A timeout on add is mapped to a
  user-readable message.
- **Auth guard:** the service resolves the signed-in user per call and throws
  a descriptive `StateError` if the session is gone, instead of a null crash.
- The `anime` / `genres` / `anime_episodes` cache tables are **select-only**
  for clients; they are written exclusively by the Edge Function.

## Error handling flow (client)

```
service throws (typed where possible)
        │
        ▼
WatchlistProvider: optimistic value already applied →
  rolls back to the original, sets `error`, rethrows
        │
        ▼
UI: awaits the call → SnackBar ("Couldn't save — change reverted") or
  full error state with Retry (failed initial load)
```

- **Mutations are optimistic**: the provider mutates memory and notifies
  immediately, persists, and restores the exact previous value on failure.
  UI callers must `await` provider mutations and surface the rethrow — a
  swallowed error looks like the app silently undoing the user's tap.
- **A failed initial `load()` is not an empty library**: the library screen
  shows an error state with a Retry button whenever the list is empty and
  `provider.error` is set.
- **Startup degradation ladder** (`lib/main.dart`): missing/placeholder
  credentials → demo mode (in-memory store); Supabase init or anonymous
  sign-in failure → demo mode with a logged warning. The app always reaches
  the first frame.
- **Model parsing is defensive**: display fields degrade (`'Unknown'` title,
  null image) and numeric fields accept any JSON `num`, but a `user_anime`
  row without an `anime_id` fails loudly (`FormatException`) since it has no
  identity.

## Known limitations

- **No cross-table transaction** in the Edge Function — mitigated by write
  ordering (see above), not eliminated. Moving the write into a Postgres
  function (RPC) would make it atomic if it ever grows more steps.
- **No offline queue**: a mutation made while offline fails (and rolls back)
  rather than syncing later.
- **The Edge Function has no automated tests** (no Deno test infra in this
  repo); the Dart client and models are unit-tested.
- **Genre/episode caches are best-effort**: their sync failures are logged
  and deferred, so genre chips or episode metadata can lag behind the anime
  row until the next cache refresh.
