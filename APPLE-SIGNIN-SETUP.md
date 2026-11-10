# Sign in with Apple – setup steps for LGBTFinder (iOS)

What the code does now (local commits, not pushed):

- **iOS app:** the login and register screens show **Sign in with Apple** on iOS, and the Google button is hidden there. Android still shows Google. The app uses the `sign_in_with_apple` package with a SHA-256 nonce, and sends the Apple **identity token**, the raw nonce, and the first-login name to the backend.
- **iOS Runner:** `ios/Runner/Runner.entitlements` now has `com.apple.developer.applesignin = [Default]`.
- **Backend:** `POST /api/auth/apple` checks the identity token against Apple's public keys (`https://appleid.apple.com/auth/keys`). It checks `iss = https://appleid.apple.com`, `aud` against `APPLE_CLIENT_IDS`, `exp`, and the nonce. Then it logs the user in, links the Apple ID to an existing user, or creates a new user. `DELETE /api/auth/apple/unlink` removes the link.

Bundle IDs in the Xcode project (`ios/Runner.xcodeproj/project.pbxproj`):

| Build | Bundle ID |
|---|---|
| Production (Release/Profile/Debug-production) | `com.lgbtfinder` |
| Staging | `com.lgbtfinder.staging` |
| Development | `com.lgbtfinder.dev` |

The native iOS flow does **not** need a Services ID, a Sign in with Apple key (.p8), a Key ID or the Team ID on the backend. The backend only verifies Apple's signed token, and the audience is the bundle ID. You need those items only for a web or Android "Sign in with Apple" flow, or for revoking Apple tokens on the server. Neither is implemented, so the steps for them below are marked optional.

---

## A. Apple Developer portal (https://developer.apple.com/account)

1. Sign in with the account that owns the LGBTFinder app, then open **Certificates, Identifiers & Profiles → Identifiers**.
2. Open the App ID **`com.lgbtfinder`**. If it doesn't exist yet, create it: **+ → App IDs → App**, Bundle ID **Explicit** = `com.lgbtfinder`.
3. Under **Capabilities**, tick **Sign In with Apple**. Click **Edit** next to it, choose **Enable as a primary App ID**, then **Save**. Confirm with **Save** at the top.
4. *(Only if you build and sign the staging or dev iOS apps on a device)* Repeat steps 2–3 for `com.lgbtfinder.staging` and `com.lgbtfinder.dev`. For each one, choose **Group with an existing primary App ID → com.lgbtfinder**, so the same Apple user gets the same account across builds.
5. Open **Profiles** and regenerate (Edit → Save → Download) every provisioning profile for these App IDs (development, ad hoc, App Store). Old profiles don't include the new entitlement, and signing will fail with "Provisioning profile doesn't include the com.apple.developer.applesignin entitlement". If Xcode uses **Automatically manage signing**, it does this for you in step B.
6. Write down your **Team ID** (top right of the portal, or **Membership details**). The current backend doesn't need it. Keep it for the optional steps.
7. *(Optional, not needed now)* **Services ID**: create one only if you later add Sign in with Apple on the web or Android. Use **Identifiers → + → Services IDs**, for example `com.lgbtfinder.signin`. Enable Sign In with Apple, set the primary App ID to `com.lgbtfinder`, and add the domain `api.lgbtfinder.com` and its return URL. Then add that Services ID to `APPLE_CLIENT_IDS` (step C2).
8. *(Optional, not needed now)* **Key (.p8)**: you need one only for server-side token revocation or a web flow. Use **Keys → +**, name it, tick **Sign in with Apple**, **Configure → primary App ID com.lgbtfinder**, then **Continue → Register → Download**. You can download the `.p8` only once. Write down its **Key ID**. The backend doesn't read any key variables yet, so don't add any.

## B. Xcode (on a Mac)

1. Open `ios/Runner.xcworkspace` (not the `.xcodeproj`). Run `flutter pub get`, then `cd ios && pod install` first.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Check that the **Team** is your Apple team and each build configuration has the right bundle ID (table above).
4. Click **+ Capability → Sign In with Apple**. The entitlement is already in `Runner/Runner.entitlements`, so Xcode should show the capability as present. If Xcode adds it again, keep one entry. `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` is already set for every Runner configuration.
5. Leave **Push Notifications** (`aps-environment`) in place. The same entitlements file has both.
6. **Info.plist:** Sign in with Apple doesn't need any Info.plist key or URL scheme. Leave `ios/Runner/Info.plist` as it is. There is no Google URL scheme in it, and none is needed because Google is hidden on iOS.

## C. Backend .env (server: `/var/www/backend/.env`, and local `.env` for testing)

