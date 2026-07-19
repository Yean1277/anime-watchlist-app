# Anime Watchlist App
## Frontend Design Specification v2.0
*宵 / YOI Design System · as-built · 2026-07-19*

> **What this is.** v2.0 documents the UI **as actually shipped** in `lib/`. It
> supersedes [v1.1](./Anime_Watchlist_Frontend_FDS_v1.1.md), which described a
> 3-tab / 5-screen plan. The product grew to **4 tabs and 7 screens**; the design
> philosophy (§1) is unchanged, everything downstream is updated to match code.
> v1.1 is kept as a historical record.

### What changed since v1.1

| Area | v1.1 | v2.0 (shipped) |
|---|---|---|
| Tabs | Library / Search / Settings (3) | Library / Discover / Stats / You (4) |
| Screens | 5 | 7 (+ Discover, + Stats; Settings → You) |
| Statuses | 4 | 5 (added **On Hold**) |
| Navigation | plain tabs | floating blurred **pill nav**, matcha-dot marker |
| Design tokens (§12) | defined | landed verbatim in `lib/theme.dart` |

---

## 1. Design Philosophy ⭐

Unchanged from v1.1. The five principles still govern every screen:

1. **Collection First** — every screen reinforces "this is *my* collection."
2. **Visual Before Data** — cover before text; never Excel, never a database.
3. **Reduce Cognitive Load** — open it and you already know how to use it.
4. **Meaningful Interaction** — not fewest steps; every step earns its place.
5. **Calm Interface** — no news, popups, ads, feed, or notifications. Quiet,
   like a private collection book.

**Product line:** *Start with one anime. Build a lifetime library.*

---

## 2. Navigation Architecture

A **floating pill nav** (`home_shell.dart` → `_PillNav`), not a standard bottom
bar:

- Four tabs, kept alive via `IndexedStack` (state survives tab switches).
- The bar floats 16px above the safe-area bottom, inset 14px each side.
- **Blur:** `BackdropFilter(sigma 12)` over `surface @ 90%` (`0xE61E2126`),
  fully rounded (`AppRadius.full`), 8% hairline border.
- `extendBody: true` so content scrolls under the translucent bar.
- **Selected marker:** a 4px **matcha dot** below the label — not an underline.
  Selected icon+label turn `accent` and bold; unselected are `textMuted`.
- Each button has a ≥44px hotzone and `Semantics(selected:)`.

| Index | Icon | Label | Screen |
|---|---|---|---|
| 0 | `collections_bookmark_rounded` | Library | `LibraryScreen` |
| 1 | `search_rounded` | Discover | `DiscoverScreen` |
| 2 | `insights_rounded` | Stats | `StatsScreen` |
| 3 | `person_rounded` | You | `ProfileScreen` |

**Pushed routes** (full-page, outside the shell, via `MaterialPageRoute`):

- **Search** — pushed from Library header `+` and the Discover search bar.
- **Detail** — pushed from any card tap (`DetailScreen.open`).

---

## 3. Screen Map

Seven screens total: four tabs + two pushed routes + the shell.

```
HomeShell (pill nav)
├─ Library   (tab)  ホーム   → Detail, Search
├─ Discover  (tab)  さがす   → Search
├─ Stats     (tab)  きろく
└─ You       (tab)  せってい
Search  (pushed)            → adds to collection
Detail  (pushed)  詳細      → edit status / progress / rating
```

| Screen | Mission | Primary action | Secondary |
|---|---|---|---|
| Library | Browse personal collection | Open anime | Add / filter by status |
| Discover | Find what's airing now | Add to list | Open Search, filter genre |
| Stats | See your tally | — (read-only) | — |
| You | Profile & account | About | — |
| Search | Find anime fast | Add | — |
| Detail | Track one show | Record next episode | Status / rating / remove |

---

## 4. Screen Anatomy

Every scrolling tab shares: `SafeArea(bottom:false)`, a `ScreenHeader`
(furigana + title + subtitle + optional actions), and 110px bottom padding so
the last row clears the floating nav.

### 4.1 Library — ホーム (`library_screen.dart`)

Component tree:

```
ScreenHeader  furigana ホーム · "Your shows" · "{n} shows · keeping count" · [+]
HeroCard      continue-watching: first "watching" show with episodes left
              (animated in/out via AnimatedSize + AnimatedSwitcher)
Filter row    horizontal FilterPills: All · Watching · Plan · Completed · On Hold · Dropped
FuriganaHeader section title + live animated count
AnimeCard[]   the filtered watchlist, one card per show
```

- **Hero logic:** surfaces the first `watching` item not yet caught up; only when
  filter = All. Tapping the ✓ records the next episode inline.
- **Entrance stagger:** first 10 cards fade+slideY in at 40ms steps, but **only**
  inside `AppMotion.entranceWindow` from the entrance start. Provider rebuilds
  and scroll-backs render static — the stagger never replays on data updates.
  Changing filter resets the window (keyed by filter) so the new list animates.
