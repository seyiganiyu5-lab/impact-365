import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import 'auth_widgets.dart';

/// Google sign-in **inside the app**: Android's account picker (or the iOS
/// sheet) instead of a web page. Google then shows "IMPACT-365", never the
/// Supabase address, and there is no browser back-and-forth.
///
/// Needs, in Google Cloud: a Web client (its ID goes in env.json as
/// GOOGLE_WEB_CLIENT_ID and in Supabase), an Android client (package name +
/// SHA-1) and, for iPhone, an iOS client (GOOGLE_IOS_CLIENT_ID).
/// Without them the app falls back to the web page.
class GoogleNativeSignIn {
  GoogleNativeSignIn._();

  static bool _isClientId(String id) =>
      id.endsWith('.apps.googleusercontent.com') && !id.contains(' ');

  /// True when this phone can use the in-app Google sign-in.
  static bool get available {
    if (kIsWeb || !_isClientId(Env.googleWebClientId)) return false;
    if (Platform.isAndroid) return true;
    if (Platform.isIOS) return _isClientId(Env.googleIosClientId);
    return false;
  }

  static Future<void>? _ready;

  static Future<void> _initialize() =>
      _ready ??= GoogleSignIn.instance.initialize(
        serverClientId: Env.googleWebClientId,
        clientId: !kIsWeb && Platform.isIOS ? Env.googleIosClientId : null,
      );

  /// Shows Google's account picker and signs in to Supabase with the chosen
  /// account. Returns false if the person closed the picker.
  static Future<bool> signIn() async {
    await _initialize();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token');
    }
    // Supabase checks the token with Google and creates / opens the account.
    await Supabase.instance.client.auth
        .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
        .withAuthTimeout();
    return true;
  }

  /// After signing out of the app, forget the Google account on this phone
  /// so the picker asks again next time.
  static Future<void> signOutQuietly() async {
    if (_ready == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
