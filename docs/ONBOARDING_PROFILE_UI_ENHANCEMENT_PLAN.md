# LGBTFinder — Onboarding & Profile UI Enhancement Plan

> Phase 0 immersion audit + Phase 1 design plan.  
> Implementation order: OB-DESIGN-001 → … → OB-DESIGN-006, then PR-DESIGN-001 → … → PR-DESIGN-010.

---

## Design Immersion Report

### Design System Tokens Found

- **Primary color:** `AppColors.accentRose` / `primaryLight` — `#F43F5E` (rose-500); legacy alias `accentPurple` / `accentViolet` — `#8B5CF6`
- **Secondary / accent color:** `accentPink` — `#EC4899`; `secondaryLight` — `#8B5CF6`; brand gradient `rose → violet` via `AppColors.brandGradient` and `AppTheme.accentGradient` (`#7C3AED → #EC4899`)
- **Background color (light):** `AppColors.backgroundLight` — `#FFFFFF`; surfaces `#FAFAFA` / `#FFFFFF`
- **Background color (dark):** `AppColors.backgroundDark` — `#18181B`; surfaces `#27272A` / `#3F3F46`
- **Text styles defined:** `h1Large`, `h1`, `h2`, `h3`, `h4`, `bodyLarge`, `body`, `bodySmall`, `caption`, `button`, `labelMedium`, `displayScript` (mapped to `textTheme.displayLarge/Medium/Small`, `headlineMedium`, `bodyLarge/Medium/Small`, `labelLarge`)
- **Border radii defined:** `radiusXS` 6, `radiusSM` 12, `radiusMD` 16, `radiusLG` 24, `radiusXL` 32, `radiusRound` 999
- **Animation durations defined:** `AppAnimations.tapDuration` 130ms, `transitionPage` 300ms, `transitionModal` 250ms, `listItemStagger` 50ms, `feedbackShort` 180ms, `cardExit` 200ms, `listItemAppear` 200ms, `shimmerDuration` 1400ms, `snackbarTransition` 200ms *(design docs also specify micro 150ms, small 260ms, medium 400ms, large 700ms, match 900ms — not all wired in code)*
- **Shadow styles defined:** Documented in `UI-DESIGN-SYSTEM.md` as `shadowSurfaceDark/Light`, `shadowFloatingDark/Light` — **not extracted as reusable constants in `app_theme.dart`**; ad-hoc `BoxShadow` in widgets only
- **Fonts in use:** **Inter** (primary, in theme), **Nunito**, **Urbanist**, **Poppins** (all in `pubspec.yaml`)

### SVG Assets Available

**896 icons** in `assets/icons/outline/` (+ bold, linear, twotone, bulk, broken — ~6,900 total). Relevant to onboarding/profile:

| Category | Icon names |
|----------|------------|
| **Onboarding / welcome** | `heart`, `discover`, `message`, `people`, `calendar`, `location`, `tag`, `crown`, `award`, `flag`, `verify`, `tick-circle`, `arrow-right`, `arrow-left`, `close-circle` |
| **Profile / identity** | `user`, `edit`, `camera`, `gallery`, `gallery-add`, `verify`, `shield`, `lock`, `unlock` |
| **Info pills** | `location`, `map`, `global`, `briefcase`, `book`, `weight`, `music` |
| **Actions** | `like`, `dislike`, `star`, `message`, `notification`, `setting` |
| **Tier / premium** | `crown`, `star`, `award` |

Legacy duplicate set also exists at `assets/images/icons/`.

### Illustration / Image Assets Available

| Asset | Status |
|-------|--------|
| `assets/images/logo/logo.png` | Present |
| `assets/logo/logo.png` | Present |
| `assets/images/chat/chat-dark.png`, `chat-light.png` | Present |
| `assets/images/onboarding/slide_1–4.png` | **Missing** — only `PROMPT_2x2_ONBOARDING.md` |
| `assets/lottie/` | **Not present** |
| Pride / LGBT gradient | Code-only via `AppColors.prideGradient` |

