# Chat info — layout & content spec

**Screen:** Conversation details from an open chat  
**Widget:** `ChatConversationInfoPage`  
**File:** `lib/pages/chat_conversation_info_page.dart`  
**Chrome:** Follow `docs/PAGE_LAYOUT_SYSTEM.md` (`PremiumDetailScaffold`)

This is **not** the other-user profile. Bio, interests, location, and profile photo gallery belong on **View profile**.

---

## Structure

```
PremiumDetailScaffold  title: "Chat info"
└── ListView
    ├── Identity card
    │     avatar, name, online / last seen
    │     View profile (gradient button)
    ├── Chat card
    │     Mute notifications
    │     Shared media count
    │     Pinned messages count
    ├── Shared media card
    │     photos / videos sent in this chat
    └── Safety card
          Report user, Block user
```

---

## Identity card

- Circular avatar (88px), online green dot when present
- Name: first name, `AppTypography.h2`, centered
- Presence: `LastSeenWidget` (`Online` / `Last seen …` / `Offline`)
- **View profile** — `GradientButton` + `AppIcons.user` → `ProfileDetailScreen`

Do not show city, bio, interests, or profile gallery here.

---

## Chat card

| Row | Behavior |
|-----|----------|
| Mute notifications | Toggles conversation mute |
| Shared media | Count of photos/videos in this chat (informational) |
| Pinned messages | Count from `pinnedCountProvider` (informational) |

---

## Shared media card

Grid of images/videos **from the conversation**, not the user’s profile album.  
Tap image → full-screen viewer. Self-destruct / disappearing media is excluded.

---

## Safety card

- Report user → `ReportUserScreen`
- Block user → `BlockUserDialog` (pops to root on success)
