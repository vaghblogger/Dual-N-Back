# nback_pro

A new Flutter project.

## Firebase / Firestore

If you sign in with Google (or Apple) and see `PERMISSION_DENIED` or "Cloud Firestore API has not been used in project ... or it is disabled", enable the **Cloud Firestore API** for your Firebase project:

1. Open [Firebase Console](https://console.firebase.google.com/) and select your project (e.g. `dualnback-fac9d`).
2. Enable Firestore: go to **Build → Firestore Database** and click **Create database**, or enable the API at:  
   https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=YOUR_PROJECT_ID  
   (replace `YOUR_PROJECT_ID` with your project ID).
3. Wait a few minutes for the change to propagate, then retry.

Until Firestore is enabled, cloud sync (settings, streak, sessions) will not work, but the app works locally and the session summary will still show after each game.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
