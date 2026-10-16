# Responsive audit

Code audit of the main screens against these size classes:

| Class | Width | Example |
| --- | --- | --- |
| Compact | under 360dp | 320×568, and 720×1280 at 320dpi (360×640) sits on the compact/medium edge |
| Medium | 360–599dp | 360×640 and 411×891 |
| Large phone | about 430dp | still the phone layout |
| Expanded | 600dp and up | 1600×2560 at 320dpi = 800×1280 |

Text scale 1.3 is the target. Text scale 1.5 must not throw. Phones stay portrait-only.

Severity: **high** = overflow or unusable control, **medium** = content crushed or stretched, **low** = polish.

Screenshot note: chat, the profile tab, and the live call screen call `ScreenshotProtection.acquire()` (`FLAG_SECURE`). Those surfaces stay black in emulator captures, so they are audited from source.

## Shared layout

`lib/core/responsive/app_breakpoints.dart` only splits phone / tablet 600 / desktop 900. There is no compact (under 360) class, no max-width form wrapper around 600–720dp, and no per-widget text-scale clamp. `ResponsiveGrid.discoverCardMaxWidth` is a hard 420dp (`responsive_grid.dart:35-40`), which is what makes the discover card a small box on an 800dp tablet.

## Onboarding

`lib/pages/onboarding_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Compact + 1.3 | Slide titles use `displayMedium` (~45sp) at `onboarding_page.dart:273`. The slide is in a `SingleChildScrollView` (`:254`), so it scrolls instead of overflowing. At 1.5 the hero still grows with the system scaler. | medium |
| Expanded | Column is capped at 500dp (`:228`). Safe. | — |

## Login / register

`lib/screens/auth/login_screen.dart`, `lib/features/auth/presentation/widgets/login_form.dart`, `lib/core/widgets/auth_page_scaffold.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Compact + 1.3 | Remember-me and “Forgot Password?” share one `Row` (`login_form.dart:92-129`). The button is not flexible, so the label can overflow at 320dp with a large text scale. | high |
| Medium / large | `AuthPageScaffold` uses `PremiumDetailScaffold`, which centers content at the tablet max (`premium_page.dart:244-246`). | — |
| Expanded | Same max-width shell. Register uses the same scaffold. | — |

## Profile setup / wizard

`lib/pages/profile_wizard_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| All phones | Steps sit in `AppSettingsDetailScaffold` / a scrollable list. No fixed-height column of the whole wizard. | low |
| Expanded | Wizard body is not given its own 600–720dp cap; it inherits the settings-detail constraint only when that scaffold applies one. Long forms read as a wide phone column on an 800dp tablet. | medium |

## Discovery

`lib/pages/discovery_page.dart`, `lib/features/discover/widgets/discover_empty_state.dart`, `lib/widgets/cards/swipeable_card.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| 360dp + text 1.3 | Empty / location card (`discover_empty_state.dart:54-155`) is a non-scrolling `Column` (illustration 104px at `:207`, title, subtitle, up to three buttons). Inside the bounded stack this is the yellow/black overflow: “A RenderFlex overflowed by 223 pixels on the bottom”. Copy is built in `discovery_page.dart:827-839` (“Turn on location for nearby matches”). | high |
| 360dp + text 1.3 | Header subtitle “Swipe and connect with people nearby” sits beside two 44px actions (`discovery_page.dart:1226-1229`, `premium_page.dart:82-88` `maxLines: 2`), so the subtitle wraps to two lines. | medium |
| Compact | `SwipeableCard.fitSize` (`swipeable_card.dart:85-95`) keeps full width when height is capped, so the card goes short and wide instead of keeping the 0.76 aspect ratio. | medium |
| Expanded 800dp | Header and greeting are outside the card constraint (`discovery_page.dart:1226-1246`) and stretch the full width. The stack is `constrainedTo(..., tablet: 420)` (`:1247-1321`), so the card/placeholder is a small box in a large empty area. | high |
| All | Bottom nav pill is already capped (`responsive_grid.dart:62-68`). Leave it. | — |

## Matches

`lib/features/matching/presentation/screens/matches_screen.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Compact | `_MatchRow` (`:190`) is a normal row with an `Expanded` name. Low overflow risk. | low |
| Expanded | One full-width column of rows (`:122-144`). No second column at 600dp+. | medium |

## Likes

`lib/screens/discovery/likes_received_screen.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Compact + 1.3 | Name row uses `Expanded` (`:424`). Pass/like buttons scale with width (`:495-517`). | low |
| Expanded | Single list (`:308`). Cards stay phone-width inside a wide scaffold. No adaptive column count. Blur for locked likes is not applied on this screen (blur lives on locked chat previews, `chat_list_item.dart:350-368`). | medium |

## Chat list

