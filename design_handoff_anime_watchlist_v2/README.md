# Handoff: Anime Watchlist v2 — Collection-First Redesign (FDS v1.1)

## Overview
A redesign of the Flutter anime watchlist app (`Yean1277/anime-watchlist-app`) following Frontend Design Specification v1.1. The redesign pivots from an episode-tracking dashboard to a **collection-first, calm interface**: 3 tabs (Library, Search, Settings), cover-first grid cards, and a confirm-before-adding flow (Search → Detail → Choose Status → card enters collection).

## About the Design Files
The files in this bundle are **design references created in HTML** — an interactive prototype showing intended look and behavior, not production code to copy directly. The task is to **recreate this design in the existing Flutter codebase** (`Yean1277/anime-watchlist-app`), reusing its established patterns: `theme.dart` tokens (`AppColor` / `AppRadius` / `AppText` / `AppMotion`), `WatchlistProvider`, `JikanService`, `WatchlistRepository`, and existing widgets where they fit (`Pressable`, `CoverTile`, `StatusPill`, `FilterPill`, `CircleIconButton`).

The FDS itself is included as `Anime_Watchlist_Frontend_FDS_v1.1.md` — it is the authoritative statement of intent; this README maps it to concrete measurements from the prototype.

## Fidelity
**High-fidelity.** Colors, typography, spacing, radii, and motion are final and match the existing YOI design system tokens already in `theme.dart`. Recreate pixel-perfectly. All measurements below are in logical px at a 390×844 viewport.

## Navigation Architecture (change from v1.0)
- **3 tabs**: Library / Search / Settings (was 4: Library / Discover / Stats / You).
- Discover and Stats screens are **removed**. Search is promoted from a pushed route to a tab.
- Floating pill nav (unchanged pattern): bottom inset 16, side insets 14, `borderRadius: 999`, bg `#1E2126` at 90% + blur 12, 1px hairline `rgba(236,237,232,0.08)`, padding `11px 8px`. Each item: icon 22px, label 11px, 4px active dot in matcha; inactive `#8C918B`, active `#B9D4A0` w700. Min hit target 64×44.

## Screens

### 1. Authentication (new screen)
- Purpose: first-open entry; anonymous auth. One action only.
- Centered column, horizontal padding 36, text-align center:
  - App mark: 76×76, radius 26, matcha gradient `#C9E0AE → #AFCB95` at 160°, glow shadow `0 22px 44px -20px rgba(185,212,160,0.5)`, 宵 glyph 34px w900 ink `#171B16`.
  - Furigana よい: 8–9px, letter-spacing .32em, `#8C918B`, margin-top 28.
  - Tagline, 24px w900 Zen Maru, line-height 1.35: "Start with one anime." in `#ECEDE8`, "Build a lifetime library." in `#8C918B` (second line muted).
  - Support copy 11px `#8C918B`: "No account needed. Your collection stays private on this device, synced quietly."
  - CTA "Continue": full-width pill, padding 15, bg `#B9D4A0`, glow `0 14px 30px -16px rgba(185,212,160,0.7)`, label 14px w700 `#171B16`.
- Behavior: taps into Supabase anonymous sign-in, then replaces route with HomeShell. Skip this screen when a session already exists.

### 2. Library (tab 1) — ほんだな
- Header: padding `18px 20px 4px`. Furigana ほんだな (8px, .32em, `#8C918B`), title "Library" 24px w900 `#ECEDE8`, summary line 11px `#8C918B`: "N in your collection · M watching".
- **Anime Grid**: 2 columns, gap 14, padding `16px 20px`, bottom padding 110 (behind floating nav).
- **Collection Card** (the core component — Cover → Title → Status, nothing else):
  - Cover: aspect-ratio 3:4, radius 12, fallback = seeded gradient (`malId mod 7`, existing `CoverTile` gradients) + centered kanji/initial glyph 44px w900 at 90% white, plus a **35% ink scrim** (`rgba(21,23,26,0.35)`) over all art.
  - Status pill overlaid bottom-left of the cover: inset 8, padding `4px 9px`, radius 999, bg `rgba(21,23,26,0.65)` + blur 6, label 9px w500 letter-spacing 0.5 in the status tone.
  - Title below: 13px w700 `#ECEDE8`, line-height 1.4, 2-line clamp, margin-top 9.
  - No description, genre, studio, synopsis, or progress bar on cards.
- **FAB**: 56×56 matcha circle, bottom-right (right 18, bottom 104 — above the nav), ink + icon, glow shadow. Tap → switch to Search tab.
- **States**:
  - Loading: skeleton grid (6 cells) — cover block + 2 text lines in `#1E2126`, 1.4s opacity shimmer (0.5→1→0.5), 90ms per-cell delay stagger.
  - Empty: centered — 64×64 radius-18 surface tile with 宵, furigana からっぽ, "Your collection is empty." 15px w700, "Start with your first anime." 11px muted, one matcha pill CTA "Find your first anime" → Search tab.
  - Error: furigana つうしんエラー, "Couldn't load your library." 15px w700, one surface pill button "Retry" (label in matcha).

