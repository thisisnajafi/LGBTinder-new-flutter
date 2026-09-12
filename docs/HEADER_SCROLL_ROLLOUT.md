# Header + bounce-scroll rollout

Messenger is the reference: `PremiumPageHeader` (title, subtitle, 3px gradient bar), status-bar inset, **no extra bottom SafeArea on home tabs**, `AppScroll.bouncing` on lists.

## Shared (applies to many screens)

| Piece | What changes |
|-------|----------------|
| `AppScroll.bouncing` | `AlwaysScrollable` + `BouncingScrollPhysics` |
| `PremiumSafeArea` | Top inset; optional bottom |
| `PremiumTabPageLayout` | Home tabs: Messenger, Notifications, Settings, Profile |
| `PremiumDetailScaffold` | Pushed pages: Chat info, settings details, etc. |
| `AppSettingsDetailList` | All settings bodies using this list |
| `AppPageScaffold` | Older pages still on `AppPageHeader` → premium header |

## Page-by-page

1. **Chat info** — already `PremiumDetailScaffold`; add bounce list  
2. **Chat page** — SafeArea header already; bounce message list  
3. **Messenger** — done (verify)  
4. **Notifications** — tab shell already; bounce lists  
5. **Settings hub** — tab shell already; bounce list  
6. **Settings children** (via `AppSettingsDetailScaffold` / `AppPageScaffold`):
   - Account details, Appearance, Matching preferences, Sound
   - Notification settings, Privacy, 2FA, Active sessions
   - Blocked users, Safety center, Help & support
   - Privacy policy, Terms
   - Call settings, Payment settings, Subscription management
   - Accessibility, animation, haptic, media, image compression, pull-to-refresh, rainbow theme, skeleton, group notifications
7. **Profile tab** — `PremiumTabPageLayout` + bounce `OwnProfileView`  
8. **Other-user profile / Chat info profile** — bounce already on other-user view; Chat info bounce in (1)

Discovery is out of this pass unless you ask for it next.