- **Pull-to-refresh** → `provider.load`.
- **Empty state:** furigana + line + "Add a show" matcha CTA (All filter only);
  other filters show a quieter "Nothing here yet."
- **Initial loading:** centered matcha `CircularProgressIndicator`, fades in.

### 4.2 Discover — さがす (`discover_screen.dart`)

Sources the current **top-airing** ranking from `JikanService.topAiring()`.

```
ScreenHeader  furigana さがす · "Discover" · "What everyone's bingeing this cour"
Search bar    tappable → pushes Search screen (not an inline field)
Genre chips   "All" + top 6 genres by frequency across the results
Spotlight     #1 show: 220px cover hero, "#1 THIS WEEK" sakura badge,
              title, score/eps/airing meta, big AddToListButton
FuriganaHeader こんしゅう · "Top this week"
rankRow[]     ranked list; ranks 1–3 in matcha, rest muted; each with AddToListButton
```

- Genre chip filters the in-memory list (`genres.contains`).
- **Loading:** centered spinner. **Error:** `cloud_off` + message, distinguishing
  rate-limit ("pull to retry in a moment") from connectivity; pull-to-refresh
  retries.
- Spotlight cover falls back to a seeded 3-way gradient if the image fails.

### 4.3 Stats — きろく (`stats_screen.dart`)

All figures computed live from the watchlist; no stored history.

```
ScreenHeader  furigana きろく · "Stats" · "Your quiet late-night tally"
StatBlock     Episodes · Shows · Hours   (hours = episodes × 24min ÷ 60)
_SeasonCard   the one matcha-gradient card: ProgressRing = completion rate
              (completed ÷ tracked), with glow
FuriganaHeader しゅうかん · "This week"
WeekChart     7-bar weekly chart — ⚠ PLACEHOLDER distribution (see §7)
FuriganaHeader じょうたい · "By status"
_StatusBreakdown  per-status bar (each status tone) + count, scaled to the max
```

### 4.4 You — せってい (`profile_screen.dart`)

```
ScreenHeader  furigana せってい · "You" · "Signed in anonymously · synced"
                                        (or "Demo mode · changes reset on reload")
_ProfileCard  sweep-gradient avatar ring, name (Anonymous/Guest),
              "{n} episodes logged" accent pill
FuriganaHeader じっせき · "Achievements"
_Achievements Wrap of tags derived from real numbers (no fake data):
              Watching n / Finished n (accent) · 50+ episodes · Century club ·
              Collector (≥10) · fallback "Just getting started"
FuriganaHeader アカウント · "Account"
_MenuCard     rows: shows tracked · episodes logged · About (→ showAboutDialog)
```

- **Dark-only by design** — there is deliberately no appearance toggle.
- Demo-mode aware (`provider.demoMode`).

### 4.5 Detail — 詳細 (`detail_screen.dart`)

Full-page editor for one show. Replaced the old bottom sheet.

```
_Hero          212px full-bleed cover, scrim into bg;
               back (scrim) + like (sakura, scrim) buttons
title / JP title / meta chips (eps · status · ★stars)
_progressCard  ProgressRing (watched / total) + "{left} to go · {pct}%"
EpisodeGrid    furigana わすう · tap a cell to set watched count
Status         WatchStatus pills — tap to change status
StarRating     furigana ひょうか · 1–5 stars (maps to 1–10 DB)
Remove         destructive rose text button → pops on remove
_RecordCta     STICKY footer: "Ep {n} watched" matcha button;
               ripple + rising "記録しました" float on tap (haptic);
               becomes "Finished — every episode watched" when complete
```

- Body is pulled up 30px (`Transform.translate`) to overlap the hero scrim.
- If the item is removed while open, the screen pops itself.

### 4.6 Search (`search_screen.dart`)

```
Back button + autofocus search field ("Search MyAnimeList…")
result rows: CoverTile · title · score/eps · AddToListButton
```

- **Debounced 450ms**, with a monotonic generation token so a slow stale
  response can never overwrite newer results.
- **Typed error states** distinguish `rateLimited` (ちょっとまって, hourglass),
  `network` / `other` (つうしんエラー, cloud-off) — each with tailored copy.
- Empty states: prompt to search (さがす) vs no-results (みつかりません).
- Add → floating snackbar `Added "{title}"`.

---

## 5. Component Catalog

Fifteen reusable widgets in `lib/widgets/`. Everything visual routes through
`theme.dart` tokens.