### Animation Packages Available

**lottie**, **animations**, **confetti**, **smooth_page_indicator**, **flutter_svg**, **cached_network_image**, **photo_view**. Custom `SkeletonLoader` / `SkeletonProfile` (no dedicated shimmer package).

---

### Onboarding — Current State Analysis

- **Number of onboarding steps:**
  - Intro carousel (first launch): **4 steps** — `lib/pages/onboarding_page.dart`
  - Post-auth profile wizard: **7 steps** — `lib/pages/profile_wizard_page.dart`
  - Preferences screen: **1 long form** — `lib/screens/onboarding/onboarding_preferences_screen.dart`

- **Route sequence (exact):**
  1. `/` Splash
  2. First launch → `/onboarding` (4 slides) → `/welcome`
  3. Returning, no token → `/welcome`
  4. Valid token → `/home`
  5. Welcome → `/register` or `/login`
  6. Register/login → `/email-verification` (if needed) → `/profile-wizard` → `/home`

- **Visual problems:** Missing onboarding PNGs; Material Icons fallbacks; splash uses generic spinner; welcome disables animations in debug; no profile mosaic grid; wizard progress is plain bars.

- **Interaction problems:** No haptics on steps; preferences uses `MaterialPageRoute` instead of go_router; skip has no confirmation.

- **Missing delight:** No confetti on completion; no personalized wizard; no animated splash → intro handoff.

---

### Profile Page — Current State Analysis

- **Screens:** `profile_page.dart` (own + other), `screens/discovery/profile_detail_screen.dart`, `profile_card.dart`, `profile_edit_page.dart`, `profile_wizard_page.dart`
- **Layout:** Vertical scroll stack — not carousel + draggable sheet per spec
- **Visual problems:** Material Icons in header/badges; grid not carousel; raw interest IDs on own profile; generic Premium badge (no basid/silder/golden)
- **Missing vs premium apps:** Photo count, distance, completeness arc, tier badges, shared-interest highlight, full image viewer

---

## UI Enhancement Plan

### ONBOARDING ENHANCEMENTS

#### OB-DESIGN-001: Welcome / Splash Screen
- **Current state:** Splash = pride gradient + logo + spinner. Welcome = gradient + logo glow + CTAs; no mosaic grid.
- **Problem:** Splash feels like loading, not brand. Welcome missing spec mosaic hero.
- **Enhancement:** Splash logo scale-in + arc progress ring (`accentRose`). Welcome profile mosaic grid + glass tagline card + polished CTAs.
- **Animation:** Splash 400ms easeOutCubic; welcome grid stagger 80ms; logo 800ms; buttons 500ms fade-up.

#### OB-DESIGN-002: Step Progress Indicator
- **Enhancement:** Reusable `OnboardingProgressIndicator` — segmented pill + "Step X of Y".

#### OB-DESIGN-003: Step Transition Animations
- **Enhancement:** Shared-axis horizontal slide + crossfade, 300ms.

#### OB-DESIGN-004: Each Onboarding Step
- **004a–004d:** Intro slides 1–4 — SVG heroes, confetti on final CTA
- **004e–004k:** Wizard steps 1–7 — photos, info, about, preferences, interests, extra photos, summary preview
- **004l:** Preferences screen — section cards, go_router navigation

#### OB-DESIGN-005: Completion / Celebration Screen
- **Enhancement:** Confetti overlay + profile preview + "Start Discovering" CTA after wizard.

#### OB-DESIGN-006: Micro-interactions & Delight
- **Enhancement:** Haptics, skip bottom sheet, validation shake, auto-scroll to errors.

---

### PROFILE PAGE ENHANCEMENTS

#### PR-DESIGN-001: Profile Photo Section
- Full-width carousel, dots, gradient overlay, photo count, PhotoView gallery, parallax.

