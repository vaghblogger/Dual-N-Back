import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase_init.dart';

/// Web client ID for Google Sign-In with Firebase on Android. Get it from
/// Google Cloud Console → your project → APIs & Services → Credentials →
/// OAuth 2.0 Client IDs → Web client (or create one). Can be set via
/// --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
const String _kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

const _kAuthChannel = MethodChannel('com.yourcompany.nback_pro/auth');

class AuthService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  /// Gets GoogleSignIn, using Web client ID from env, or from Android
  /// (default_web_client_id) when google-services.json has oauth_client.
  Future<GoogleSignIn> _getGoogleSignIn() async {
    if (_googleSignIn != null) return _googleSignIn!;
    String? clientId = _kGoogleWebClientId.isEmpty ? null : _kGoogleWebClientId;
    if (clientId == null && Platform.isAndroid) {
      try {
        clientId = await _kAuthChannel.invokeMethod<String>('getDefaultWebClientId');
      } catch (_) {}
    }
    _googleSignIn = GoogleSignIn(serverClientId: clientId);
    return _googleSignIn!;
  }

  FirebaseAuth get _firebaseAuth {
    if (!firebaseInitialized) {
      throw StateError('Firebase not initialized');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  User? get currentUser =>
      firebaseInitialized ? _firebaseAuth.currentUser : null;
  bool get isGuest => currentUser == null;
  String? get displayName =>
      currentUser?.displayName ?? currentUser?.email;

  Stream<User?> get authStateChanges =>
      firebaseInitialized ? _firebaseAuth.authStateChanges() : Stream.value(null);

  Future<User?> signInWithGoogle() async {
    if (!firebaseInitialized) {
      throw StateError(
        'Firebase is not configured. Add google-services.json (Android) and '
        'GoogleService-Info.plist (iOS).',
      );
    }
    try {
      final googleSignIn = await _getGoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (Platform.isAndroid) {
          throw StateError(
            _kGoogleSignInFailedMessage,
          );
        }
        return null;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && Platform.isAndroid) {
        throw StateError(_kGoogleSignInFailedMessage);
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      return userCred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    if (!Platform.isIOS) return null;
    // Apple Sign-In requires sign_in_with_apple package - add when needed
    return null;
  }

  Future<void> signOut() async {
    if (!firebaseInitialized) return;
    try {
      final googleSignIn = await _getGoogleSignIn();
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (_) {
      // Google Sign-In may not be initialized or already disconnected
    }
    await _firebaseAuth.signOut();
  }
}

/// Shown when Google Sign-In fails on Android (no account picker or sign-in error).
const String _kGoogleSignInFailedMessage =
    'Google Sign-In needs a Web client ID. '
    '1) In Firebase Console add a Web app, then re-download google-services.json for Android and replace android/app/google-services.json. '
    '2) Or get the Web client ID from Google Cloud Console → Credentials → OAuth 2.0 Web client, then run: flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID';
