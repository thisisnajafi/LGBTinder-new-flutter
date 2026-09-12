# Messenger — layout spec

**Screen:** Main-tab conversation list (Chats / Calls)  
**Widget:** `ChatListPage`  
**Files:**

- `lib/pages/chat_list_page.dart`
- `lib/widgets/chat/chat_list_item.dart`
- `lib/core/widgets/premium/premium_page.dart` (`PremiumTabPageLayout`)

**Chrome:** Tab shell (`PremiumTabPageLayout`), not `PremiumDetailScaffold`.

---

## Structure

```
PremiumTabPageLayout
├── Header  "Messenger"
│     subtitle  "Your conversations & matches"
│     search action
│     3px brand-gradient bar
└── Body Column
      search field (when open)
      Chats | Calls switch
      All / Unread / Online  (or call filters)
      likes-and-matches row (chats, if any)
      list  (conversations or calls)
```

Home already reserves space for the floating nav. This tab must **not** add a second bottom SafeArea.

---

## Safe area

| Zone | Rule |
|------|------|
| Status bar | `PremiumTabPageLayout` insets with `SafeArea(top)` or `viewPadding.top` if padding is 0 |
| Header top pad | `AppSpacing.spacingLG` (16) under the status bar |
| Bottom | `SafeArea(bottom: false)` — `HomePage` already pads `navBarReserve` |
| List bottom | `AppSpacing.spacingLG` so the last row clears the floating bar |

---

## List smoothness

- Tight rows: `AppSpacing.spacingXS` (4) between cards, not 8–16
- No staggered fade/slide on first load
- `BouncingScrollPhysics` + pull-to-refresh
- `RepaintBoundary` per conversation row
- Empty match row must not leave an extra spacer

Cards: `AppRadius.radiusMD`, light shadow, 52px avatar, name + preview + time.

---

## Do / don’t

**Do** keep Chats vs Calls and filters on this screen.  
**Don’t** put profile About / Interests here. Open Chat for that peer, then Chat info.
