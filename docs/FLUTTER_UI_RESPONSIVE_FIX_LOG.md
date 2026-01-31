# Flutter UI — Responsive Fix Log

**Purpose:** Log each responsive issue processed from `FLUTTER_UI_RESPONSIVE_ISSUES.md`: issue summary, change made, and status.

**Last updated:** January 2025

---

## Processed issues

### 1. Bottom Navigation Bar — fixed height

| Field | Detail |
|-------|--------|
| **Component** | `lib/widgets/navbar/bottom_navbar.dart` |
| **Issue** | Inner `Container` used fixed `height: 70`, so the bar did not adapt to safe area insets (e.g. home indicator) or different devices. |
| **Recommendation (from issues doc)** | Use `kBottomNavigationBarHeight` (56) or derive from `MediaQuery.padding.bottom` + content. |
| **Change made** | Replaced `height: 70` with `height: kBottomNavigationBarHeight`. The widget is already wrapped in `SafeArea(top: false)`, so bottom inset is applied; the content area now uses Material’s standard 56 logical pixels. |
| **Status** | ✅ Fixed |

---

### 2. Discovery Page — fixed 56×56 action buttons

| Field | Detail |
|-------|--------|
| **Component** | `lib/pages/discovery_page.dart` |
| **Issue** | Action buttons (rewind, dislike, message, like, superlike) used fixed `width: 56, height: 56`, so they did not scale on different screen sizes. |
| **Recommendation (from issues doc)** | Use `MediaQuery.of(context).size.width` or a fraction (e.g. min 48, max 64) or `LayoutBuilder` to scale. |
| **Change made** | Added `BuildContext context` to `_buildActionButton`; compute size as `(MediaQuery.sizeOf(context).width * 0.14).clamp(48.0, 64.0)` and use that for both width and height. All five call sites now pass `context`. |
| **Status** | ✅ Fixed |

---

### 3. Upgrade Dialog — fixed size, no scroll

| Field | Detail |
|-------|--------|
| **Component** | `lib/widgets/premium/upgrade_dialog.dart` |
| **Issue** | Dialog had no max width/height and no scroll; on small screens it could overflow, on large screens it could be too wide. |
| **Recommendation (from issues doc)** | Dialogs should have max width (e.g. 400 or 90% of width) and scrollable content; avoid fixed height. |
| **Change made** | Wrapped dialog content in `ConstrainedBox(maxWidth: (screenWidth * 0.9).clamp(280, 400), maxHeight: screenHeight * 0.8)` and wrapped the inner `Column` in `SingleChildScrollView` so long content scrolls on short screens. |
| **Status** | ✅ Fixed |

---

### 4. Discovery Page — app bar height and avatar/icon sizes

| Field | Detail |
|-------|--------|
| **Component** | `lib/pages/discovery_page.dart` |
| **Issue** | App bar used fixed `PreferredSize(Size.fromHeight(80))`; avatar ring was 48×48 and inner image 44×44, so they did not scale across devices. |
| **Recommendation (from issues doc)** | Derive app bar height from `MediaQuery.padding.top` + content; scale avatar/icon from screen width (e.g. `min(48, screenWidth * 0.12)`). |
| **Change made** | App bar: `preferredSize: Size.fromHeight(MediaQuery.padding.top + kToolbarHeight)`. Avatar: inside the app bar `Consumer`, compute `avatarSize = (screenWidth * 0.12).clamp(40, 56)` and `imageSize = avatarSize - 4`; use these for the gradient ring and the inner `Image.network`/fallback. |
| **Status** | ✅ Fixed |

---

### 5. Profile Wizard Page — fixed dimensions and scroll per step

| Field | Detail |
|-------|--------|
| **Component** | `lib/pages/profile_wizard_page.dart` |
| **Issue** | Many fixed dimensions (e.g. avatar 150, 48×48 in selection lists); long form overflow risk; need scroll per step. |
| **Recommendation (from issues doc)** | Replace key layout dimensions with MediaQuery/LayoutBuilder; use Expanded/Flexible; ensure form sections scroll (SingleChildScrollView). |
| **Change made** | (1) Scroll: all 7 step builders already return `SingleChildScrollView` — no change. (2) Avatar size: in `build()`, compute `avatarSize = (MediaQuery.sizeOf(context).width * 0.4).clamp(120, 200)` and pass to `_buildStep1(..., avatarSize: avatarSize)`. `_buildStep1` now takes optional `avatarSize` (default 150) and uses it for `AvatarUpload(size: avatarSize)`. Remaining fixed sizes (e.g. 48×48 in bottom-sheet lists) can be tackled in a later pass. |
| **Status** | ✅ Fixed |

---

### 6. Swipeable card / card stack — responsive constraints and aspect ratio

