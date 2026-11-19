import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'analytics_service.dart';

/// Optional sign-in with Google (Firebase Auth). Projects and media stay on
/// the phone — an account only identifies the user (name, email, photo).
///
/// Needs `android/app/google-services.json` (Firebase) with the app's
/// SHA-1/SHA-256 fingerprints registered and Google enabled under
/// Authentication → Sign-in method. Without Firebase, [available] is false
/// and Settings shows accounts as unavailable.
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  bool _googleReady = false;

  /// True when Firebase is configured in this build.
  Future<bool> get available => Analytics.instance.ready;

  /// The signed-in user, or null. Emits on sign-in / sign-out.
  Stream<User?> userChanges() async* {
    if (!await available) {
      yield null;
      return;
    }
    yield* FirebaseAuth.instance.userChanges();
  }

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    // On Android the server client id comes from google-services.json
    // (the `default_web_client_id` resource), so nothing is passed here.
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  Future<OAuthCredential> _googleCredential() async {
    await _initGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google returned no ID token');
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Returns null when the user cancelled the Google account picker.
  Future<User?> signInWithGoogle() async {
    if (!await available) throw StateError('Accounts are not set up in this build');
    try {
      final cred = await FirebaseAuth.instance.signInWithCredential(await _googleCredential());
      unawaited(Analytics.instance.log('sign_in', {'method': 'google'}));
      return cred.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!await available) return;
    await FirebaseAuth.instance.signOut();
    try {
      await _initGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[account] google sign-out: $e');
    }
  }

  /// Deletes the Firebase account (Play policy: in-app account deletion).
  /// Firebase asks for a fresh sign-in first when the last one is old.
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await user.reauthenticateWithCredential(await _googleCredential());
      await user.delete();
    }
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      debugPrint('[account] google disconnect: $e');
    }
    unawaited(Analytics.instance.log('account_deleted'));
  }
}