| Widget | Role |
|---|---|
| `screen_header` | Furigana + title + subtitle + trailing actions; every tab's top |
| `furigana_header` | Section divider: optional furigana + title + trailing (count/label) |
| `anime_card` | Library row: cover, title, status, progress |
| `hero_card` | Continue-watching card on Library; inline "watched" action |
| `cover_tile` | Cover image with seeded-gradient + kanji/initial fallback + ink scrim |
| `filter_pill` | Selectable pill (status / genre / detail-status), optional count |
| `status_pill` | Colored status label using the status tone |
| `add_to_list_button` | Add-to-collection button (compact + `big` variants) |
| `circle_icon_button` | Round icon button, optional on-cover `scrim` style |
| `pressable` | Scale-on-press wrapper; replaces Material splash app-wide |
| `progress_ring` | Circular progress; `onAccent` variant for matcha cards |
| `episode_grid` | Tap-to-fill grid of episode cells (Detail) |
| `star_rating` | 1–5 star input/display |
| `stat_block` | Row of big-number stat entries (Stats) |
| `week_chart` | 7-bar weekly chart (Stats) |

---

## 6. Design System — 宵 / YOI

Dark-only "soft Japanese" system: matcha accent on ink surfaces, big rounded
shapes, one easing curve. Fully landed in `lib/theme.dart` — never hard-code a
color, radius, or duration; route through the tokens.

**Furigana** labels are the identity mark: decorative only, never the sole
carrier of essential information, ≤3 per screen.

### 6.1 Color Tokens

| Token | Value | Use |
|---|---|---|
| **bg** 墨 sumi | `#15171A` | App background |
| **surface** 消炭 | `#1E2126` | Cards (raised `#272B31`) |
| **accent** 抹茶 matcha | `#B9D4A0` | Progress / CTAs / active state; gradient `#C9E0AE → #AFCB95` @ 160°; accent surfaces use **glow** shadow, not elevation |
| **secondary** 桜 sakura | `#E8B0B4` | New / favorite; #1 badge; like button |
| **text** 白練 | `#ECEDE8` | Primary text |
| **muted** 鼠 | `#8C918B` | Secondary text; hairlines = text @ 8% |
| **onAccent** | `#171B16` | Ink text on matcha/sakura fills |

### 6.2 Status Tones (5 statuses)

| Status | DB value | Tone | Note |
|---|---|---|---|
| Plan to Watch | `plan_to_watch` | `#8C918B` nezumi | Default on add; quiet |
| Watching | `watching` | `#B9D4A0` matcha | **Only** status using matcha — accent = active |
| Completed | `completed` | `#9FC6C2` | Muted teal |
| On Hold | `on_hold` | `#C9B98F` | Muted gold — **new in v2.0** |
| Dropped | `dropped` | `#D19A9E` | Muted rose; also the destructive / error tone |

### 6.3 Radii Scale

`8 / 12 / 18 / 26 / 34 / 999` → Episode cell / Cover / Card / Hero / Sheet / Pill.

### 6.4 Typography

- **Zen Maru Gothic** — titles and all JP/CJK ("the source of soft").
- **Outfit** — numbers and English labels only.
- Fallbacks: NotoSansTC, Inter.
- **Furigana** — 8px, `.32em` tracking, muted.

### 6.5 Motion

One curve: `cubic-bezier(0.2, 0.8, 0.2, 1)`. No bounce, no overshoot.

| Token | ms | Use |
|---|---|---|
| press | 160 | scale-on-press |
| base | 340 | entrances, size/switcher |
| bar | 550 | chart bar grow |
| ring | 800 | progress-ring sweep |
| ripple | 750 | record CTA ripple |
| float | 1000 | "記録しました" rise |
| fade | 240 | cover fade / count switch |
| staggerStep | 40 | list entrance delay (cap 10 items) |

- List stagger is first-screenful only and one-shot per entrance window.
- **reduce-motion** honored everywhere — disables all flourishes.

### 6.6 Covers

- 7 seeded two-stop gradient fallbacks, deterministic (`malId mod 7`), with a
  kanji / initial glyph.
- Every cover gets an ink scrim so mixed art reads as one system.

---

## 7. State Patterns

Consistent across screens:

- **Loading:** centered matcha `CircularProgressIndicator`, fades in
  (reduce-motion → static). *v1.1 aspired to skeletons; the shipped app uses a
  spinner — see §9.*
- **Empty:** furigana + human line + gentle next step; a matcha CTA only where
  there's a clear primary action (Library All filter).
- **Error:** `cloud_off` icon + honest, specific copy. Network vs rate-limit are
  distinguished (Search typed errors; Discover message + pull-to-retry). Never
  "Unknown error."

### Known placeholder

- **Stats → WeekChart** renders a hard-coded distribution
  (`[.34,.20,.52,.28,.88,.70,.46]`). The app tracks no per-day watch history yet;
  wire real data once watch events exist. (`TODO` in `stats_screen.dart`.)

---

## 8. Out of Scope

- Light theme — **dark-only by design** (YOI is intrinsically dark).
- Tablet / landscape layouts.
- Animation library beyond `flutter_animate` + the tokens above.
- Real per-day history for the weekly chart (deferred; see §7).
- Social / feed / notifications — excluded on principle (§1.5).
