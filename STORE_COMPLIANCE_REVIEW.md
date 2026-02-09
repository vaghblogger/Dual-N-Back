# App Store & Google Play Store Compliance Review

**App:** Dual N-Back Pro (nback_pro)  
**Reviewed:** February 2025

This document summarizes compliance gaps and required actions before submitting to **Apple App Store** and **Google Play Store**.

---

## Critical (Must Fix Before Submission)

### 1. Privacy Policy & Terms of Use URLs

**Status:** Done. App uses live GitHub Pages URLs.

**Location:** `nback_pro/lib/src/core/constants/app_strings.dart`

- `privacyPolicyUrl = 'https://vaghblogger.github.io/Dual-N-Back/privacy-policy.html'`
- `termsOfUseUrl = 'https://vaghblogger.github.io/Dual-N-Back/terms-of-use.html'`

**Requirement:**

- **Apple:** Apps must have a privacy policy and disclose data collection. You must provide a valid, publicly accessible URL in App Store Connect and in the app (e.g. Settings).
- **Google:** A legally compliant, publicly accessible privacy policy URL is required. The Data Safety form must align with this policy.

**Action (done in app):** Set the same URLs in App Store Connect and Play Console. The policy must describe:

- Data collected (e.g. Firebase Auth UID, email/display name if used, Firestore: settings, streak, session history)
- Use of data (account, sync, progress)
- Third parties (Firebase/Google, Apple Sign In)
- How users can delete data (e.g. account reset / sign out and data deletion)

---

### 2. In-App Purchases Not Implemented

**Status:** Paywall is UI-only; no store IAP integration.

**Locations:**  
`subscription_provider.dart` always returns `SubscriptionState.free`. Paywall screen buttons only dismiss; “Restore purchases” does nothing.

**Requirement:**

- **Apple:** Digital goods (subscriptions, premium features) must be sold via In-App Purchase. External payment links for digital content are not allowed.
- **Google:** Subscriptions and one-time digital purchases must use Google Play Billing.

**Action:** Integrate native IAP before release:

- **iOS:** Use StoreKit 2 or the `in_app_purchase` (or equivalent) Flutter plugin; create products in App Store Connect.
- **Android:** Use Google Play Billing via the same plugin; create products in Play Console.

Until IAP is integrated, do not present the app as offering a purchasable “Pro” subscription in store listings if the purchase cannot be completed in-app.

---

### 3. Feedback / Contact Email

**Status:** Done.

**Location:** `app_strings.dart` → `feedbackEmail = 'vaghblogger@gmail.com'`

**Action:** Use the same contact in store listing and support fields.

---

### 4. Debug / Analytics Code in Production

**Status:** Sync service sends HTTP requests to localhost in all builds.

**Location:** `nback_pro/lib/src/data/services/sync_service.dart` — `_debugLog()` posts to `http://10.0.2.2:7244/ingest/...` (Android emulator) or `http://127.0.0.1:7244/...` (iOS simulator).

**Risk:** Reviewers or automated checks may flag outbound HTTP to localhost or non-HTTPS endpoints. This should not run in release.

**Action:** Guard this logic with `kDebugMode` so it only runs in debug builds (fix applied in `sync_service.dart`).

---

## High Priority (Strongly Recommended)

### 5. Android Package Name / Application ID

**Status:** Placeholder.

**Location:** `android/app/build.gradle.kts` → `applicationId = "com.yourcompany.nback_pro"`  
Also `namespace = "com.yourcompany.nback_pro"` and manifest references.

**Action:** Replace with your real package name (e.g. `com.yourcompany.nbackpro`). Once published, this cannot be changed.

---

### 6. Android Release Permissions

**Status:** `INTERNET` added to `android/app/src/main/AndroidManifest.xml`.

**Android 13+ (API 33+):** If the app shows notification permission UI (e.g. daily reminder), ensure `POST_NOTIFICATIONS` is declared. The `flutter_local_notifications` plugin may merge it; verify in the merged manifest or add it to main if needed.

---

### 7. iOS Sign in with Apple

**Status:** Implemented and shown only on iOS when Google Sign-In is also offered — **compliant**.