`lib/widgets/chat/chat_list_item.dart`, `lib/pages/chat_list_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| 360dp + text 1.3 | Name, Official chip, pin, and mute share one row (`chat_list_item.dart:173-209`) while the timestamp sits in a sibling column (`:226-258`). A name such as “Pamela Carter” collapses to “Pamela C…”. | high |
| Expanded | Master-detail is already in `chat_list_page.dart` (`ResponsiveLayout` around `:886`, master width `responsive_grid.dart:44`). Keep it. | — |

## Chat thread

`lib/pages/chat_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| All | `ScreenshotProtection.acquire()` at `chat_page.dart:209` (released `:238`). Captures are black. | — |
| Expanded | Bubbles are capped (`responsive_grid.dart:47-59`). Composer uses a `LayoutBuilder` (`message_input.dart`). | low |

## Calls

`lib/features/calls/pages/incoming_call_page.dart`, `lib/features/calls/pages/outgoing_call_page.dart`, `lib/features/calls/presentation/widgets/call_controls.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Live call | `outgoing_call_page.dart:139` acquires `FLAG_SECURE`. Incoming page does **not** acquire it (`incoming_call_page.dart` has no `ScreenshotProtection` call). | medium (security gap, not layout) |
| Compact | `CallControls` only scrolls the button row when width is **under** 360 (`call_controls.dart:80-84`), so 360dp still uses a single `Row`. Live sheet uses fixed 56px circles (`outgoing_call_page.dart:1567-1603`); three or four fit at 320dp, but labels in the pill row do not wrap. | medium |
| Compact height | Incoming column (`incoming_call_page.dart:69-95`) uses spacers and a 176px avatar. Short phones rely on the spacers; there is no scroll if text scale 1.5 plus system insets exceed the height. | medium |
| Expanded | Incoming and the control sheet are not width-capped, so controls stretch across 800dp. | medium |

## Profile

`lib/pages/home_page.dart`, `lib/features/profile/presentation/widgets/own_profile/profile_hero_section.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Profile tab | `_ProfileScreenshotGuard` acquires `FLAG_SECURE` only while the profile tab is selected (`home_page.dart:270-271`, `:329`). | — |
| Expanded | Hero photo size is clamped to 132px (`profile_hero_section.dart:188`) while the header still spans the scaffold width. | low |
| Other user profile | Pushed profile routes do not acquire `FLAG_SECURE` themselves. | low |

## Edit profile

`lib/pages/profile_edit_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| All phones | Body is `AppSettingsDetailList` (`:325`), so the form scrolls. | — |
| FLAG_SECURE | This route never calls `ScreenshotProtection`. A black capture only happens if the profile-tab guard is still held underneath. | medium |
| Expanded | Inherits the detail scaffold width. Long location rows can stay a single line of controls. | low |

## Settings

`lib/features/settings/pages/settings_page.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Phones | Single scrolling list (`:274-280`). | — |
| Expanded | `wideContentMaxWidth: 1120` (`:266`) does not cap an 800dp tablet. Two columns start at 720px (`:273`). Usable, wider than the 600–720 form column used elsewhere. | low |

## Premium / paywall

`lib/features/payments/presentation/screens/subscription_plans_screen.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Compact + 1.3 | Plan names use `AppTypography.h2` inside a `Wrap` (`:696-707`) with `maxLines: 1`. A long plan name ellipsizes; “Current” and “Most popular” chips wrap. Subscribe bar is a bottom slot and should be checked at 320dp. | medium |
| Expanded | List is a single column inside `PremiumDetailScaffold` (max content width 600 tablet / 800 desktop). Acceptable, not a plan grid. | low |

## Filters

`lib/screens/discovery/filter_screen.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Under 520dp | Lifestyle toggles stack (`:230`, `:281`). `SegmentedButton` (`:262`) does not shrink, so Any / Yes / No can overflow a 320dp row at text scale 1.3. | high |
| Expanded | Same screen, side-by-side title and segments. Scaffold is max-width constrained. | low |

## Notifications

`lib/features/notifications/presentation/screens/notifications_screen.dart`

| Size | Finding | Severity |
| --- | --- | --- |
| Phones | List tiles. Empty state is the shared `EmptyState` widget. | low |
| Expanded | No master-detail and no max-width tighter than the tab scaffold. Tiles stretch. | low |

## Fix order

1. Shared compact / expanded helpers and a 600–720dp centered wrapper, plus a text-scale clamp for hero text.
2. Discover empty card (scroll, compact spacing) and tablet card sizing.
3. Chat list name row.
4. Login remember row, filter segments, call controls.
5. Likes and matches column count on expanded widths.
6. Widget tests at 320×568, 360×640, 411×891, and 800×1280 with text scale 1.0 and 1.3.
