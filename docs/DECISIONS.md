# Decision Log

A lightweight record of significant technical decisions (ADR-style). Each entry
captures the **context**, the **decision**, and its **consequences** so future
contributors understand *why* the project looks the way it does.

> Status legend: ✅ Accepted · 🔁 Superseded · 💭 Proposed

---

## 1. Flutter for the mobile app — ✅ Accepted

**Context.** The goal is a "modern mobile app" that runs on both iOS and Android
from a single codebase, built quickly by a small team.

**Decision.** Use Flutter (Dart) with Material 3.

**Consequences.** One codebase for both platforms; rich widget library and fast
iteration (hot reload). Trade-off: Dart is a separate language/ecosystem, and the
native `android/`/`ios/` folders are generated locally (not committed) via
`flutter create`.

---

## 2. Supabase as the backend — ✅ Accepted

**Context.** The watchlist must persist beyond a single session and be able to
sync across devices later, without us hand-rolling a server.

**Decision.** Use Supabase (hosted Postgres) with Row Level Security, accessed via
`supabase_flutter`. Data lives in a single `watchlist` table.

**Consequences.** Managed auth + database + RLS with little backend code. The list
is cloud-stored, not device-only. Trade-off: requires a Supabase project and
network connectivity; introduces a vendor dependency.

---

## 3. Anonymous auth for v1 — ✅ Accepted

**Context.** We want zero sign-up friction, but Supabase RLS needs an authenticated
user to own rows.

**Decision.** Sign each device in anonymously on first launch
(`auth.signInAnonymously()`); no login UI.

**Consequences.** Frictionless UX and per-user data isolation via RLS. Trade-off:
the list is **device-bound** — reinstalling or switching devices loses access.
Upgrade path: Supabase supports linking an anonymous account to email/password
later without losing data. Requires "Anonymous sign-ins" to be enabled in the
Supabase dashboard.

---

## 4. Jikan API for anime data — ✅ Accepted

**Context.** We need anime titles, cover images, and episode counts for search.

**Decision.** Use the free [Jikan API](https://docs.api.jikan.moe) (an unofficial
MyAnimeList REST API) over plain `http`.

**Consequences.** No API key or OAuth needed — simplest possible integration.
Trade-off: it is rate-limited and unofficial, so search is debounced (~450ms) and
results are de-duplicated by `mal_id`.

---

## 5. `provider` for state management — ✅ Accepted

**Context.** Watchlist state must be shared across the home and search screens and
react to mutations.

**Decision.** Use a single `WatchlistProvider` (`ChangeNotifier`) via the
`provider` package, with optimistic updates and rollback on error.

**Consequences.** Minimal boilerplate and a gentle learning curve for a small app.
Trade-off: less structure than Bloc/Riverpod; acceptable at this scale and easy to
migrate later if the app grows.

---

## 6. Config via `.env`; native folders not committed — ✅ Accepted

**Context.** Supabase credentials must not be committed, and generated platform
code bloats the repo.

**Decision.** Load `SUPABASE_URL` / `SUPABASE_ANON_KEY` from a git-ignored `.env`
(via `flutter_dotenv`), shipping `.env.example` as a template. Git-ignore the
`android/`/`ios/`/etc. folders, regenerating them with `flutter create`.

**Consequences.** No secrets in version control and a lean repo. Trade-off: a small
one-time setup step after cloning (documented in [SETUP.md](../SETUP.md)), and
`.env` must exist before building since it is declared as a Flutter asset.
