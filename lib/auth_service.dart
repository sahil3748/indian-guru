import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.courses',
      'https://www.googleapis.com/auth/classroom.rosters.readonly',
      'https://www.googleapis.com/auth/classroom.profile.emails',
    ],
    // Only provide clientId on web platform
    clientId: kIsWeb
        ? '1060232368338-ns1b8bmbh62197gjjnec6en1j67sg3bd.apps.googleusercontent.com'
        : null,
  );

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      print('🔄 Initializing Google Sign-In with scopes...');
      print('📝 Requested scopes: ${_googleSignIn.scopes}');
      print('📱 Platform: ${kIsWeb ? 'Web' : 'Mobile'}');

      // First try silent sign in
      final silentSignIn = await _googleSignIn.signInSilently();
      if (silentSignIn != null) {
        print('✅ Silent sign-in successful');
        return silentSignIn;
      }

      print('🔄 Silent sign-in failed, attempting interactive sign-in...');
      final signedInAccount = await _googleSignIn.signIn();

      if (signedInAccount != null) {
        print('✅ Sign-in successful');
        print('📧 Account email: ${signedInAccount.email}');
        print('👤 Account display name: ${signedInAccount.displayName}');

        // Get authentication
        final googleAuth = await signedInAccount.authentication;
        print('🔑 Access token obtained: ${googleAuth.accessToken != null}');
        print('🔑 ID token obtained: ${googleAuth.idToken != null}');
      } else {
        print('❌ Sign-in cancelled or failed');
      }

      return signedInAccount;
    } catch (error) {
      print('❌ Error signing in with Google: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Successfully signed out from Google');
    } catch (error) {
      print('❌ Error signing out: $error');
    }
  }
}
