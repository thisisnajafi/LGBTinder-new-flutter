# LGBTFinder — Application Features

**Product:** LGBTFinder Flutter app (`lgbtindernew`)  
**Audience:** product, design, QA, and engineering  
**Source of truth:** live routes and screens in `lib/` (September 2026)  
**Home shell:** `/home` — five tabs: Discover, Chat, Notifications, Profile, Settings

This document describes what people can do in the app: the home experience, the rest of the product, every notification type the app understands, and the Settings hub.

---

## 1. App map

After splash and sign-in, the signed-in app is a five-tab home shell. Back on a non-Discover tab returns to Discover. Back again on Discover asks the user to press back once more to exit.

| Tab | Label | Route | Screen |
|---|---|---|---|
| 0 | Discover | `/home` | Swipe stack and nearby matching |
| 1 | Chat | `/home?tab=1` | Messenger (chats + calls) |
| 2 | Notifications | `/home?tab=2` | In-app inbox |
| 3 | Profile | `/home?tab=3` | Own profile hub |
| 4 | Settings | `/home?tab=4` | Account, privacy, preferences |

The Chat tab shows an unread-message badge. The Notifications tab shows an unread-notification badge. The Profile tab can show the user’s avatar and an online indicator. An offline banner appears when the device has no network.

---

## 2. Home — Discover tab

**Title:** Discover  
**Subtitle:** Swipe and connect with people nearby

This is the main dating surface: a card stack of nearby (or passport) profiles.

### Header

| Action | What it does |
|---|---|
| Passport | Opens location passport (Silver+ / plan flag `passport`). Badge when a virtual location is active. |
| Notifications | Jumps to the Notifications tab. Badge if there are unread items. |
| Filters | Opens Discovery filters. Badge when filters are active. |

### Body (top to bottom)

1. **Greeting card** — time-based greeting (Good morning / afternoon / evening / night). Avatar tap opens the Profile tab.
2. **Active filters bar** — chips such as distance, age range, Online, Verified, or Custom filters. Edit or Clear.
3. **Passport banner** — shown while discovering from a chosen city. **Return home** restores the real location.
4. **Swipe limit banner** — remaining daily likes / swipes from the current plan.
5. **Card stack** — swipe left (dislike), right (like), up (superlike). Tap a card for the full profile. Pull to refresh.
6. **Action row** — Dislike, Superlike, Like buttons.

### Empty and limit states

| Situation | User sees |
|---|---|
| Location off | Turn on location for nearby matches |
| Nobody nearby | No one nearby right now |
| Deck exhausted | You've seen everyone nearby |
| Daily like / swipe cap | Upgrade dialog |
| Superlikes used up | Superlike packs purchase sheet |

A mutual like launches the match celebration (chat now or keep swiping). Superlike can include an optional message before send.

### Discovery filters

**Screen:** Discovery filters — Fine-tune who you see

| Section | Controls | Notes |
|---|---|---|
| Discover range | Age range, maximum distance | Available on all plans |
| Identity | Gender multi-select | Available on all plans |
| Advanced filters | Verified only, Online only, Premium only, interests, relationship goals, profession, education, languages, music taste | Silver+ / `advanced_filters` |
| Lifestyle match | Smoking, drinking, fitness / gym | Advanced |

---

## 3. Other product features

### 3.1 Matching beyond the stack

| Feature | What the user can do |
|---|---|
| Profile detail | Open a full profile from Discover, likes, or notifications. Like, Superlike, or message when allowed. |
| Other-user profile | Message, Like, Superlike. More menu: Block, Report, Add to favorites, Mute. |
| Likes you | See people who liked you, then Pass or Accept. Gated (Silver+ / see who liked you). Empty: No likes yet. |
| Matches list | Open a match into chat. Empty: No matches yet. |
| Lost match | Dialog when a match is no longer available. |
| Discovery preferences | Age 18–100, distance 1–500 km, visibility: everyone / people I like / hidden. |
| Passport | Search a city, stay 24 / 48 / 72 hours, then return home. |

