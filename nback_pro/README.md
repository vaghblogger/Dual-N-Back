# nback_pro

A new Flutter project.

## Firebase / Firestore

This app uses a **named** Firestore database `nbackpro` (see `lib/src/data/services/sync_service.dart`). You must create that database and deploy rules to it, or you will get `PERMISSION_DENIED` when signed in.

### One-time setup

**1. Create the named database (if needed)**

- Open [Firebase Console](https://console.firebase.google.com/) → your project (e.g. `dualnback-fac9d`).
- Go to **Build → Firestore Database**.
- If you only see one database (e.g. “(default)”): click **Create database** (or **Add database**).
- Set **Database ID** to exactly: `nbackpro` (lowercase, no spaces).
- Choose **Standard** and a location, then **Create**. For Security Rules you can pick “Start in production mode”; we deploy rules in step 2.

**2. Deploy rules to `nbackpro`**

From the **`nback_pro`** directory (where `firebase.json` and `firestore.rules` live):

```bash
cd path/to/nback_pro
firebase deploy --only firestore:nbackpro
```

You should see: `✔ firestore: released rules firestore.rules to cloud.firestore`.

**3. (Optional) Confirm in Console**

- In Firebase Console → **Firestore Database**, use the **database dropdown** at the top (next to “Cloud Firestore”) and select **nbackpro**.
- Open the **Rules** tab and confirm the rules allow read/write for `users/{uid}` when `request.auth.uid == uid`. Then click **Publish** if you made any change.

### If you still see PERMISSION_DENIED

- Ensure you deployed with `firestore:nbackpro` (not only `firestore:rules`) so rules apply to the named database.
- Ensure the database ID in Console is exactly `nbackpro` (same as in `sync_service.dart`).
- Wait 1–2 minutes after deploying rules, then fully restart the app and sign in again.

### Enabling Firestore API

If you see “Cloud Firestore API has not been used...” or “is disabled”, enable the API:

- [Enable Firestore API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=dualnback-fac9d) for your project (replace project ID if different).
- Or in Firebase Console: **Build → Firestore Database** and complete creating a database.

Until Firestore is set up, cloud sync will not work, but the app works locally and the session summary still shows after each game.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
