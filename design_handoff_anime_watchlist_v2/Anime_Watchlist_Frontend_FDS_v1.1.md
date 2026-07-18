# Anime Watchlist App
## Frontend Design Specification v1.1
*整合 宵 / YOI Design System · 2026-07-18*

---

## 1. Design Philosophy ⭐⭐⭐⭐⭐

这是整份 FDS 最重要的一页。
如果只有一页，就是这一页。

**Product Philosophy**

> Start with one anime.
> Build a lifetime library.

**Frontend Philosophy** — 五条原则：

### Principle 1 · Collection First
每一个 Screen 都应该强化："这是我的 Collection。"

### Principle 2 · Visual Before Data
不要像 Excel。不要像 Database。
用户应该先看到 Cover，不是文字。

### Principle 3 · Reduce Cognitive Load
用户不用思考。不用学习。打开就知道怎么用。

### Principle 4 · Meaningful Interaction
不是：越少步骤越好。
而是：每一步都有意义。

例如：
Search → 看到 Cover → Tap Add → 加入 Collection
这个过程本身就是体验。

### Principle 5 · Calm Interface
不要：News / Popup / Ads / Community Feed / Notifications。
你的 App 应该很安静，像一本私人收藏册。

---

## 2. Navigation Architecture

目前：

```
Library
Search
Settings
```

只有三个 Tab。
因为：越少越容易建立习惯。

---

## 3. Screen Architecture

目前只有五个 Screen：

```
Authentication
Library
Search
Anime Detail
Settings
```

以后再增加。

---

## 4. Screen Priority

| Screen | Mission | Primary Action | Secondary |
|---|---|---|---|
| Library | Browse personal collection | Open Anime | Add Anime |
| Search | Find anime quickly | Search | View Detail |
| Anime Detail | Confirm before adding | Add to Collection | Change Status |

---

## 5. Component Architecture

Flutter 最重要的部分。

Library：

```
Library Screen
↓ AppBar
↓ Library Summary
↓ Anime Grid
↓ Anime Card
↓ Floating Action Button
```

以后 Flutter Component 完全对应。

---

## 6. Component Philosophy

例如：Anime Card。
不是 Information Card，而是 **Collection Card**。

Priority：

```
Cover
↓ Title
↓ Status
```

不要：Description / Genre / Studio / Synopsis。
全部抢视觉。

---

## 7. Interaction Design

例如：Add Anime。

Flow：

```
Search
↓ Select Anime
↓ Choose Status
↓ Collection Updated
```

不要：Popup × 4。

---

## 8. Empty State

第一次打开：

> Your collection is empty.
> Start with your first anime.

一个按钮。结束。

---

## 9. Loading State

不要：Loading...
最好：Skeleton。
让用户感觉：Library 已经在那里。

---

## 10. Error State

不要：Unknown Error.
而是：

> Couldn't load your library.
> **Retry**

结束。

---

## 11. Motion Design

原则：不要很多 Animation。

但是 Add Anime：
Card 轻轻进入 Grid。
用户会感觉：我真的收藏了一部作品。
不是：数据库新增了一笔数据。

---

## 12. Design System — 宵 / YOI

Dark-only「soft Japanese」系统：
matcha accent on ink surfaces，大圆角，一条 easing curve。

Furigana labels 是识别标志 — decorative only，
不能是唯一的意义载体，每个 Screen ≤ 3 个。

### 12.1 Color Tokens

| Token | Value | Use |
|---|---|---|
| **bg** 墨 sumi | `#15171A` | App background |
| **surface** 消炭 | `#1E2126` | Cards；raised variant `#272B31` |
| **accent** 抹茶 matcha | `#B9D4A0` | Progress / CTAs / active states；gradient `#C9E0AE → #AFCB95` at 160°；accent surfaces 用 glow shadow 取代 elevation |
| **secondary** 桜 sakura | `#E8B0B4` | New / favorite accents；Sunday bar；#1 badge |
| **text** 白練 | `#ECEDE8` | Primary text |
| **muted** 鼠 | `#8C918B` | Secondary text；hairlines = text at 8% |

### 12.2 Status Tones

| Status | DB value | Tone | 说明 |
|---|---|---|---|
| Plan to Watch | `plan_to_watch` | `#8C918B` | Default on add；安静的 nezumi 灰 |
| Watching | `watching` | `#B9D4A0` | 唯一使用 matcha 的 status — accent 保留给 active state |
| Completed | `completed` | `#9FC6C2` | Muted teal |
| On Hold | `on_hold` | `#C9B98F` | Muted gold |
| Dropped | `dropped` | `#D19A9E` | Muted rose；同时也是 destructive / error tone |

### 12.3 Radii Scale

`8 / 12 / 18 / 26 / 34 / 999`

对应：Episode cell / Cover / Card / Hero / Sheet / Pill。

### 12.4 Typography

- **Zen Maru Gothic**：titles 和所有 JP / CJK 文字
- **Outfit**：numbers 和 English labels
- **Furigana**：8 px，`.32em` tracking

### 12.5 Motion

一条 curve：`cubic-bezier(0.2, 0.8, 0.2, 1)`

| Duration | ms |
|---|---|
| press | 160 |
| base | 340 |
| bar | 550 |
| ring | 800 |
| float | 1000 |

- List stagger：40 ms，capped at 10 items
- No bounce，no overshoot
- **reduce-motion** honored everywhere：disable 所有 flourishes

### 12.6 Covers

- 7 个 seeded gradients：deterministic（`malId mod 7`）two-stop fallback tile + kanji / initial glyph
- 每张 cover 加 35% ink scrim，让混合 art 视觉统一

### 12.7 Design System 原则（保留自 v1.0）

先定义原则，Token 已经落地：
Spacing Scale / Typography Scale / Corner Radius / Elevation / Icon Style / Image Ratio
— 以上除 Spacing 和 Image Ratio 外，已由 YOI tokens 定义；剩余两项待补。

---

## 13. Out of Scope

目前不讨论：

- ~~Dark Theme~~ → 已确定 **dark-only by design**（YOI 系统本身就是 dark-only）
- Light Theme（以后）
- Tablet
- Landscape
- Animation Library

以后。