### 3.2 Chat (Messenger)

**Title:** Messenger

Two sections: **Chats** and **Calls**.

**Chats**

- Search conversations
- Filters: All, Unread, Online
- Horizontal row of new matches
- Open a thread; swipe Mute / Unmute or Delete (with undo)
- Reorder conversations
- Tablet: split list + thread

**Thread**

- Text, image, voice, video, profile card, self-destruct media
- Attachments: Camera, Gallery, Voice, File, Profile, Self-Destruct
- Reply, copy, edit own text, delete own, report theirs
- Reactions: ❤️ 😂 😮 😢 😡 👍
- Pin / pinned messages, swipe-to-reply, typing indicator, link previews, delivery / read status
- Header: chat info, voice call, video call (gated)
- Chat info: mute notifications, shared media, pinned messages, report, block, peer call history

Free / Basic users can see locked or blurred messages until they upgrade.

**Calls**

- Filters: All, Missed, Incoming, Outgoing
- Outgoing / live call: mute, speaker, camera, hang up, timer
- Incoming: accept / decline via overlay or native CallKit
- Busy handling if already in a call; ring timeout
- Per-person call history

### 3.3 Profile

**Own profile title:** Profile — Your photos, bio, and membership

| Area | What the user can do |
|---|---|
| Hero | Name, age, verified badge, tier, location, online, views, Superlikes remaining. Edit profile / photo. |
| Photos | Gallery (plan photo limit). Add from camera or gallery. |
| Personality | Bio |
| Details | Job, education, height, gender, goals, languages, smoke / drink / gym |
| Interests | Edit from profile editor |
| Account hub | Verification, Discovery, Privacy, Security, Boost |
| Membership | Upgrade or manage subscription |

**Edit profile:** photos, bio, lifestyle, location, work & education, interests & languages.

**Verification:** photo / ID / video (score weights 30 / 40 / 30). Statuses: Unverified, Under Review, Fully Verified, score out of 100.

### 3.4 Auth and onboarding

| Screen | User can |
|---|---|
| Welcome | Create account or sign in |
| Sign in | Email / password, forgot password |
| Create account | Name, email, password, accept Terms / Privacy |
| Verify email | Enter OTP, resend |
| Reset password | OTP then new password |
| Account banned | Shown when the account is blocked |
| Profile wizard (7 steps) | Photo, basic info, about you, lifestyle, interests & music, extra photos, review |
| Intro onboarding | Welcome, Discover Matches, Connect & Chat, Be Yourself — Skip / Next / Get Started |
| Set preferences | Matching prefs after the wizard |

Unauthenticated deep links are saved and resumed after login. Incomplete profiles are sent to the wizard.

### 3.5 Premium and billing

Tiers in the client: **Basic** (`basid`), **Silver** (`silder` / premium), **Golden** (`golden`).

Plan feature flags include: advanced filters, see who liked me, rewind, passport, boost, read receipts, video calls, incognito, ad-free, priority likes, AI matching.

Typical gates:

- Unlimited likes, likes-you, advanced filters, boost → Silver+
- Video calls → Golden (or API `video_calls`)
- Superlikes → daily allowance plus purchased packs

| Screen | User can |
|---|---|
| Choose plan | Browse and buy a membership |
| Superlikes | Buy extra Superlike packs |
| Subscription | Current plan, upgrade, cancel (period end or immediately), restore purchases, manage in Google Play |
| Compare tiers | Basic / Silver / Golden comparison |
| Upgrade required | Full-screen paywall for locked features |
| Billing history | Past transactions |

### 3.6 Safety and support

**Safety center**

- Blocked users, report history, nearby safe places, emergency contacts
- Safety tips (do not share address/financials; meet in public; trust instincts)
- Report a problem → Help & support

**Reporting reasons:** spam, fake profile, inappropriate content, harassment, scam, underage, other.