**Note:** Apple requires Sign in with Apple when you offer other third-party sign-in (e.g. Google). Ensure the “Sign in with Apple” capability is enabled in the Xcode project and in the Apple Developer portal for the App ID.

---

### 8. iOS Usage Descriptions (Info.plist)

**Status:** No custom usage description keys found in `ios/Runner/Info.plist`.

**Current use:**

- Local notifications (daily reminder): No special key required for local notifications.
- No camera, microphone, or location.
- If you later add tracking (e.g. analytics that track users across apps/sites), you must add `NSUserTrackingUsageDescription` and use App Tracking Transparency.

**Action:** If you add any capability that requires a usage string (e.g. photo library, health), add the corresponding `NS*UsageDescription` key and text.

---

### 9. Developer-Only Override (Subscription State)

**Status:** Tapping version 7 times in Settings opens a “Dev: Subscription override” dialog. It is correctly gated with `kDebugMode` in `settings_screen.dart`, so it does not appear in release.

**Action:** No change required; ensure release builds are not built with debug flags.

---

## Store-Specific Checklist

### Apple App Store

- [ ] Privacy policy URL set in app and in App Store Connect.
- [ ] In-App Purchase set up for Pro subscription (and optional lifetime); products created and approved.
- [ ] Sign in with Apple offered on iOS (already implemented).
- [ ] No placeholder or example.com URLs in the binary (privacy, terms, contact).
- [ ] App Store Connect metadata: privacy questionnaire, age rating, and data use descriptions consistent with the app and privacy policy.
- [ ] If the app uses IDFA or similar tracking: ATT prompt and `NSUserTrackingUsageDescription` (not needed for current feature set).

### Google Play Store

- [ ] Privacy policy URL set in app and in Play Console.
- [ ] Google Play Billing set up for Pro subscription (and optional lifetime); products configured.
- [ ] Data Safety form completed: declare collection of account identifiers, app usage/data (e.g. settings, progress), and any data shared with Firebase/Google. Align with privacy policy.
- [ ] No placeholder or example.com URLs in the binary.
- [ ] Application ID (package name) final and not “com.yourcompany.*” placeholder.
- [ ] Target SDK and permissions (INTERNET, POST_NOTIFICATIONS if used) correct for current Play policy.

---

## Data & Privacy Summary (For Policy & Data Safety)

| Data / Feature        | Collected / Used | Where | Notes                          |
|-----------------------|------------------|-------|--------------------------------|
| Firebase Auth         | UID, optional email/name | Firebase | For account and sync           |
| Firestore             | Settings, streak, session history | Firebase (users/{uid}) | Only when signed in            |
| Local storage (Hive)  | Settings, stats, streak | Device  | Same data, local only for guest |
| Notifications         | Daily reminder time | Device / optional | No content data sent off-device for notifications |
| Sign in with Apple/Google | Per provider policies | Auth providers | Disclose in privacy policy     |

Ensure your privacy policy and Google Data Safety form accurately reflect the above and any SDKs (Firebase, etc.).

---

## Summary

| Item                          | Severity   | Action                                      |
|-------------------------------|------------|---------------------------------------------|
| Privacy / Terms URLs          | Critical   | Done (GitHub Pages URLs)                    |
| In-App Purchase               | Critical   | Integrate StoreKit / Play Billing           |
| Feedback email                | Critical   | Done (vaghblogger@gmail.com)                |
| Debug HTTP in sync_service    | Critical   | Done (kDebugMode guard)                     |
| Android package name          | High       | Done (com.vaghblogger.nback_pro)            |
| INTERNET in main manifest     | High       | Done                                        |
| Sign in with Apple            | OK         | Already compliant on iOS                    |
| Dev-only subscription override| OK         | kDebugMode-gated                            |

See [COMPLIANCE_IMPLEMENTATION_PLAN.md](COMPLIANCE_IMPLEMENTATION_PLAN.md) for implementation steps and current status. After addressing the remaining critical and high-priority items (IAP, package name, POST_NOTIFICATIONS), re-check Apple and Google developer documentation before each submission.
