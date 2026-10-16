# Notification and call UI plan

Observed on the emulator: a message in the shade is the generic title “New Message!” and the body “&lt;name&gt; sent you a message”. There is no avatar, no message preview, and no conversation grouping. The status-bar icon is a white square because Android is given the full-color launcher art. CallKit shows the name, avatar, and Decline/Accept, but the line under the name is only “Voice Call” or “Video Call”, and the banner colors are generic. Opening the app while that banner is up does not reliably open an in-app incoming screen. `CallKitRestore` treats an unanswered CallKit row as stale and `restoreAcceptedCall` ends it.

## Ranked work

1. **Monochrome status icon and brand accent.** Add a white `ic_stat_lgbtfinder` drawable, point Firebase and `flutter_local_notifications` at it, and tint it with the app pink (`#EC4899`) in the manifest, local notifications, and the FCM `android.notification` block.

2. **Per-type channels and emoji-free copy.** Separate high-importance channels for messages, likes, matches, and calls. Titles and bodies for like, super like, match, message, incoming call, and missed call are plain sentences. Super Like is its own title. A match title is celebratory without emoji.

3. **Message preview, MessagingStyle, grouping, and quick actions.** The visible body is the message text when the push is allowed to include it. Android uses `MessagingStyle`, one row per message, grouped by conversation, with Reply and Mark as read. A background push that already has an OS notification is still collapsed to a single shade row.

4. **Profile photo privacy.** `NotificationAvatarService::urlFor($recipient, $sender)` is the only rule: a clear photo only when the recipient is premium or the two users are matched. Otherwise the payload carries a server-blurred ~128px thumbnail on the public disk, and the clear URL is omitted. Like, super like, match, message, and call payloads (FCM data, database notifications, and the Pusher events that feed those notifications) use that helper. The app downloads that URL, crops a circle, and sets it as the large icon, falling back to the app icon.

5. **CallKit subtitle and accent.** The line under the name is “Incoming voice call · LGBTFinder” or “Incoming video call · LGBTFinder”, with the same pink accent on the actions.

6. **Missed-call notification with Call back.** The missed-call push is data-only so the app can post one shade row with a Call back action that starts an outgoing call to that person.

7. **In-call screen.** Blurred photo behind the outgoing and incoming screens, a larger circular avatar with the pulse ring while the call is ringing, status text Calling… / Ringing… / Connecting… / mm:ss, and the existing labeled control buttons kept in the theme.

8. **Incoming page while ringing.** An unanswered CallKit row is not ended on launch. Bringing the app forward reads that row and opens `IncomingCallPage` (decline and accept) instead of leaving the user on whatever tab was underneath.
