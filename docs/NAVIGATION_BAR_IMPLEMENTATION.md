# Navigation Bar & Shell Layout — Implementation Guide

**Project:** LGBTinder (`lgbtindernew/`)  
**Date:** 2026-05-26  
**Status:** Specification (implementation pending)  
**References:** Klick dating app mockups + profile-shell reference (user-provided screenshots)

---

## 1. Purpose

This document defines how LGBTinder’s main shell navigation and page layout should match the reference applications, and how to **disable horizontal swipe** between main tabs.

It is the single source of truth for:

- Bottom navigation bar appearance and behavior
- Home shell layout (`HomePage`)
- Tab switching rules (tap-only, no swipe)
- Per-tab page layout patterns

**Related files (current implementation):**

| Area | File |
|------|------|
| Shell + tab host | `lib/pages/home_page.dart` |
| Bottom nav widget | `lib/core/widgets/app_bottom_nav_bar.dart` |
| Tab routes / deep links | `lib/routes/home_tab_routes.dart` |
| Scroll lock (partial swipe guard) | `lib/core/providers/home_scroll_provider.dart` |
| Icon mapping | `lib/core/utils/app_icons.dart` |
| Design system (needs update) | `UI-DESIGN-SYSTEM.md`, `Enhanced-Flutter-UI-Document.md` §3.4 |

---

## 2. Reference Analysis

Two reference patterns were provided. **Klick (image 2) is the primary target** because it matches LGBTinder’s product shape (dating app, 5 tabs, icon-only bar, pill active state on a flat dark surface).

### 2.1 Klick — Primary Target (match this)

| Element | Spec |
|---------|------|
| Bar shape | **Full-width**, flush to screen bottom (not floating) |
| Bar height | ~64px content + safe area inset |
| Bar background | Themed **surface** color (dark in dark mode) |
| Top border | 0.5px `outlineVariant` / divider — **no shadow, no elevation** |
| Items | 5 icon-only tabs, evenly spaced |
| Active item | **Capsule pill**: `primary` at **12% opacity** background |
| Active icon | Full **primary** color, 24px SVG |
| Inactive icon | `onSurface` at **40% opacity**, outline style |
| Active icon style | Bold/filled variant (optional; outline+bold swap is OK) |
| Badge | Small circular badge on relevant tab (e.g. likes count) |
| Labels | **None** — icon-only |
| Transition | `AnimatedContainer`, **220ms**, `Curves.easeOutCubic` |
| Page change | **Bottom nav tap only** — no horizontal swipe between tabs |

**Klick tab order (reference):** Discover → Shop → Likes → Messenger → Profile

**LGBTinder tab order (keep as-is):** Discover → Chat → Notifications → Profile → Settings

Do **not** reorder tabs or change routing to match Klick’s icons. Apply Klick’s **visual system** to our existing five tabs.

### 2.2 Profile App — Secondary Reference (optional Phase 2)

The first screenshot shows a **floating** dark pill bar with horizontal margin from screen edges. Differences from Klick:

| Element | Floating variant |
|---------|------------------|
| Position | Inset from left/right (~16px), lifted above bottom safe area |
| Shape | Entire bar is one rounded capsule (`borderRadius: 100`) |
| Active profile tab | Circular **avatar** instead of icon (with online dot) |
| Background | Solid dark charcoal, no top border on screen edge |

**Recommendation:** Ship Klick-style full-width bar first (already partially implemented in `AppBottomNavBar`). Consider the floating avatar bar as a future premium polish item — it requires avatar loading, online status, and different active rendering for the profile index only.

---

## 3. Current State vs Target

### 3.1 Bottom navigation bar

| Requirement | Current (`app_bottom_nav_bar.dart`) | Target |
|-------------|-------------------------------------|--------|
| Custom Row (not `BottomNavigationBar`) | ✅ Yes | Keep |
| Active pill 12% primary | ✅ Yes | Keep |
| Active icon full primary | ✅ Yes | Keep |
| Inactive icon 40% opacity | ✅ Yes | Keep |
| Capsule padding 16×6 | ✅ Yes | Keep |
| `borderRadius: 100` | ✅ Yes | Keep |
| Bar `colorScheme.surface` | ✅ Yes | Keep |
| 0.5px top border, flat | ✅ Yes | Keep |
| Animation 220ms easeOutCubic | ✅ Yes | Keep |
| Badge on tab | ✅ Chat tab (index 1) | Keep; align badge styling with reference (see §5.3) |

**Nav bar status:** Largely complete. Remaining nav polish is badge placement/color theming and updating outdated design docs (§3.4 still describes purple filled circle active state).

### 3.2 Home shell — swipe behavior (must change)

