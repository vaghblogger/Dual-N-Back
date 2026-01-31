import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase_init.dart';

class AuthService {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    if (!firebaseInitialized) return null;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
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
    if (firebaseInitialized) {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
  }
}