### 3. Search (tab 2) — さがす
- Header like Library ("Search", さがす).
- Search field: radius 18, bg `#1E2126`, hairline border, search icon 18px, input 14px, placeholder "Search anime…". Debounce 450ms; discard stale responses (keep the existing generation-token pattern).
- Results: same 2-col cover grid as Library. Result card = cover + title + meta line 10px `#8C918B` ("★ 8.6 · 12 eps"). Shows already in the collection get a 26px matcha ✓ disc at the cover's top-right.
- Idle state shows the top-airing set (from `JikanService`) so covers appear immediately; typing filters/searches.
- No-results state: みつかりません, `No results for "query"`, "Try a different word."
- Tap any card → Anime Detail.

### 4. Anime Detail (pushed route)
- Mission: **confirm before adding**. Primary = Add to Collection; secondary = Change Status.
- Cover hero: height 300, cover art (or gradient fallback with 88px glyph at 30%), scrim `rgba(21,23,26,0.15) 30% → #15171A 100%`. Back button: 40×40 blurred disc top-left.
- Body overlaps hero by −36. If owned: "IN YOUR COLLECTION" badge (10px w500, matcha on `rgba(185,212,160,0.14)` pill) above the title.
- Title 22px w900; JP subtitle 11px muted; meta as hairline chips 10px (`N eps`, `★ score`, `Airing/Finished`, current status).
- **Not in collection**: sticky footer CTA (hairline top border, padding `12px 20px`): full-width matcha pill "Add to Collection" → opens the **status sheet**.
- **Status sheet** (bottom sheet, the one modal in the app): radius `34 34 0 0`, bg `#1E2126`, grab handle 36×4, furigana じょうたいをえらぶ, title "Choose a status" 16px w900. Five rows (radius 18, bg `#272B31`, hairline): 10px status-tone dot + label 14px w700; Plan to Watch marked "default". Slide-up 340ms on the base curve. Choosing a status adds the item, closes the sheet, pops to Library.
- **Add motion (FDS §11)**: the new card enters the grid with `cardIn` — opacity 0→1, scale 0.92→1, translateY 10→0, 340ms `cubic-bezier(0.2, 0.8, 0.2, 1)`. This is the only celebratory animation in the app.
- **In collection**: Status section (じょうたい) with the five statuses as filter pills (selected: matcha bg, ink text, w700; unselected: surface + hairline, muted); "Remove from collection" as a quiet rose (`#D19A9E`) text row with trash icon, centered.

### 5. Settings (tab 3) — せってい
- Header "Settings", subtitle "Signed in anonymously · synced" (or the demo-mode line).
- Profile card: radius 26 surface; 56px avatar with 2px sweep-gradient ring (`#6E8F73 → #B9D4A0 → #E8B0B4`); "Anonymous user" 16px w900; matcha badge pill "N in collection".
- Account list card (radius 18, hairline dividers inset 52): "N shows collected", "M watching now", "About" (chevron → version + MAL/Jikan attribution dialog).
- Footer line 10px muted: "宵 / YOI · v1.1 · data from MyAnimeList via Jikan".

## Interactions & Behavior
- Add flow: Search → tap card → Detail → "Add to Collection" → status sheet → pop to Library with card entrance. No confirmation popups.
- Status changes and removal are immediate + optimistic (existing provider pattern).
- Press feedback: existing `Pressable` scale (160ms).
- All list/grid entrances: 40ms stagger, capped at 10, first screenful only.
- `reduce-motion`: disable shimmer stagger, card entrance, sheet slide (fade instead).

## State Management
- Reuse `WatchlistProvider`; watchlist item still `{malId, title, titleJapanese, episodes, episodesWatched, score, status}` — episode/score fields are retained in data but **not surfaced in this UI phase** (FDS keeps the UI collection-first; tracking UI may return later).
- New UI state: active tab (3), search query + debounce generation, detail source (owned item vs. Jikan result), sheet visibility, `newId` for the entrance animation (clear after ~600ms).
- Library load states: loading / error / empty / content, driven by the repository fetch.

## Design Tokens (YOI — already in theme.dart)
- bg 墨 `#15171A` · surface 消炭 `#1E2126` · raised `#272B31`
- accent 抹茶 `#B9D4A0` (gradient `#C9E0AE → #AFCB95` @160°; glow shadows instead of elevation) · secondary 桜 `#E8B0B4`
- text 白練 `#ECEDE8` · muted 鼠 `#8C918B` · hairline = text @ 8%
- Status tones: plan `#8C918B` · watching `#B9D4A0` · completed `#9FC6C2` · on-hold `#C9B98F` · dropped `#D19A9E` (dropped doubles as destructive/error)
- Radii: 8 / 12 / 18 / 26 / 34 / 999 (episode cell / cover / card / hero / sheet / pill)
- Type: Zen Maru Gothic (titles + all JP/CJK) · Outfit (numbers + English labels) · furigana 8px @ .32em, ≤3 per screen, decorative only
- Motion: one curve `cubic-bezier(0.2, 0.8, 0.2, 1)`; press 160 · base 340 · bar 550 · ring 800 · float 1000 ms; no bounce/overshoot

## Assets
No bitmap assets. Covers come from Jikan image URLs with the seeded-gradient + glyph fallback (already implemented in `CoverTile`). Icons are simple 2px-stroke line icons (Flutter: use existing icon set styled to match). Fonts via google_fonts: Zen Maru Gothic, Outfit.

## Files
- `Anime Watchlist v2.dc.html` — the interactive hi-fi prototype (all 5 screens, all states; open in a browser). Tweakable flags inside: `startEmpty`, `uiState` (normal/loading/error), `showFurigana`.
- `Anime_Watchlist_Frontend_FDS_v1.1.md` — the governing spec.