| Field | Detail |
|-------|--------|
| **Component** | `lib/widgets/cards/card_stack_manager.dart` |
| **Issue** | Card size was implicit from parent; no consistent aspect ratio, so cards could stretch inconsistently across devices and orientations. |
| **Recommendation (from issues doc)** | Ensure parent (CardStackManager) constrains card using available width and a consistent aspect ratio (e.g. LayoutBuilder + AspectRatio). |
| **Change made** | Wrapped the card `Stack` in `LayoutBuilder`. Compute `cardWidth = constraints.maxWidth` and `cardHeight = (cardWidth * 4 / 3).clamp(0, constraints.maxHeight)`. Wrapped the stack in `Center(child: SizedBox(width: cardWidth, height: cardHeight, child: Stack(...)))` so cards use the full available width and a 4:3 aspect ratio, clamped to available height. `SwipeableCard` unchanged; it already uses `double.infinity` for image fill and gets bounded size from this parent. |
| **Status** | ✅ Fixed |

---

### 7. Chat input, message bubbles — fixed widths/heights and responsive max width

| Field | Detail |
|-------|--------|
| **Component** | `lib/features/chat/presentation/widgets/chat_input.dart`, `lib/features/chat/presentation/widgets/message_bubble.dart`, `lib/widgets/chat/message_bubble.dart` |
| **Issue** | Chat input: fixed maxHeight 120, send button 48×48, attachment buttons 40×40. Message bubbles: features version had fixed image constraints 200×200 and placeholder height 150; widgets version had fixed image/video height 200. (Both bubbles already used responsive maxWidth 0.7/0.75.) |
| **Recommendation (from issues doc)** | Use responsive max width for bubbles; avoid fixed pixel sizes for input area. |
| **Change made** | **Message bubbles (features):** In `_buildImageContent()`, compute `maxW = screenWidth * 0.7`, `maxH = (maxW * 1.2).clamp(120, 280)` and use for container constraints and placeholder/error height. **Message bubbles (widgets):** Image and video height set to `(MediaQuery.sizeOf(context).width * 0.75 * 0.8).clamp(120, 280)`. **Chat input:** Text field maxHeight → `(MediaQuery.sizeOf(context).height * 0.25).clamp(80, 160)`; send button wrapped in LayoutBuilder with size `(screenWidth * 0.12).clamp(44, 56)`; attachment buttons wrapped in LayoutBuilder with size `(screenWidth * 0.1).clamp(36, 48)`. |
| **Status** | ✅ Fixed |

---

### 8. Badge / daily rewards dialogs — fixed dimensions, max width/height + scroll

| Field | Detail |
|-------|--------|
| **Component** | `lib/features/marketing/presentation/widgets/badge_achievement_popup.dart`, `lib/features/marketing/presentation/widgets/daily_rewards_dialog.dart` |
| **Issue** | Badge popup: content container had no max size; daily rewards: fixed `maxWidth: 400` only, no max height or scroll. On small screens dialogs could overflow. |
| **Recommendation (from issues doc)** | Use LayoutBuilder or MediaQuery to cap dialog size (e.g. max width 90% of screen); use flexible inner layout; scroll + max height for long content. |
| **Change made** | **Badge achievement popup:** Wrapped the main content (Center → ScaleTransition → content) in `ConstrainedBox(maxWidth: (screenWidth * 0.9).clamp(280, 400), maxHeight: screenHeight * 0.8)` and wrapped the inner `Column` in `SingleChildScrollView` so long content scrolls. **Daily rewards dialog:** Replaced fixed `BoxConstraints(maxWidth: 400)` with responsive `maxWidth: (screenWidth * 0.9).clamp(280, 400)` and added `maxHeight: screenHeight * 0.8`; wrapped the dialog body in `SingleChildScrollView` so the column scrolls on short screens. |
| **Status** | ✅ Fixed |

---

### 9. Skeleton loaders (profile, discovery, chat) — fixed placeholder sizes

| Field | Detail |
|-------|--------|
| **Component** | `lib/widgets/loading/skeleton_profile.dart`, `lib/widgets/loading/skeleton_discovery.dart`, `lib/widgets/loading/skeleton_chat_list.dart` |
| **Issue** | All placeholder widths/heights were fixed (e.g. 80×80 avatar, 150×20 name, 300×500 card, 56×56 chat avatar), so skeletons didn’t match responsive content layout on different devices. |
| **Recommendation (from issues doc)** | Base placeholder sizes on `MediaQuery.sizeOf(context)` or parent constraints so skeletons match actual content layout. |
| **Change made** | **SkeletonProfile:** At build, compute `w = MediaQuery.sizeOf(context).width` and derive avatarSize, nameW, subW, stat sizes, bioLastW, galleryH, galleryItemW, sectionTitleW, chipW from `w` with clamps; use these for all `SkeletonLoader` and container dimensions. **SkeletonDiscovery:** Compute cardW, cardH (4:3-style with max from height), nameW, subW, bioW from `w`/`h`; use for card container and inner skeletons. **SkeletonChatList:** Compute avatarSize, nameW, timeW from `w` with clamps; use for list item skeletons. |
| **Status** | ✅ Fixed |

