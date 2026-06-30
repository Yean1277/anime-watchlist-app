# Anime Watchlist App

A simple cross-platform (iOS + Android) anime watchlist built with **Flutter**,
backed by **Supabase**, with anime data from the free **Jikan API** (MyAnimeList).

## Features

- **Search** anime by title (Jikan / MyAnimeList) with cover art and episode counts.
- **Status tracking** — tag each anime as *Plan to Watch*, *Watching*, *Completed*,
  or *Dropped*, and filter by status with tabs.
- **Cloud-synced** watchlist stored in Supabase (Postgres + Row Level Security).
- **No sign-up** — anonymous auth gives each device its own private list automatically.

## Tech stack

| Layer            | Choice                                |
| ---------------- | ------------------------------------- |
| App framework    | Flutter (Dart), Material 3            |
| State management | `provider` (`ChangeNotifier`)         |
| Backend          | Supabase (`supabase_flutter`)         |
| Anime data       | Jikan API via `http`                  |
| Config           | `flutter_dotenv` (`.env`)             |

## Project layout

```
lib/
├── main.dart                  # bootstrap: dotenv, Supabase init, anon sign-in
├── theme.dart                 # Material 3 theme
├── models/                    # Anime (Jikan) + WatchlistItem / WatchStatus
├── services/                  # JikanService + WatchlistService (Supabase CRUD)
├── providers/                 # WatchlistProvider (ChangeNotifier)
├── screens/                   # WatchlistScreen + SearchScreen
└── widgets/                   # WatchlistCard + StatusChip
```

## Getting started

This repo contains only the Dart source. You generate the native platform
folders and connect Supabase locally. **See [SETUP.md](SETUP.md)** for the full
step-by-step (Supabase project, SQL schema, anonymous auth, `.env`, and run).

Quick version:

```bash
flutter create --platforms=android,ios --org com.example .
git checkout -- lib/ pubspec.yaml   # keep the repo's app code
cp .env.example .env                # then fill in your Supabase keys
flutter pub get
flutter run
```

Run the unit tests with:

```bash
flutter test
```

## Viewing the UI (web / demo mode)

Flutter also compiles to the web, so you can preview the UI in a browser
without a phone or emulator.

**Demo mode:** when no Supabase credentials are configured, the app boots into
**demo mode** — it starts with an empty watchlist, shows a banner, and lets you
search (real Jikan API) and add/edit/remove items in memory only (changes reset
on reload). This makes it easy to look at the UI before wiring up a backend.

Run it locally in a browser:

```bash
flutter create --platforms=web --org com.example .
git checkout -- lib/ pubspec.yaml
touch .env            # empty file = demo mode (it's a declared asset)
flutter pub get
flutter run -d chrome
```

**Live on GitHub Pages:** the workflow at
[`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml) builds the
web app and deploys it on every push. One-time setup: in the repo, go to
**Settings → Pages → Build and deployment → Source → GitHub Actions**. After the
workflow runs, the UI is live at
`https://<owner>.github.io/anime-watchlist-app/` (demo mode). To deploy a
backend-connected build instead, add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as
repository **Secrets** and the workflow will use them.
