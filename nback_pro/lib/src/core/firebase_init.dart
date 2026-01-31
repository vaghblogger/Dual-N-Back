/// Set to true in main() after Firebase.initializeApp() succeeds.
/// Used so AuthService can avoid touching Firebase when not configured.
bool firebaseInitialized = false;