| Requirement | Current (`home_page.dart`) | Target |
|-------------|----------------------------|--------|
| Tab switching via nav tap | ✅ `_onTabTapped` + GoRouter | Keep |
| Horizontal swipe between tabs | ❌ **Enabled** via `PageScrollPhysics` | **Disable completely** |
| Scroll lock workaround | Partial — `homeVerticalScrollLockProvider` only blocks swipe on profile | Remove need for lock; swipe always off |
| Tab state preservation | ✅ `_KeepAliveTab` + `PageView` | Keep (via `PageView` or `IndexedStack`) |
| Route sync on tab change | ✅ GoRouter `context.go` | Keep |

**Critical gap:** `HomePage` comment says *"swipeable tabs"* and uses:

```dart
physics: verticalScrollLock
    ? const NeverScrollableScrollPhysics()
    : const PageScrollPhysics(parent: BouncingScrollPhysics()),
```

Reference apps do **not** allow swipe between main sections. Users change tabs only by tapping the bottom bar.

### 3.3 Page layout (per reference)

| Tab | Reference pattern | LGBTinder page | Gap |
|-----|-------------------|----------------|-----|
| Discover | Full-bleed profile card, name/age overlay, action buttons above nav | `DiscoveryPage` + card stack | Align card radius, bottom gradient, action row spacing to design system |
| Chat | Conversation list rows (avatar, name, preview, time) | `ChatListPage` | Ensure list sits flush above nav reserve; no double bottom padding |
| Notifications | List / activity feed | `NotificationsScreen` | Same list shell as messenger |
| Profile | Large centered avatar, name, grouped settings cards | `ProfilePage` | Move toward card-group layout (§6) |
| Settings | Grouped list in rounded cards | `SettingsScreen` | Same card-group pattern |

---

## 4. Disable Swipe Between Tabs

### 4.1 Requirement

- Horizontal drag on the main shell **must not** change tabs.
- Tab changes happen **only** when the user taps a bottom nav item (or via deep link / GoRouter).
- Nested scroll views (profile, chat list, discovery) must not accidentally trigger tab changes.
- Discovery card **swipe gestures** (like/pass on profile cards) must **not** be affected — only the **shell `PageView`** horizontal scroll is disabled.

### 4.2 Recommended implementation

**Option A — Minimal change (keep `PageView`):**

In `lib/pages/home_page.dart`, set physics permanently:

```dart
PageView(
  controller: _pageController,
  onPageChanged: _onPageChanged,
  physics: const NeverScrollableScrollPhysics(), // always disabled
  children: [...],
)
```

Then:

1. Remove conditional `homeVerticalScrollLockProvider` usage from `PageView` physics (provider can be deleted if unused elsewhere).
2. Keep `_pageController.animateToPage` / `jumpToPage` in `_onTabTapped` and `_syncPageControllerToRoute` for programmatic tab changes.
3. `_onPageChanged` will only fire from programmatic navigation — keep it for route sync or simplify if redundant.

**Option B — Replace `PageView` with `IndexedStack` (cleaner long-term):**

```dart
IndexedStack(
  index: currentIndex,
  children: [
    _KeepAliveTab(child: pages[0]),
    // ...
  ],
)
```

Benefits:

- Swipe is impossible by design (no `PageController` needed).
- All tabs stay mounted; `_KeepAliveTab` still useful.
- Remove `_pageChangeFromRoute`, `_syncPageControllerToRoute`, and `PageController` lifecycle.

**Recommendation:** Option B for new work; Option A is acceptable for a one-line surgical fix.

### 4.3 Tab transition animation

Reference apps use a **cross-fade or instant cut**, not a horizontal page slide, when tapping tabs.

If keeping `PageView` with `NeverScrollableScrollPhysics`:

- Use `jumpToPage(index)` instead of `animateToPage` for instant switch, **or**
- Wrap tab body in `AnimatedSwitcher` with 220ms fade to match nav pill animation.

If using `IndexedStack`:

- Wrap body in `AnimatedSwitcher(duration: 220ms, switchInCurve: Curves.easeOutCubic, ...)` keyed by `currentIndex`.

### 4.4 Files to touch (swipe disable only)

| File | Change |
|------|--------|
| `lib/pages/home_page.dart` | Disable swipe; optional IndexedStack migration |
| `lib/core/providers/home_scroll_provider.dart` | Remove if no longer referenced |
| Any profile/discovery code setting `homeVerticalScrollLockProvider` | Remove lock toggles |

### 4.5 Acceptance criteria (swipe)