**Help & support:** FAQs, send a message, tickets, email `support@lgbtfinder.com`, live chat, Terms, Privacy.

---

## 4. Notifications

Notifications exist in three layers:

1. **In-app inbox** (Notifications tab)
2. **Push** (FCM; optional OneSignal)
3. **Live overlays** (incoming call UI, in-app chat banner)

### 4.1 Inbox (Notifications tab)

**Title:** Notifications  
**Subtitle:** `{N} unread · Stay in the loop` or `Your social activity hub`

**Category chips:** All · Matches · Likes · Views · System

| Chip | Types included |
|---|---|
| All | Everything |
| Matches | type contains `match` |
| Likes | type contains `like` (includes like, superlike, story_like, feed_like, …) |
| Views | type contains `view` |
| System | type contains `plan`, `system`, or `verify` |

**Actions**

- Tap → mark read and navigate
- Swipe delete with 5-second undo
- Mark all read / Clear all (overflow menu)
- Leaving the tab marks remaining items read
- Infinite scroll for older items
- Empty: No notifications → Discover or support

Plan-restricted likes hide the other person’s identity until the viewer upgrades.

### 4.2 How a tap is routed

| Type | Opens |
|---|---|
| `message`, `chat` | Chat thread (or chat list) |
| `match`, `like` | Matches list |
| `superlike`, `superlike_sent` | Chat if peer id exists, else Discover |
| `call`, `incoming_call`, `incoming_call_audio`, `incoming_call_video` | Active / incoming call UI |
| `active_call` | Payload location, else Home |
| `plan_purchased`, `plan_granted`, `plan_upgraded`, `subscription_renewed` | Subscription management |
| `profile`, `profile_view` | That user’s profile, else Discover |
| `notification` / unknown | Notifications tab |
| Plan-restricted like with no peer | Upgrade required |

If the notification carries an `action_url`, that URL wins.

### 4.3 Notification types

Types are strings (there is no Dart enum). Below is the full set the Flutter client and Laravel push templates currently recognize.

#### Dating and social (user-related)

| Type | Meaning | Typical copy |
|---|---|---|
| `like` | Someone liked your profile | New Like — {name} liked your profile |
| `match` | Mutual like | It's a Match — new match with {name} |
| `superlike` | Someone Superliked you | Superlike — {name} superliked you |
| `superlike_sent` | You sent a Superlike (client routing) | Opens chat / Discover |
| `superlike_received` | Superlike received (client visual) | Star icon |
| `message` / `chat` | New chat message | New Message — {name} sent you a message |
| `view` / `profile_view` / `profile` / `visit` / `profile_visit` | Profile visit | Profile View — someone viewed your profile |

#### Calls

| Type | Meaning | Typical copy |
|---|---|---|
| `incoming_call` | Generic incoming call | Opens call UI |
| `incoming_call_audio` | Incoming voice call | Incoming Call — {name} is calling you |
| `incoming_call_video` | Incoming video call | Incoming Video Call — {name} wants to video chat |
| `call` | Call event | Opens call UI |
| `active_call` | Resume a live call | Native notification tap |
| `missed_call` | You missed a call | Missed Call — you missed a call from {name} |
| `call_declined` | Peer declined | Call Declined |
| `call_not_answered` | Peer did not answer | Call Not Answered |

Incoming-call push uses a high-priority call notification / CallKit, not a normal inbox tile.

#### Membership and payments (system)

| Type | Meaning |
|---|---|
| `plan_purchased` | Subscription activated |
| `plan_granted` | Premium access granted (admin / gift) |
| `plan_upgraded` | Plan upgraded |
| `plan_downgraded` | Plan downgraded |
| `subscription_renewed` | Renewal succeeded |
| `subscription_canceled` | Subscription canceled |
| `subscription_expired` | Subscription expired |
| `subscription_reminder` / `renewal_reminder` | Expiry reminder |
| `payment_success` | Payment succeeded |
| `payment_failed` | Payment failed |
| `premium_feature` | Premium feature highlight |
| `superlike_pack_purchased` | Superlike pack bought |
| `superlike_pack_finished` | Superlike pack used up |
| `superlike_pack_auto_activated` | Next queued pack activated |