1. The backend reads exactly one new variable: **`APPLE_CLIENT_IDS`**, a comma-separated list of accepted token audiences.
2. Set it on the server:
   ```
   APPLE_CLIENT_IDS=com.lgbtfinder
   ```
   - If you also want the staging or dev iOS builds to sign in against this server, use
     `APPLE_CLIENT_IDS=com.lgbtfinder,com.lgbtfinder.staging,com.lgbtfinder.dev`
   - If you add a Services ID later (A7), append it to the list.
   - If you don't set it, the default from `config/services.php` is `com.lgbtfinder`.
3. Rebuild the config cache after editing `.env`: `php artisan config:cache` (the deploy already runs `scripts/rebuild-production-cache.sh`).
4. The server must reach `https://appleid.apple.com/auth/keys` over HTTPS (outbound). Check with
   `curl -sS https://appleid.apple.com/auth/keys | head -c 200`.
5. No migration is needed. Apple links are stored in the existing `social_accounts` table (`provider = apple`), and `users.auth_provider = apple` for new Apple users.
6. Deploy: push the backend commit to `main`. GitHub Actions deploys it, and this needs your approval.

## D. App Store Connect

1. In **App Store Connect → Apps → LGBTFinder**, nothing has to be switched on for Sign in with Apple. It comes from the App ID capability (A3).
2. **Review notes:** say that iOS sign-in options are email and **Sign in with Apple** (Guideline 4.8 is met: no third-party login is offered on iOS without Apple).
3. **Account deletion (Guideline 5.1.1(v)):** apps that create accounts must let users delete them in the app. I found no account-deletion call in the Flutter app's `lib/` (the backend has account-management routes), so check this before review. Apple also asks apps to revoke Sign in with Apple tokens on deletion. That needs the optional key (A8) and a server change, which hasn't been implemented.
4. **Private relay email:** if a user hides their email, Apple gives an `@privaterelay.appleid.com` address. Mail to it goes through only if you register your sending domain. In the portal, open **Certificates, Identifiers & Profiles → Services → Sign in with Apple for Email Communication → Configure**. Add the domain **`lgbtfinder.com`** and the sender **`noreply@lgbtfinder.com`** (the `MAIL_FROM_ADDRESS`). SPF must pass for that domain. Resend's SPF is on `send.lgbtfinder.com`, so check that Apple shows the domain as verified.

## E. Firebase

1. Sign in with Apple doesn't need anything in Firebase. The app doesn't use Firebase Auth. The backend verifies Apple's token directly.
2. This is separate from Apple: Google sign-in on Android needs the **release SHA-1 `53:11:3F:73:E2:CE:A7:A3:8E:4D:D6:BC:44:10:EC:E0:13:8B:77:79`** added to the Firebase Android app `com.lgbtfinder` (project `lgbtfinder-fa8e5`). If you publish through Google Play, also add the **Play App Signing** SHA-1 from Play Console → Setup → App signing. Then download the new `google-services.json` into `android/app/src/production/`.

## F. How to test

1. On a Mac with Xcode: `flutter pub get`, then `cd ios && pod install && cd ..`.
2. Run on a **real iPhone** signed in to iCloud. The simulator works too if it is signed in to an Apple ID (Settings → Sign in).
   `flutter run --flavor production` (Xcode scheme **production**; schemes `development`, `staging`, `production` exist in `ios/Runner.xcodeproj/xcshareddata/xcschemes`).
3. On the login screen, check that **Sign in with Apple** shows and **Continue with Google** does not.
4. Tap **Sign in with Apple** and choose **Share My Email** or **Hide My Email**. Expected result: a new account is created, the app goes to profile completion, and the first and last name are pre-filled from Apple.
5. Log out and sign in with Apple again. Apple no longer sends the name, and the same account should log in.
6. To repeat the first-login case (name and email sent again), go to the iPhone's **Settings → [your name] → Sign-In & Security → Sign in with Apple → LGBTFinder → Stop Using Apple ID**, then sign in again.
7. Backend checks without a device (from the backend folder): `php artisan test tests/Feature/Api/AppleAuthTest.php`. It covers a new user with a name, a returning user without a name, linking a verified email, a missing email, wrong audience, nonce mismatch, an expired token, a forged signature, and validation.
8. Quick server check after deploy: `curl -s -X POST https://api.lgbtfinder.com/api/auth/apple -H "Accept: application/json" -d identity_token=x` should return HTTP 400 `INVALID_APPLE_TOKEN`, not 404. A 503 `APPLE_NOT_CONFIGURED` means `APPLE_CLIENT_IDS` is empty.
9. If Apple shows error 1000 (`AuthorizationErrorCode.unknown`) on the device, the capability or provisioning profile is missing (A3/A5/B4), or the device isn't signed in to iCloud.
