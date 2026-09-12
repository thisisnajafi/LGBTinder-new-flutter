# Page layout system

Canonical chrome for **pushed detail pages**. Match this whenever a screen is restyled.

Visual source: other-user profile header (`PremiumHeroHeader`).
Tokens: `UI-DESIGN-SYSTEM.md` (`AppColors`, `AppSpacing`, `AppRadius`). No hardcoded colors or Material `Icons.*`.

---

## Shell

Use `PremiumDetailScaffold`.

| Part | Spec |
|------|------|
| Safe area | Full `SafeArea` on the scaffold (content never under the status bar) |
| Background | `AppColors.backgroundLight` / `backgroundDark` |
| Header | `PremiumHeroHeader` — rounded XL card, soft pink/white wash, optional blurred cover, circular glass back |
| Horizontal inset | `PremiumPageHeader.horizontalPadding` = `AppSpacing.spacingLG` (16) |
| Body | Scrollable list of white/surface cards |

Page titles use `PremiumPageHeader` (title + subtitle + action inside `PremiumHeroHeader`).
Chat uses `ChatHeader`. Profile uses `ProfileHeroSection`. All three share the same card.

---

## Tab screens (Messenger, Settings, Notifications)

Use `PremiumTabPageLayout` instead of `PremiumDetailScaffold`.

- Top: SafeArea / `viewPadding.top` so the title is never under the clock
- Bottom: **no** extra SafeArea — Home already reserves the floating nav
- Header: same `PremiumHeroHeader` card as Chat info / profile
- Profile tab: `showTitleHeader: false` — `ProfileHeroSection` is the header
- Pull-to-refresh: `PremiumRefreshIndicator` (grey circle, violet spinner). Pass `onRefresh` on `PremiumTabPageLayout` / `PremiumDetailScaffold` for any screen that loads remote data.

---


## Cards

`PremiumShell` (`margin: EdgeInsets.zero` inside the padded list).

- Fill: `cardBackgroundLight` / `cardBackgroundDark`
- Radius: `AppRadius.radiusXL` (32)
- Border: violet at 8–12% opacity
- Shadow: light, blur 6, y-offset 2
- Inner padding: `AppSpacing.spacingLG` (16)
- Vertical gap between cards: `AppSpacing.spacingLG` (16)

---

## Section titles

`PremiumSectionHeader`

- 4×36 vertical gradient bar on the left (`brandGradient`)
- Title: `titleMedium`, weight 800
- Optional subtitle: `bodySmall`, secondary text

---

## Settings rows

`PremiumSettingsGroup` + `PremiumSettingsTile`

- 40px circular icon well, accent at 12% fill
- Title + optional subtitle
- Trailing chevron unless the row is informational (`trailing: SizedBox.shrink()`)

Primary CTA: `GradientButton` (pink–purple), SVG icon via `AppIcons`.

---

## Checklist for the next page

1. Wrap with `PremiumDetailScaffold` (safe area + `PremiumHeroHeader`)
2. Body is a padded `ListView` / `CustomScrollView` of `PremiumShell` cards
3. Section titles use `PremiumSectionHeader`
4. Keep content **on-topic for that screen** (do not copy another feature’s sections)
5. Save a short screen spec under `lgbtindernew/docs/`