#### Safety, verification, marketing

| Type | Meaning |
|---|---|
| `safety_alert` | Safety alert |
| `system_announcement` / `announcement` / `admin` / `system` / `general` | Product / admin message |
| `verification_reminder` | Finish verification |
| `verification_approved` | Photo / ID / video approved |
| `verification_rejected` | Verification needs resubmit |
| `marketing` / `promotion` / `promo` | Offers and campaigns |

#### Feed / story (templates exist; inbox can display them)

| Type | Meaning |
|---|---|
| `story_like` / `story_reply` | Story engagement |
| `feed_like` / `feed_comment` / `comment` / `reply` / `comment_like` | Feed engagement |

#### Marketing campaigns (backend templates)

These are scheduled / campaign types, not always listed as inbox chips:

| Category | Examples |
|---|---|
| Re-engagement | Inactive 3 / 7 / 14 / 30 days |
| Promotional | Flash sale, feature highlight, weekend special, Pride month |
| Renewal | 7 days / 3 days / 1 day / expired |
| Daily rewards | Reward ready, streak about to break, streak milestone |
| Achievement | Badge earned, multiple badges |

### 4.4 Push vs in-app vs live UI

| Channel | Behavior |
|---|---|
| In-app list | `GET /notifications`. Mark read, delete, unread badge. |
| FCM push | Device token via `POST /notifications/register-device`. Foreground shows a local notification. Channel group `lgbtfinder_$type`. |
| Chat FCM suppress | Open thread or muted peer can skip chat push. |
| Incoming call | CallKit / Android call category, not a standard banner. |
| In-app chat banner | Toast-style new-message banner while using the app — separate from the inbox. |

### 4.5 Notification preference model (API)

The backend preference model (`NotificationPreferences`) supports:

| Key | Default | Purpose |
|---|---|---|
| `push_enabled` | on | Master push switch |
| `email_enabled` | on | Master email switch |
| `sms_enabled` | off | SMS (rarely used) |
| `likes` | on | Like pushes |
| `matches` | on | Match pushes |
| `messages` | on | Message pushes |
| `superlikes` | on | Superlike pushes |
| `profile_views` | off | View pushes |
| `premium_features` | on | Premium / plan pushes |
| `weekly_digest` | on | Weekly email |
| `marketing_emails` | off | Promo email |
| `security_alerts` | on | Security email / push |
| `quiet_hours_enabled` + start/end | off | Mute during a time window |
| `muted_users` | [] | Per-user mute |

`isNotificationAllowed(type)` maps `like`, `match`, `message`, `superlike`, `profile_view`, `premium`.

The **Alerts** screen in Settings currently keeps these toggles in local widget state. The preference API and the Alerts UI are not fully wired together yet.

---

## 5. Settings page

**Title:** Settings  
**Subtitle:** Your account, privacy, and preferences  
**Route:** `/home?tab=4`

Pull-to-refresh revalidates cached account data.

### 5.1 Quick access

| Tile | Subtitle | Opens |
|---|---|---|
| Profile | Edit your dating profile | Profile tab |
| Membership | Plans & benefits | Subscription management |
| Security | Sessions & 2FA | Active sessions |
| Privacy | Visibility & data | Privacy & safety |
| Alerts | Push & email prefs | Notification settings |
| Discovery | Who you want to meet | Matching preferences |
| Likes you | People who liked your profile | Likes received |

### 5.2 Account

| Tile | Subtitle | Opens |
|---|---|---|
| Account details | Phone, email, and password | Account details → change email / password (OTP) |
| Blocked users | Manage blocked profiles | Blocked users list (unblock with confirm) |
| Safety center | Reports, alerts, and emergency contacts | Safety center |
| Two-factor authentication | Extra sign-in protection | Enable / disable 2FA, QR, backup codes |

