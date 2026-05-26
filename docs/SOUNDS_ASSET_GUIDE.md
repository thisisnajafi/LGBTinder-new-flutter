# Sound Assets Guide (Module 9)

The app expects **7 WAV files** referenced by `lgbtinder-backend/config/chat_sounds.php` and `SoundService` in Flutter.

## Required files

| File | Purpose | Used for |
|------|---------|----------|
| `message_default.wav` | Default message ping | In-app message sound + default notification |
| `message_soft.wav` | Soft pop | Message + notification option |
| `message_pop.wav` | Short pop | Message + notification option |
| `message_chime.wav` | Light chime | Message + notification option |
| `ringtone_default.wav` | Default incoming call | CallKit / Android incoming call |
| `ringtone_pride.wav` | Pride Pulse ringtone | Incoming call option |
| `ringtone_classic.wav` | Classic phone ring | Incoming call option |

## Where files must live

1. **Flutter assets:** `lgbtindernew/assets/sounds/*.wav` (declared in `pubspec.yaml`)
2. **Android raw resources:** `lgbtindernew/android/app/src/main/res/raw/*.wav` (same basename, no extension in code — e.g. `message_default`)

iOS CallKit uses the asset path from Flutter where applicable; Android notifications and CallKit use `res/raw/`.

## Technical specs

- **Format:** WAV (PCM), mono preferred
- **Sample rate:** 44.1 kHz (or 22.05 kHz)
- **Duration:** Message/notification: **0.2–0.8 s**; ringtones: **1.5–3 s** (loop-friendly)
- **Size:** Keep each file **under ~100 KB**
- **Naming:** Exact IDs above — must match backend catalog `id` fields

## Current placeholders

Run from repo root:

```powershell
python lgbtindernew/scripts/generate_default_sounds.py
```

This generates simple synthesized tones (royalty-free). They work for development; replace with polished SFX for production.

## Recommended free sources (commercial use)

All below allow commercial use; check each license for attribution requirements.

1. **Mixkit** — https://mixkit.co/free-sound-effects/notification/  
   No attribution required. Download WAV/MP3, rename to match table above, convert to WAV if needed.

2. **Pixabay** — https://pixabay.com/sound-effects/search/notification/  
   Free for commercial use (Pixabay license).

3. **Kenney.nl** — https://kenney.nl/assets?q=audio  
   CC0 game audio packs (good for UI pops).

4. **Freesound** — https://freesound.org/  
   Filter by **CC0** license only. Many require attribution (CC BY).

### Suggested search terms

- Messages: `soft notification`, `message pop`, `ui chime`, `dm ping`
- Calls: `phone ring`, `incoming call`, `classic telephone ring`
- Pride ringtone: `uplifting alert`, `positive notification loop`

## Replace workflow

1. Download or export WAV with exact filename from the table.
2. Copy into `assets/sounds/`.
3. Copy the same files into `android/app/src/main/res/raw/`.
4. Run `flutter clean && flutter pub get` if assets do not appear.
5. Test: **Settings → Sounds** — preview each option; send a test message from another account.

## Optional extras (not in Module 9 catalog)

These are **not** wired yet but listed in `ASSETS_REQUIREMENTS.md` for future features:

- `match_sound.wav` — match celebration
- `like_sound.wav` / `dislike_sound.wav` — swipe feedback
- `error_sound.wav` — error toast

If you gather these, place them in `assets/sounds/` and we can wire them in a follow-up task.