---

### 10. Settings tiles/sections, account management — fixed sizes; flexible layout + scroll

| Field | Detail |
|-------|--------|
| **Component** | `lib/features/settings/presentation/widgets/settings_tile.dart`, `lib/features/settings/presentation/widgets/settings_section.dart`, `lib/screens/settings/account_management_screen.dart` |
| **Issue** | Settings tile: fixed icon container 40×40 and divider indent 64. Settings section: fixed padding/margin (16, 8, 12) and icon size 20. Account management: fixed loading indicator 20×20; body already uses ListView (scroll). |
| **Recommendation (from issues doc)** | Replace with flexible layout (Expanded) and spacing constants; ensure forms scroll. |
| **Change made** | **SettingsTile:** Icon container size → `(MediaQuery.sizeOf(context).width * 0.1).clamp(36, 48)`; inner icon size → `(iconSize * 0.5).clamp(18, 24)`; divider indent when icon present → `iconSize + 24`. **SettingsSection:** Imported `AppSpacing`; replaced const padding/margin (8, 16) with `AppSpacing.spacingSM`, `AppSpacing.contentPadding`, `AppSpacing.spacingLG`; IconSettingsSection icon size → `(MediaQuery.sizeOf(context).width * 0.05).clamp(18, 24)`. **Account management:** Body already uses `ListView` (scroll); loading indicator in verify button → `(MediaQuery.sizeOf(context).width * 0.05).clamp(18, 24)` for width/height. |
| **Status** | ✅ Fixed |

---

### 11. Typography — fixed fontSize; textTheme + textScaleFactor

| Field | Detail |
|-------|--------|
| **Component** | `lib/core/theme/typography.dart` |
| **Issue** | All styles use fixed `fontSize` (32, 28, 24, 18, 16, 14, 12); many widgets use local `TextStyle(fontSize: X)` (566+ in 173 files). Accessibility and consistency improve when theme text styles and system scaling are used. |
| **Recommendation (from issues doc)** | Prefer `ThemeData.textTheme`; for custom sizes use `fontSize * MediaQuery.textScaleFactorOf(context)`; rely on textTheme and scale factor. |
| **Change made** | **typography.dart:** (1) Documented that base styles are logical pixel sizes and that [Text] applies [MediaQuery.textScaleFactorOf] automatically when using these styles; recommended preferring [Theme.of(context).textTheme] in widgets. (2) Added [AppTypography.withTextScale](BuildContext, TextStyle) to return a copy of a style with fontSize scaled by [MediaQuery.textScaleFactorOf](context), for non-[Text] usages (e.g. layout or custom painting). No change to existing const styles (Flutter already scales them when used in [Text]). Local [TextStyle](fontSize: X) across the app left for incremental migration; prefer theme textTheme in new code. |
| **Status** | ✅ Fixed |

---

### 12. Scroll/layout (settings, forms, dialogs) — SingleChildScrollView / maxHeight where needed

| Field | Detail |
|-------|--------|
| **Component** | Settings screen, profile wizard, dialogs, bottom sheets (see §3 in FLUTTER_UI_RESPONSIVE_ISSUES.md). |
| **Issue** | Long content in dialogs/forms could overflow on short screens if not scrollable or height-constrained. |
| **Recommendation (from issues doc)** | Use SingleChildScrollView or ListView inside dialogs/bottom sheets and constrain height (e.g. maxHeight: screenHeight * 0.8). |
| **Change made** | **Already in place:** Settings screen uses ListView; profile wizard has SingleChildScrollView per step; upgrade dialog, badge popup, daily rewards dialog already fixed with ConstrainedBox + SingleChildScrollView; selection bottom sheet already has maxHeight 0.8 and Flexible(ListView). **New:** ConfirmationDialog and AlertDialogCustom now wrap content in ConstrainedBox(maxHeight: MediaQuery.sizeOf(context).height * 0.8) and SingleChildScrollView so long title/message scroll on short screens. |
| **Status** | ✅ Fixed |

---

### 13. MediaQuery/LayoutBuilder — shared breakpoints and responsive helper