#### PR-DESIGN-002: Name, Age, Verification & Tier Badge
- Overlay on photos; `TierBadge` (basid/silder/golden); SVG location icon.

#### PR-DESIGN-003: Bio Section
- Collapsible bio with read-more; quote accent border.

#### PR-DESIGN-004: Info Pills
- `ProfileInfoPill` with SVG icons; grouped sections.

#### PR-DESIGN-005: Interests / Tags Section
- Resolved titles; shared-interest gradient highlight.

#### PR-DESIGN-006: Action Buttons
- Sticky frosted bar; four circular actions; press scale + like burst.

#### PR-DESIGN-007: Own Profile — Edit Mode
- Floating Edit CTA; completeness tips inline.

#### PR-DESIGN-008: Profile Completeness Indicator
- Circular arc + checklist bottom sheet.

#### PR-DESIGN-009: Premium Tier Visual Treatment
- `TierBadge` from `userTierProvider`; locked section overlays for basid.

#### PR-DESIGN-010: Empty States & Loading States
- Section skeletons; empty photo CTA; themed errors.

---

## Implementation Status

| ID | Task | Status |
|----|------|--------|
| OB-DESIGN-001 | Welcome / Splash Screen | ✅ Complete |
| OB-DESIGN-002 | Step Progress Indicator | ✅ Complete |
| OB-DESIGN-003 | Step Transition Animations | ✅ Complete |
| OB-DESIGN-004 | Each Onboarding Step | ✅ Complete (intro + wizard wiring; wizard step bodies retain existing forms) |
| OB-DESIGN-005 | Completion / Celebration | ✅ Complete |
| OB-DESIGN-006 | Micro-interactions | ✅ Complete (haptics, skip sheet, chip feedback) |
| PR-DESIGN-001 | Profile Photo Section | ✅ Complete |
| PR-DESIGN-002 | Name / Tier Badge | ✅ Complete |
| PR-DESIGN-003 | Bio Section | ✅ Complete |
| PR-DESIGN-004 | Info Pills | ✅ Complete |
| PR-DESIGN-005 | Interests / Tags | ✅ Complete (shared-interest highlight widget; wire `sharedInterests` when API provides) |
| PR-DESIGN-006 | Action Buttons | ✅ Complete |
| PR-DESIGN-007 | Edit Mode | ✅ Complete (floating edit FAB) |
| PR-DESIGN-008 | Completeness Indicator | ✅ Complete (local estimate from profile fields) |
| PR-DESIGN-009 | Tier Visual Treatment | ⚠️ Partial (TierBadge + overlay header; basid upsell lock overlays not added) |
| PR-DESIGN-010 | Empty / Loading States | ✅ Complete (carousel skeleton + empty photo state) |

### Key files created

- `lib/core/widgets/splash_arc_loader.dart`
- `lib/core/utils/app_haptics.dart`
- `lib/features/onboarding/widgets/` — progress indicator, intro hero, celebration, skip sheet, welcome mosaic/glass card
- `lib/features/profile/widgets/` — photo carousel, tier badge, info pill, completeness indicator, interest chips

### Key files modified

- `lib/pages/splash_page.dart`, `lib/screens/auth/welcome_screen.dart`
- `lib/pages/onboarding_page.dart`, `lib/pages/profile_wizard_page.dart`
- `lib/screens/onboarding/onboarding_preferences_screen.dart`
- `lib/pages/profile_page.dart`, `lib/screens/discovery/profile_detail_screen.dart`
- `lib/widgets/profile/` — bio, info sections, action buttons, skeleton
- `lib/widgets/badges/` — verification, premium

### QA (modified UI scope)

`flutter analyze` on touched onboarding/profile files: **0 errors** (project-wide analyze may still report pre-existing issues in unrelated modules).

---

**Approved:** `approve all` — implementation complete per plan above.