- [ ] Dragging left/right on Discover does **not** open Chat.
- [ ] Dragging on Profile scroll view does **not** change tabs.
- [ ] Tapping each nav icon switches tab and updates URL (`/home` or `/home?tab=N`).
- [ ] Deep links (`/home?tab=2`) open the correct tab without swipe.
- [ ] Discovery card stack like/pass swipes still work normally.

---

## 5. Bottom Navigation Bar — Final Spec

Use this as the canonical spec (supersedes `Enhanced-Flutter-UI-Document.md` §3.4 and `UI-DESIGN-SYSTEM.md` BottomGlassNav).

### 5.1 Dimensions

```dart
static const double barHeight = 64.0;
static const double iconSize = 24.0;
static const EdgeInsets activePillPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
static const double activePillRadius = 100.0; // full capsule
```

### 5.2 Colors (theme-only — no hardcoded hex)

```dart
// Bar
color: Theme.of(context).colorScheme.surface

// Bar top border
BorderSide(
  color: Theme.of(context).colorScheme.outlineVariant,
  width: 0.5,
)

// Active pill
Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)

// Active icon
Theme.of(context).colorScheme.primary

// Inactive icon
Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.40)
```

### 5.3 Notification badge

Reference (Klick): pink/red circular badge, white text, top-right of icon.

Preserve existing `NotificationBadge` on **Chat** tab (index 1). Optional alignment tweaks:

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    AnimatedContainer(/* pill */),
    if (badgeCount > 0)
      Positioned(
        top: -2,
        right: -2,
        child: /* badge */,
      ),
  ],
)
```

Badge color: prefer `colorScheme.error` (theme) over hardcoded red.

### 5.4 Interaction

- `GestureDetector` or `InkWell` with `HitTestBehavior.opaque` on each tab slot.
- Minimum touch target: **48×48dp** (bar height 64 satisfies this).
- Optional: keep `ScaleTapFeedback` for press feedback (already present).
- Semantics: `button: true`, `selected: isActive`, label per tab for screen readers.

### 5.5 Widget structure

```
SafeArea(top: false)
└── Container(height: 64, surface bg, top border)
    └── Row(spaceAround)
        └── Expanded × 5
            └── GestureDetector(onTap)
                └── Center
                    └── Stack (badge)
                        └── AnimatedContainer (pill)
                            └── AppSvgIcon (outline inactive / bold active)
```

---

## 6. Page Layout Patterns (Reference-Aligned)

Apply these patterns inside each tab **without** changing routing.

### 6.1 Shared shell layout

```
Scaffold
└── Stack
    ├── Tab body (scrollable content)
    │   └── padding bottom = navBarReserve (64 + safeArea.bottom)
    └── Positioned(bottom: 0)
        └── AppBottomNavBar
```

Rules:

- Nav bar is **overlayed** at the bottom (current `HomePage` pattern) — content scrolls behind the reserved padding, not under the icons.
- No `Scaffold.bottomNavigationBar` — use positioned custom bar for full styling control.
- Page background: `colorScheme.background` (not hardcoded `AppColors.backgroundDark` in shell).

### 6.2 Discover tab

Reference: large rounded profile card, bottom gradient, name/age/distance, floating action buttons.

```
Column / Stack
├── AppPageHeader (optional filters)
├── Expanded
│   └── Card stack (full width, radiusLG ~16–20)
│       ├── Photo (CachedNetworkImage)
│       ├── Bottom gradient overlay
│       └── Text overlay (name, age, distance)
└── Action row (pass / superlike / like) — above nav reserve
```

### 6.3 Chat & Notifications tabs

Reference: standard messaging / activity lists.

```
CustomScrollView / ListView
├── Optional header ("Messages" / "Notifications")
└── List tiles
    ├── CircleAvatar 48–56px
    ├── Title + subtitle
    ├── Trailing time / chevron
    └── Divider or 8px gap between rows
```

### 6.4 Profile & Settings tabs

Reference (profile app): centered avatar, progress ring optional, grouped cards.

```
SingleChildScrollView
├── Header row (title left, action right)
├── Center: CircleAvatar (large, ~96px)
├── Name (titleLarge, centered)
├── Optional stat cards row (2 columns)
└── Grouped sections
    └── Card (radiusMD 16)
        └── ListTile rows with leading SVG icon + chevron