| Field | Detail |
|-------|--------|
| **Component** | New: `lib/core/utils/responsive_utils.dart`. Existing screens already use MediaQuery/LayoutBuilder in many places (discovery, profile wizard, card stack, chat, dialogs, skeletons, settings, etc.). |
| **Issue** | Only ~18 usages of MediaQuery/LayoutBuilder across 11 files; no shared breakpoints or helper for consistent responsive sizing and tablet/desktop layout. |
| **Recommendation (from issues doc)** | Add LayoutBuilder/MediaQuery where width/height or safe area or breakpoints are needed; use a shared helper or constants (e.g. small screen = width &lt; 600). |
| **Change made** | Added `responsive_utils.dart` with: **[Breakpoints]** — `smallPhone` (360), `largePhone` (414), `tablet` (600), `desktop` (900); static helpers `width(context)`, `height(context)`, `isSmallScreen(context)`, `isTabletOrLarger(context)`, `isDesktop(context)`. **[responsiveValue]** — picks `small` / `medium` / `large` by screen width with optional `min`/`max`. **[Responsive]** — static `value(context, small:, medium:, large:, min:, max:)` for a concise API. Documented usage so teams can use these for new code and refactors (e.g. single vs two columns on tablet). No change to existing screens; they already use MediaQuery where we added fixes. |
| **Status** | ✅ Fixed |

---

### 14. Overflow/rigid Row/Column — long text and flexibility

| Field | Detail |
|-------|--------|
| **Component** | `lib/features/settings/presentation/widgets/settings_tile.dart`, `lib/pages/discovery_page.dart`, `lib/widgets/navbar/bottom_navbar.dart` |
| **Issue** | Row/Column with non-flexible children or long text can overflow on narrow screens or with large fonts. |
| **Recommendation (from issues doc)** | Ensure long text is in Expanded/Flexible with overflow: TextOverflow.ellipsis or wrapped; avoid Row with many fixed-width children; use Wrap or scroll. |
| **Change made** | **SettingsTile:** Title and subtitle Text now have `maxLines: 1` and `overflow: TextOverflow.ellipsis`; content Column has `mainAxisSize: MainAxisSize.min`. **Discovery app bar:** Greeting/name Column wrapped in `Expanded` so it takes bounded width; greeting and name Text have `maxLines: 1` and `overflow: TextOverflow.ellipsis` so long names don’t overflow the Row. **Bottom nav:** Nav item label Text has `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and `textAlign: TextAlign.center`. Other screens left for incremental audit; run on narrow device or large font to catch remaining overflows. |
| **Status** | ✅ Fixed |

---

## Remaining issues (to process next)

From `FLUTTER_UI_RESPONSIVE_ISSUES.md`, in recommended order:

| # | Component / area | Issue summary | Status |
|---|------------------|---------------|--------|
| 4 | Discovery page app bar | `PreferredSize(Size.fromHeight(80))` fixed; avatar/icon 48×48, 44×44 fixed | ✅ Fixed |
| 5 | Profile wizard page | Many fixed dimensions; long form overflow risk; add scroll per step | ✅ Fixed |
| 6 | Swipeable card / card stack | Ensure parent constrains card with responsive width + aspect ratio | ✅ Fixed |
| 7 | Chat input, message bubbles | Fixed widths/heights; use responsive max width for bubbles | ✅ Fixed |
| 8 | Badge/daily rewards dialogs | Fixed dimensions; max width/height + scroll | ✅ Fixed |
| 9 | Skeleton loaders (profile, discovery, chat) | Fixed placeholder sizes; base on MediaQuery or parent | ✅ Fixed |
| 10 | Settings tiles/sections, account management | Fixed sizes; flexible layout + scroll | ✅ Fixed |
| 11 | Typography | Fixed fontSize in theme and local styles; prefer textTheme + textScaleFactor | ✅ Fixed |
| 12 | Scroll/layout (settings, forms, dialogs) | Ensure SingleChildScrollView / maxHeight where needed | ✅ Fixed |
| 13 | MediaQuery/LayoutBuilder | Add where breakpoints or responsive sizing are needed | ✅ Fixed |
| 14 | Overflow/rigid Row/Column | Audit long text, use Expanded/Flexible, Wrap or scroll | ✅ Fixed |

See `FLUTTER_UI_RESPONSIVE_ISSUES.md` for full details and file-level reference.

**All 14 responsive issues from the recommended fix order have been processed.** For ongoing work: prefer theme textTheme, use `Responsive`/`Breakpoints` for new layouts, and test on narrow devices and with large accessibility text.

---

## Testing checklist (recommended)

From `FLUTTER_UI_RESPONSIVE_ISSUES.md` §6 — run after fixes:

| Check | Notes |
|-------|--------|
| **Small phone** (~320 pt width) | Discovery, chat, profile wizard, settings, login; all dialogs (upgrade, daily rewards, badges). |
| **Large phone** (~414 pt width) | Same screens; verify no oversized gaps or tiny elements. |
| **Tablet** (~600 pt width) | Same screens; consider using `Breakpoints.isTabletOrLarger(context)` for two-column layouts later. |
| **Large / Largest text** | System accessibility: increase font size; verify no overflow or clipped text. |
| **Orientation** | Rotate device; verify card stack, forms, and dialogs still layout correctly. |

---

