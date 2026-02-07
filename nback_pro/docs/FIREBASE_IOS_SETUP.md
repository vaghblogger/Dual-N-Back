# Add iOS to Firebase

Use this guide to register your iOS app in the same Firebase project you use for Android, then wire the app so Firebase (Auth, Firestore) works on iOS.

---

## 1. Open Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Open the **same project** you use for Android (the one with `com.vaghblogger.nback_pro`).

---

## 2. Add an iOS app to the project

1. On the project overview page, click the **iOS** icon (or “Add app” → “iOS”).
2. **Apple bundle ID**  
   Enter the bundle ID your iOS app uses in Xcode.  
   - Current value in this project: **`com.yourcompany.nbackPro`**.  
   - Recommended for consistency with Android: **`com.vaghblogger.nbackPro`** (or `com.vaghblogger.nback_pro`; iOS often uses no underscore).  
   - If you change it, you must set the same ID in Xcode (see step 5 below).
3. **App nickname** (optional): e.g. `N-Back Pro iOS`.
4. **App Store ID**: leave blank until you have one from App Store Connect.
5. Click **Register app**.

---

## 3. Download `GoogleService-Info.plist`

1. On the next screen, click **Download GoogleService-Info.plist**.
2. Save the file somewhere you can find it (e.g. Downloads).

---

## 4. Add the file to your Flutter iOS app

1. **Copy** the downloaded `GoogleService-Info.plist` into the iOS Runner folder:
   ```text
   nback_pro/ios/Runner/GoogleService-Info.plist
   ```
   So the path is:  
   `nback_pro/ios/Runner/GoogleService-Info.plist`

2. **Add it to the Xcode project** so it’s included in the app bundle:
   - Open the iOS project in Xcode:
     ```bash
     open nback_pro/ios/Runner.xcworkspace
     ```
   - In the left sidebar, select the **Runner** group (under Runner).
   - Right‑click **Runner** → **Add Files to "Runner"…**.
   - Choose `GoogleService-Info.plist` (from `ios/Runner/`).
   - Leave **Copy items if needed** unchecked (file is already in Runner).
   - Ensure the **Runner** target is checked.
   - Click **Add**.

3. Confirm the file appears under **Runner** in the project navigator and is listed under **Runner** target → **Build Phases** → **Copy Bundle Resources**. If it’s not under Copy Bundle Resources, drag `GoogleService-Info.plist` into that section.

---

## 5. Match bundle ID (if you changed it in Firebase)

If you registered the iOS app in Firebase with a bundle ID other than `com.yourcompany.nbackPro` (e.g. `com.vaghblogger.nbackPro`), set the same ID in Xcode:

1. In Xcode, select the **Runner** project (blue icon) in the sidebar.
2. Select the **Runner** target.
3. Open the **Signing & Capabilities** tab.
4. Set **Bundle Identifier** to the same value you used in Firebase (e.g. `com.vaghblogger.nbackPro`).

You can also change it in `ios/Runner.xcodeproj/project.pbxproj` by replacing `com.yourcompany.nbackPro` with your chosen bundle ID.

---

## 6. Rebuild and run

From the project root:

```bash
cd nback_pro
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

Pick your iOS device or simulator when prompted. Firebase (Auth, Firestore) should now work on iOS; sign-in and sync will use the same Firebase project as Android.

---

## Quick checklist

- [ ] Firebase Console: added iOS app with your chosen bundle ID.
- [ ] Downloaded `GoogleService-Info.plist`.
- [ ] Placed it in `nback_pro/ios/Runner/GoogleService-Info.plist`.
- [ ] Added the file to the Runner target in Xcode (Copy Bundle Resources).
- [ ] Bundle ID in Xcode matches the one registered in Firebase.
- [ ] `flutter run` and test sign-in/sync on iOS.

---

## Troubleshooting

- **“No Firebase App ‘[DEFAULT]’ has been created”**  
  Usually means the app can’t find `GoogleService-Info.plist`. Confirm the file is in `ios/Runner/` and is in the Runner target’s **Copy Bundle Resources**.

- **Google Sign-In on iOS**  
  If you use Google Sign-In, ensure the iOS app has the correct URL scheme and that the Web client ID / OAuth client for iOS is configured in Google Cloud (and in Firebase if required). Your app already uses a Web client ID from env or Android; iOS may need the same or an iOS OAuth client.

- **Sign in with Apple**  
  You already have Sign in with Apple set up (entitlements + capability). No extra Firebase step needed for Apple Sign-In.