### 5.3 App experience

| Tile | Subtitle | Opens |
|---|---|---|
| Sounds & haptics | Notification sounds | Message sound, call ringtone, notification sound, vibration |
| Appearance | Light / Dark / System | Theme mode |

### 5.4 Support & legal

| Tile | Opens |
|---|---|
| Help & support | FAQs and contact |
| Privacy policy | Legal copy |
| Terms of service | Legal copy |
| About | App version and build (not tappable) |

### 5.5 Account actions

**Log out** — confirm: “You will need to sign in again to use the app.” Then Welcome screen.

### 5.6 Nested setting screens

#### Privacy & safety

| Section | Controls |
|---|---|
| Profile visibility | Show my profile, show age, show distance, show online status, show last seen |
| Who can see my profile | Everyone / Matches only / Premium users only |
| Discovery visibility | Everyone / Only people I've liked / Hidden from discovery |
| Discovery | Show me in discovery, show me in top picks, allow swipe back |
| Data sharing | Matching, analytics, ads |
| Messaging privacy | Block messages from non-matches, show read receipts |

#### Alerts (notification settings)

**Push:** master switch, new matches, new messages, message likes, Superlikes, top picks (off by default), boosts (off by default), profile views, likes.

**Email:** master switch, new matches (off), new messages (off), promotions, updates.

**Sound & vibration:** sound, vibration.

#### Discovery preferences

Age range, max distance, discovery visibility (`everyone` / `people_i_like` / `hidden`). Saved to the preferences API.

#### Sounds & notifications

Persisted sound catalog: message sound, call ringtone, notification sound, vibration enabled. User can preview before saving.

#### Account details / management

Phone, email (Verified badge), password change via OTP.

#### Active sessions

List of signed-in devices; revoke a session.

#### Two-factor authentication

Status, scan QR / enter code / save backup codes, enable or disable.

---

## 6. Route index

```
/                          Splash
/welcome                   Welcome
/login                     Sign in
/register                  Create account
/forgot-password           Reset password
/email-verification        Email OTP
/account-banned            Banned account
/profile-wizard            7-step profile setup
/onboarding                Intro slides
/onboarding-preferences    Matching prefs after wizard
/home                      Discover (+ ?tab=1..4)
/home/blocked-users        Blocked users
/home/safety-center        Safety center
/home/likes-received       Likes you
/home/matches              Matches
/profile/edit              Edit profile
/profile/verification      Verification
/profile-detail            Other user profile
/passport                  Location passport
/chat                      Chat thread
/call/outgoing             Outgoing / live call
/calls/history             Peer call history
/subscription-plans        Choose plan
/superlike-packs           Superlike packs
/subscription-management   Manage membership
/subscription-status       Membership summary
/tier-comparison           Compare tiers
/feature-locked            Upgrade required
/billing-history           Billing history
/help-support              Help & support
/support-tickets           Tickets
/terms-of-service          Terms
/privacy-policy            Privacy
```

---

## 7. Related docs

| Doc | Role |
|---|---|
| `docs/FIREBASE_AND_NOTIFICATIONS_SETUP.md` | FCM / OneSignal setup |
| `docs/USER_FLOW_RELEASE_NOTES.md` | Auth guards, tiers, paywall |
| `docs/NAVIGATION_BAR_IMPLEMENTATION.md` | Bottom nav |
| `docs/CHAT_PAGE_LAYOUT.md` | Chat UI |
| `Enhanced-Flutter-UI-Document.md` | Visual design, not a feature inventory |

Older settings screens still exist in code (accessibility, call settings, rainbow theme, and others) but are **not** linked from the current Settings hub. Treat this document and `AppRoutes` as the user-facing map.

---

# LGBTFinder — امکانات برنامه

