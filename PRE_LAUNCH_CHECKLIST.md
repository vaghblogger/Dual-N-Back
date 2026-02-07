# Pre-Launch Checklist: Play Store & App Store

Use this list before submitting **Dual N-Back Pro** to Google Play Store and Apple App Store. Tick each item when done.

---

## Critical (must do)

### 1. In-App Purchase (IAP)

- [ ] Add IAP Flutter package (e.g. `in_app_purchase`) to `pubspec.yaml`.
- [ ] **iOS:** In App Store Connect, create In-App Purchase products (e.g. Pro Monthly, Pro Yearly, optional Lifetime). Enable In-App Purchase in Xcode for the app target.
- [ ] **Android:** In Play Console, create the same subscription products and configure billing.
- [ ] In app: replace hardcoded `SubscriptionState.free` in `subscription_provider.dart` with real purchase status from the IAP plugin.
- [ ] In app: wire paywall “Monthly”, “Yearly”, “Lifetime” buttons to the plugin’s purchase flow.
- [ ] In app: wire “Restore purchases” to the plugin’s restore and refresh subscription state.
- [ ] Test purchase and restore on iOS (sandbox) and Android (test account).

*Ref: [COMPLIANCE_IMPLEMENTATION_PLAN.md](COMPLIANCE_IMPLEMENTATION_PLAN.md) § 2, [PaymentGateway.md](PaymentGateway.md).*

---

### 2. Firebase (if you use it)

- [x] In Firebase Console, add an Android app with package name `com.vaghblogger.nback_pro` (if not already).
- [x] Download the new `google-services.json` and replace `nback_pro/android/app/google-services.json` if the current file was for the old package.

---

## High (strongly recommended)

### 3. Android: notification permission (Android 13+)

- [ ] Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to `nback_pro/android/app/src/main/AndroidManifest.xml` (if not already present).
- [ ] Confirm the app requests notification permission when the user enables the daily reminder (e.g. via `notification_service.requestPermissions()`).

*Ref: [COMPLIANCE_IMPLEMENTATION_PLAN.md](COMPLIANCE_IMPLEMENTATION_PLAN.md) § 4.*

---

## App Store Connect (Apple)

- [ ] Create the app in App Store Connect (if not already).
- [ ] Set **Privacy Policy URL** to: `https://vaghblogger.github.io/Dual-N-Back/privacy-policy.html`
- [ ] Set **Terms of Use (EULA)** or terms URL to: `https://vaghblogger.github.io/Dual-N-Back/terms-of-use.html`
- [ ] Complete **App Privacy** questionnaire (data collection, usage, tracking) to match the app and your [privacy policy](https://vaghblogger.github.io/Dual-N-Back/privacy-policy.html).
- [ ] Set **Age Rating** (questionnaire).
- [ ] Add **Support URL** and/or contact (e.g. `vaghblogger@gmail.com` or a support page).
- [ ] Fill in **metadata**: app name, subtitle, description, keywords, screenshots, icon.
- [ ] Ensure **Sign in with Apple** capability is enabled for the App ID in Apple Developer portal and in Xcode.
- [ ] Upload build (Archive and distribute via Xcode or CI).

*Ref: [STORE_COMPLIANCE_REVIEW.md](STORE_COMPLIANCE_REVIEW.md) Apple section.*

---

## Play Console (Google)

- [ ] Create the app in Play Console (if not already).
- [ ] Set **Privacy policy** URL to: `https://vaghblogger.github.io/Dual-N-Back/privacy-policy.html`
- [ ] Complete **Data safety** form: declare what data you collect (account IDs, app data like settings/progress), and that you share with Firebase/Google. Align with your [privacy policy](https://vaghblogger.github.io/Dual-N-Back/privacy-policy.html).
- [ ] Confirm **Application ID** is `com.vaghblogger.nback_pro` (no `com.yourcompany.*`).
- [ ] Set **Target SDK** and ensure **INTERNET** (and **POST_NOTIFICATIONS** if you use reminders) are correct for current Play policy.
- [ ] Fill in **Store listing**: title, short description, full description, screenshots, icon, contact email (e.g. vaghblogger@gmail.com).
- [ ] Upload release build (AAB).

*Ref: [STORE_COMPLIANCE_REVIEW.md](STORE_COMPLIANCE_REVIEW.md) Google section.*

---

## Final checks

- [x] No placeholder or example.com URLs in the app (privacy, terms, contact are all real).
- [x] Release build: no debug-only subscription override visible (7-tap is already gated with `kDebugMode`).
- [ ] Test on a real device: sign-in, sync, daily reminder, and (after IAP) paywall purchase and restore.

---

## Already done (no action needed)

| Item | Status |
|------|--------|
| Privacy Policy & Terms URLs in app | Set to GitHub Pages |
| Feedback email in app | vaghblogger@gmail.com |
| Debug HTTP in sync_service | Guarded with kDebugMode |
| INTERNET in main Android manifest | Added |
| Android package name | com.vaghblogger.nback_pro |
| Sign in with Apple on iOS | Implemented |
| Dev subscription override | Debug-only |

---

*For more detail, see [STORE_COMPLIANCE_REVIEW.md](STORE_COMPLIANCE_REVIEW.md) and [COMPLIANCE_IMPLEMENTATION_PLAN.md](COMPLIANCE_IMPLEMENTATION_PLAN.md).*
