# Other-user profile — layout & design spec

**Screen:** Other person's public profile  
**Route / widget:** `ProfileDetailScreen` → `OtherUserProfileView`  
**Files:**

- `lib/screens/discovery/profile_detail_screen.dart`
- `lib/features/profile/presentation/widgets/other_user_profile/other_user_profile_view.dart`
- `lib/features/profile/presentation/widgets/own_profile/profile_hero_section.dart` (`viewerMode: true`)
- `lib/features/profile/presentation/widgets/other_user_profile/other_user_profile_sections.dart`

Opened from chat / messenger “View profile”, likes, and discovery. This is **not** the owner Profile tab and **not** the profile editor.

Tokens must come from `UI-DESIGN-SYSTEM.md` (`AppColors`, `AppSpacing`, `AppRadius`). Do not hardcode new colors.

---

## Safe area (required)

This screen is a pushed detail page. It must **not** draw under the status bar.

| Rule | Value |
|------|--------|
| Top | `SafeArea(top: true)` on `ProfileDetailScreen` |
| Bottom | `SafeArea(bottom: false)` — the scroll view already adds `MediaQuery.padding.bottom` |
| Back button | 40×40 circle, below the status bar, never overlapping the clock |
| Horizontal | `AppSpacing.spacingLG` (16) on the hero card |

The hero card is inset inside the safe zone. It is a rounded card (`AppRadius.radiusXL`), not a full-bleed edge-to-edge photo under the status bar.

---

## Page structure (top → bottom)

```
SafeArea
└── CustomScrollView (bounce + pull-to-refresh)
    ├── ProfileHeroSection (viewerMode)
    ├── gap AppSpacing.spacingXL (24)
    ├── Compatibility card
    ├── gap 24
    ├── Gallery card
    ├── gap 24
    ├── About (bio + conversation starters, if any)
    ├── About them (detail chips, if any)
    ├── Shared interests (if any)
    └── bottom spacer: spacingXXL + home-indicator inset
```

Background: `Theme.scaffoldBackgroundColor`  
Light: `AppColors.backgroundLight` (`#F8F9FA`) with a soft pink wash behind the hero.  
Dark: `AppColors.backgroundDark`.

---

## 1. Hero card

Rounded container (`radiusXL` = 32), light drop shadow, clipped.

### 1.1 Back

- 40×40 circular hit target (min 44 with padding)
- Fill: black 35% opacity
- Icon: `AppIcons.arrowLeft`, white, 20px
- Semantics: `Back`
- Action: `Navigator.maybePop`

### 1.2 Photo carousel

- Square photo, width ≈ 28% of screen, clamped **104–132**
- Outer gradient ring: `accentGradientStart` → `accentPink` → `feedbackInfo`
- Inner radius: `AppRadius.radiusLG` (24)
- Verified: 28px circle, brand gradient, tick icon, bottom-right of photo
- Multiple photos: dashed / pill page indicators at the bottom of the photo
- Tap: open `ProfilePhotoGalleryViewer`

### 1.3 Identity

- Name + age: `headlineSmall`, weight 800  
  Format: `{firstName} {lastName}, {age}`
- Location row: pink location pin (`AppIcons.location`) + `{city}, {country}` (optional `· X.X km away`)
- Presence: grey / green dot + `Offline` / `Online`

### 1.4 Plan badge (dynamic)

Must reflect **the viewed user**, never the viewer.

| Plan | Badge label | Gradient |
|------|-------------|----------|
| No paid plan | Basic | `getPlanTheme('Basic')` (orange) |
| Mid paid plan | Premium | `getPlanTheme('Premium')` (violet) |
| Top paid plan | Golden | `getPlanTheme('Golden')` |

API fields: `plan_type`, `plan_name`, `plan_id`, `is_premium`.  
Resolver: `lib/features/profile/domain/profile_plan_resolver.dart` (`tierFromUserProfile` / `planBadgeLabelFromUserProfile`).

Capsule: star (Basic/Premium) or crown (Golden) + label, `AppRadius.radiusRound`.

### 1.5 Actions (viewer mode)

Row of pill buttons:

1. **Message** — flex grow, pink→purple brand gradient, speech-bubble SVG + “Message”, white text
2. **More** — grey pill, three-dots SVG + “More”
3. Optional like (discovery only)

Below: full-width outlined chip — heart + `{n}% match`, pink border, white fill.

---

## 2. Compatibility card

White / surface card, `radiusLG`, light shadow, padding 16.

- Section title: “Compatibility” with a vertical pink accent bar on the left
- Subtitle: “How well you might connect” (`textSecondary`)
- Inner pink panel: circular percent ring + “Strong match potential / Based on interests, goals, and lifestyle”
- Rows (outline SVG + labels, middot-separated):
  - Shared interests
  - Shared values (relationship goals)
  - Lifestyle (smoke / drink / gym overlap)

Data: `computeProfileCompatibility` (API `match_percentage` / `compatibility_score` when present).

---

## 3. Gallery card

Same card chrome as Compatibility.

- Title: “Gallery”
- Subtitle: `{n} images`
- Horizontal row of rounded thumbnails (`radiusMD` / `radiusLG`)
- Tap: same gallery viewer as the hero

---

## 4. Optional sections further down

| Section | When |
|---------|------|
| About | Bio or conversation starters |
| About them | Job, education, height, gender, goals, languages, lifestyle chips |
| Shared interests | Viewed user has interest labels |

---

## Interaction notes

- Pull-to-refresh reloads this user's profile
- Message: open/create chat (draft if a conversation starter was tapped)
- More: report / block / share sheet
- Do not show own-profile stats (views, remaining superlikes, edit camera badge)

---

## Accessibility

- Back, Message, More, photos: semantic labels
- Touch targets ≥ 44px
- Respect `MediaQuery.disableAnimations`
- Contrast: primary text on light cards uses `textPrimaryLight`; badges use dark text on the plan gradient

---

## Do / don’t

**Do**

- Keep the page inside the safe zone
- Drive the plan badge from the viewed user’s `plan_type` / `is_premium`
- Reuse `ProfileHeroSection` in `viewerMode` rather than a one-off header

**Don’t**

- Draw the back button under the status clock
- Hardcode “Basic” (or any plan name)
- Use the viewer’s `userTierProvider` for this badge
- Use Material `Icons.*` — SVG via `AppIcons` / `AppSvgIcon` only