**محصول:** اپ Flutter ال‌جی‌بی‌تی‌فایندر (`lgbtindernew`)  
**مخاطب:** محصول، طراحی، QA و مهندسی  
**منبع:** کد فعلی مسیرها و صفحات در `lib/` (سپتامبر ۲۰۲۶)

این سند امکانات واقعی اپ را پوشش می‌دهد: صفحه خانه، بقیه قابلیت‌ها، انواع نوتیفیکیشن، و صفحه تنظیمات.

---

## ۱. نقشه اپ

پس از اسپلش و ورود، اپ داخل یک شِل پنج‌تبه اجرا می‌شود. دکمه برگشت روی تب غیر از Discover به Discover برمی‌گردد. برگشت دوباره روی Discover برای خروج تأیید می‌خواهد.

| تب | برچسب | مسیر | کار |
|---|---|---|---|
| ۰ | Discover | `/home` | سوایپ و مچ نزدیک |
| ۱ | Chat | `/home?tab=1` | مسنجر (چت + تماس) |
| ۲ | Notifications | `/home?tab=2` | اینباکس درون‌برنامه |
| ۳ | Profile | `/home?tab=3` | پروفایل خود کاربر |
| ۴ | Settings | `/home?tab=4` | حساب، حریم خصوصی، ترجیحات |

تب چت بج پیام نخوانده دارد. تب نوتیفیکیشن بج نوتیف نخوانده دارد. تب پروفایل می‌تواند آواتار و نقطه آنلاین نشان دهد. بدون اینترنت، بنر آفلاین ظاهر می‌شود.

---

## ۲. خانه — تب Discover

**عنوان:** Discover  
**زیرعنوان:** Swipe and connect with people nearby

سطح اصلی دوستیابی: پشته کارت پروفایل‌های نزدیک (یا پاسپورت).

### هدر

| عمل | نتیجه |
|---|---|
| Passport | باز کردن پاسپورت مکانی (سیلور+). بج وقتی مکان مجازی فعال است. |
| Notifications | رفتن به تب نوتیفیکیشن. |
| Filters | فیلتر دیسکاور. بج وقتی فیلتر فعال است. |

### بدنه (از بالا به پایین)

1. کارت خوش‌آمدگویی بر اساس زمان روز. لمس آواتار → تب پروفایل.
2. نوار فیلترهای فعال (فاصله، سن، آنلاین، تأییدشده، سفارشی). ویرایش / پاک کردن.
3. بنر پاسپورت — **Return home** مکان واقعی را برمی‌گرداند.
4. بنر سقف سوایپ / لایک روزانه.
5. پشته کارت — چپ: دیسلایک، راست: لایک، بالا: سوپرلایک. لمس کارت: پروفایل کامل. کشیدن برای تازه‌سازی.
6. ردیف دکمه‌ها: دیسلایک / سوپرلایک / لایک.

### حالت‌های خالی و محدودیت

موقعیت خاموش → روشن کردن لوکیشن. کسی نزدیک نیست / همه را دیده‌اید. سقف روزانه لایک/سوایپ → دیالوگ ارتقا. سوپرلایک تمام → خرید پک.

لایک دوطرفه جشن مچ را نشان می‌دهد. سوپرلایک می‌تواند پیام اختیاری داشته باشد.

### فیلترها

محدوده سن و فاصله و جنسیت برای همه. فیلترهای پیشرفته (فقط تأییدشده، فقط آنلاین، فقط پریمیوم، علایق، اهداف رابطه، شغل، تحصیلات، زبان، موسیقی) و سبک زندگی (سیگار، نوشیدنی، باشگاه) برای سیلور+.

---

## ۳. بقیه امکانات

### مچینگ

