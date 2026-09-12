# Chat page — layout spec

**Screen:** One-to-one conversation  
**Widget:** `ChatPage` + `ChatHeader` + `MessageInput`  
**Files:**

- `lib/pages/chat_page.dart`
- `lib/widgets/chat/chat_header.dart`
- `lib/widgets/chat/message_input.dart`

**Chrome:** Follow `docs/PAGE_LAYOUT_SYSTEM.md` for safe area and header bar. This screen is a chat, not a card list.

---

## Structure

```
Scaffold  (solid background — not the wallpaper)
└── SafeArea (top: true, bottom: false)
    └── Column
        ├── ChatHeader
        │     back · avatar · name / last seen · call · video · info
        │     3px brand-gradient bar
        ├── ChatMutedBanner (if muted)
        └── Expanded  ← wallpaper lives only here
            └── Column
                  pinned banner
                  message list
                  typing
                  reply preview
                  MessageInput  (has its own bottom SafeArea)
```

---

## Safe area (required)

| Zone | Rule |
|------|------|
| Status bar | Header sits **below** it. Wallpaper must not draw behind the clock. |
| Top | `SafeArea(top: true)` on the page, **not** a custom `AppBar` slot |
| Bottom | `MessageInput` already applies `SafeArea(top: false)` above the home indicator |
| Keyboard | `resizeToAvoidBottomInset: true` |

Do not use `Scaffold.appBar` + `PreferredSize` for this screen. That left a transparent strip and let the pattern sit under the status bar.

---

## Header

Solid `cardBackgroundLight` / `Dark` (same family as Chat info).

- Back: 48×48, `AppIcons.arrowLeft`
- Avatar 42px, online ring + green dot
- Name: `titleMedium`, weight 800
- Subtitle: `LastSeenWidget`
- Actions: circular wells, 40px (36 on narrow)
- Divider: 3px `AppColors.brandGradient`, pill radius, 16px horizontal inset

Tap name/avatar or info → Chat info. Not the full public profile.

---

## Message area

Wallpaper (`assets/images/chat/chat-light.png` / `chat-dark.png`) fills **only** the expanded region under the header.

- Sent bubbles: brand gradient, white text
- Received: surface/white bubbles
- Date pills and call history chips stay centered

---

## Composer

White/surface bar above the system nav. Rounded field “Type a message…”, media and mic/send on the right. SVG icons only.