```

Section labels: `labelMedium`, `onSurface` at 60% opacity.

---

## 7. Implementation Task List

### Phase 1 — Required (navigation parity + no swipe)

| # | Task | File(s) | Priority |
|---|------|---------|----------|
| 1 | Set `PageView` physics to `NeverScrollableScrollPhysics` always | `home_page.dart` | P0 |
| 2 | Remove `homeVerticalScrollLockProvider` toggles if unused | `home_page.dart`, profile pages | P0 |
| 3 | Replace `animateToPage` slide with `jumpToPage` or `AnimatedSwitcher` fade | `home_page.dart` | P1 |
| 4 | Verify nav bar matches §5 (already mostly done) | `app_bottom_nav_bar.dart` | P0 |
| 5 | Shell background uses `colorScheme.background` | `home_page.dart` | P1 |
| 6 | Run `flutter analyze` — zero issues | — | P0 |

### Phase 2 — Layout polish (reference page structure)

| # | Task | File(s) | Priority |
|---|------|---------|----------|
| 7 | Discover card full-bleed + gradient overlay audit | `discovery_page.dart`, card widgets | P2 |
| 8 | Chat list tile spacing / avatar size audit | `chat_list_page.dart` | P2 |
| 9 | Profile grouped card sections | `profile_page.dart` | P2 |
| 10 | Settings grouped card sections | `settings_screen.dart` | P2 |
| 11 | Update `UI-DESIGN-SYSTEM.md` § BottomGlassNav → pill spec | docs | P2 |
| 12 | Update `Enhanced-Flutter-UI-Document.md` §3.4 | docs | P2 |

### Phase 3 — Optional (floating bar variant)

| # | Task | Notes |
|---|------|-------|
| 13 | Floating inset bar with `borderRadius: 100` on outer container | Horizontal margin 16, margin bottom 8 |
| 14 | Profile tab active state = `CircleAvatar` + online dot | Requires user photo + presence API |

---

## 8. Code Snippets

### 8.1 Disable swipe (minimal fix)

```dart
// lib/pages/home_page.dart — PageView
PageView(
  controller: _pageController,
  onPageChanged: _onPageChanged,
  physics: const NeverScrollableScrollPhysics(),
  children: [ /* _KeepAliveTab children */ ],
)
```

Update class doc comment from *"swipeable tabs"* to *"tap-only tabs"*.

### 8.2 IndexedStack alternative (recommended refactor)

```dart
// Replace PageView + PageController with:
body: Stack(
  fit: StackFit.expand,
  children: [
    Padding(
      padding: EdgeInsets.only(bottom: navBarReserve),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _KeepAliveTab(
            key: ValueKey('tab_$currentIndex'),
            child: pages[currentIndex],
          ),
        ),
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        notificationCount: /* ... */,
      ),
    ),
  ],
),
```

Note: `IndexedStack` preserves all tab states; `AnimatedSwitcher` with a single child only keeps one mounted unless you use a map of `_KeepAliveTab` widgets keyed by index. For full keep-alive across tabs, prefer:

```dart
IndexedStack(
  index: currentIndex,
  children: pages.map((p) => _KeepAliveTab(child: p)).toList(),
)
```

### 8.3 Tab tap handler (unchanged contract)

```dart
void _onTabTapped(int index) {
  final bounded = index.clamp(0, HomeTabRoutes.tabCount - 1);
  final target = HomeTabRoutes.locationForTab(bounded);
  if (GoRouterState.of(context).uri.toString() != target) {
    context.go(target);
  }
}
```

Routing stays in GoRouter; the shell reads `currentIndex` from `HomeTabRoutes.tabIndexFromGoState`.

---

## 9. Testing Checklist

### Navigation bar visual

- [ ] Active tab: soft pink/purple capsule (12% primary), icon full primary
- [ ] Inactive tabs: muted 40% opacity icons, no background
- [ ] Bar: flat surface color, 0.5px top border, no shadow
- [ ] Pill animates smoothly (220ms) when switching tabs
- [ ] Badge visible on Chat when unread count > 0
- [ ] Light and dark mode both correct

### Interaction

- [ ] All 5 tabs tappable with correct route update
- [ ] No horizontal swipe changes tab on any screen
- [ ] Back gesture / system back does not break tab state
- [ ] Deep link `/home?tab=3` opens Profile

### Layout

- [ ] No content hidden behind nav bar
- [ ] Scroll views extend to nav reserve padding only
- [ ] Discovery actions remain above nav bar

---

## 10. Summary

| Topic | Decision |
|-------|----------|
| Visual target | **Klick-style** full-width flat bar with capsule active pill |
| Tab order & routes | **Keep LGBTinder’s 5 tabs** — do not copy Klick’s shop/likes icons |
| Swipe between tabs | **Disable** — `NeverScrollableScrollPhysics` or `IndexedStack` |
| Nav bar code | **`AppBottomNavBar`** — already aligned; minor badge/doc updates |
| Shell host | **`HomePage`** — primary file to change for swipe disable |
| Page layout | Grouped cards + list patterns per §6; phased after P0 nav fix |

**Next step:** Implement Phase 1 task #1 (disable swipe in `home_page.dart`) — single highest-impact change matching the reference apps’ tap-only navigation.