پروفایل کامل، منوی بیشتر (بلاک، ریپورت، علاقه‌مندی، میوت)، صفحه «کسانی که شما را لایک کردند» (سیلور+)، لیست مچ، دیالوگ مچ ازدست‌رفته، ترجیحات دیسکاور (سن ۱۸–۱۰۰، فاصله ۱–۵۰۰ کیلومتر، نمایش: همه / کسانی که لایک کرده‌ام / مخفی)، پاسپورت شهر برای ۲۴ / ۴۸ / ۷۲ ساعت.

### چت و تماس

مسنجر دو بخش دارد: **Chats** و **Calls**.

چت: جستجو، فیلتر All / Unread / Online، ردیف مچ‌های جدید، میوت/حذف با امکان برگرداندن، مرتب‌سازی. ترد: متن، عکس، ویس، ویدیو، کارت پروفایل، رسانه خودتخریب؛ ریپلای، کپی، ویرایش، حذف، ریپورت؛ ری‌اکشن؛ پین؛ تایپینگ؛ پیش‌نمایش لینک؛ وضعیت ارسال/خوانده. تماس صوتی و ویدیویی از هدر (ویدیو قفل‌شده). کاربران رایگان ممکن است پیام قفل/محو ببینند.

تماس: فیلتر All / Missed / Incoming / Outgoing، میوت/اسپیکر/دوربین، پذیرش یا رد، CallKit، تاریخچه تماس با همان نفر.

### پروفایل

نام، سن، تأیید، سطح عضویت، مکان، آنلاین، بازدید، سوپرلایک باقی‌مانده، گالری، بایو، جزئیات زندگی، علایق، هاب حساب (تأیید هویت، دیسکاور، حریم خصوصی، امنیت، بوست)، ارتقا یا مدیریت اشتراک. تأیید: عکس / مدارک / ویدیو با امتیاز از ۱۰۰.

### ورود و آنبوردینگ

خوش‌آمد، ورود، ثبت‌نام، تأیید ایمیل OTP، بازیابی رمز، حساب بن‌شده، ویزارد ۷ مرحله‌ای پروفایل، اسلایدهای معرفی، تنظیم ترجیحات. لینک عمیق بعد از ورود ادامه پیدا می‌کند.

### پریمیوم

سطح‌ها: Basic / Silver / Golden. فیلتر پیشرفته، دیدن لایک‌ها، پاسپورت، بوست معمولاً سیلور+؛ تماس ویدیویی معمولاً گلدن. صفحه پلن، پک سوپرلایک، مدیریت اشتراک، مقایسه سطح، پی‌وال، تاریخچه صورتحساب.

### ایمنی و پشتیبانی

مرکز ایمنی: بلاک، تاریخچه ریپورت، مکان‌های امن نزدیک، مخاطبان اضطراری، نکات ایمنی. دلایل ریپورت: اسپم، پروفایل جعلی، محتوای نامناسب، آزار، کلاهبرداری، زیر سن قانونی، سایر. پشتیبانی: پرسش‌های متداول، تیکت، ایمیل `support@lgbtfinder.com`.

---

## ۴. نوتیفیکیشن‌ها

سه لایه: اینباکس درون‌برنامه، پوش (FCM / OneSignal)، و رابط زنده (تماس ورودی، بنر چت).

### اینباکس

دسته‌ها: **All / Matches / Likes / Views / System**. لمس = خوانده + ناوبری. حذف با سوایپ و ۵ ثانیه Undo. علامت همه به‌عنوان خوانده / پاک کردن همه. خروج از تب بقیه را خوانده می‌کند. لایک محدود به پلن هویت طرف مقابل را تا ارتقا پنهان می‌کند.

### هدایت پس از لمس

| نوع | مقصد |
|---|---|
| پیام / چت | ترد چت |
| مچ / لایک | لیست مچ |
| سوپرلایک | چت یا دیسکاور |
| تماس ورودی | صفحه تماس |
| خرید/ارتقا پلن | مدیریت اشتراک |
| بازدید پروفایل | پروفایل همان کاربر |
| ناشناخته | تب نوتیفیکیشن |

### انواع نوتیفیکیشن

**اجتماعی:** `like`, `match`, `superlike`, `superlike_sent`, `superlike_received`, `message`, `chat`, `view`, `profile_view`, `profile`, `visit`, `profile_visit`

**تماس:** `incoming_call`, `incoming_call_audio`, `incoming_call_video`, `call`, `active_call`, `missed_call`, `call_declined`, `call_not_answered`

**عضویت و پرداخت:** `plan_purchased`, `plan_granted`, `plan_upgraded`, `plan_downgraded`, `subscription_renewed`, `subscription_canceled`, `subscription_expired`, `subscription_reminder`, `renewal_reminder`, `payment_success`, `payment_failed`, `premium_feature`, پک‌های سوپرلایک

**سیستم و ایمنی:** `safety_alert`, `system_announcement`, `announcement`, `admin`, `system`, `general`, `verification_reminder`, `verification_approved`, `verification_rejected`, `marketing`, `promotion`, `promo`

**فید/استوری (قالب وجود دارد):** `story_like`, `story_reply`, `feed_like`, `feed_comment`, `comment`, `reply`, `comment_like`

**کمپین بازاریابی بک‌اند:** بازگشت کاربر غیرفعال، فروش ویژه، تمدید اشتراک، پاداش روزانه، نشان/دستاورد.

### ترجیحات API

کلیدها: پوش، ایمیل، پیامک، لایک، مچ، پیام، سوپرلایک، بازدید پروفایل، امکانات پریمیوم، خلاصه هفتگی، ایمیل بازاریابی، هشدار امنیتی، ساعات سکوت، کاربران میوت‌شده.

صفحه **Alerts** در تنظیمات فعلاً سوئیچ‌ها را فقط در state محلی نگه می‌دارد و هنوز کامل به API وصل نیست.

---

## ۵. صفحه تنظیمات

**عنوان:** Settings — Your account, privacy, and preferences

### دسترسی سریع

پروفایل، عضویت، امنیت (نشست‌ها و ۲FA)، حریم خصوصی، هشدارها، دیسکاور، کسانی که شما را لایک کردند.

### حساب

جزئیات حساب (تلفن، ایمیل، رمز)، کاربران بلاک‌شده، مرکز ایمنی، احراز هویت دو مرحله‌ای.

### تجربه اپ

صدا و هپتیک (صدای پیام، زنگ تماس، صدای نوتیف، ویبره)، ظاهر (روشن / تاریک / سیستم).

### پشتیبانی و حقوقی

راهنما، سیاست حریم خصوصی، شرایط استفاده، درباره (نسخه اپ).

### خروج

دیالوگ تأیید، سپس صفحه خوش‌آمد.

### صفحات تو در تو

**حریم خصوصی:** نمایش پروفایل / سن / فاصله / آنلاین / آخرین بازدید؛ چه کسی پروفایل را ببیند (همه / فقط مچ / فقط پریمیوم)؛ دیده شدن در دیسکاور (همه / فقط کسانی که لایک کرده‌ام / مخفی)؛ نمایش در دیسکاور و تاپ پیکس و امکان سوایپ برگشت؛ اشتراک داده برای مچینگ/آنالیتیکس/تبلیغ؛ بلاک پیام غیرمچ؛ رسید خوانده شدن.

**هشدارها:** پوش (مچ، پیام، لایک پیام، سوپرلایک، تاپ پیکس، بوست، بازدید، لایک)، ایمیل (مچ، پیام، پروموشن، آپدیت)، صدا و ویبره.

**ترجیحات دیسکاور:** سن، فاصله، دیده شدن — ذخیره در API.

---

## ۶. نکته برای تیم

چند صفحه قدیمی تنظیمات هنوز در ریپو هستند (دسترسی‌پذیری، تنظیمات تماس، تم رنگین‌کمانی و غیره) اما از هاب فعلی Settings لینک نمی‌شوند. نقشه کاربر همین سند و `AppRoutes` است.
