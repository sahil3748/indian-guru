import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'user_preferences_service.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // Course management
      'https://www.googleapis.com/auth/classroom.courses',
      'https://www.googleapis.com/auth/classroom.courses.readonly',

      // Roster management
      'https://www.googleapis.com/auth/classroom.rosters',
      'https://www.googleapis.com/auth/classroom.rosters.readonly',
      'https://www.googleapis.com/auth/classroom.profile.emails',
      'https://www.googleapis.com/auth/classroom.profile.photos',

      // Announcements
      'https://www.googleapis.com/auth/classroom.announcements',
      'https://www.googleapis.com/auth/classroom.announcements.readonly',

      // Coursework (including quizzes)
      'https://www.googleapis.com/auth/classroom.coursework.students',
      'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',

      // Topics
      'https://www.googleapis.com/auth/classroom.topics',
      'https://www.googleapis.com/auth/classroom.topics.readonly',

      // Student submissions
      'https://www.googleapis.com/auth/classroom.student-submissions.students',
      'https://www.googleapis.com/auth/classroom.student-submissions.students.readonly',
      'https://www.googleapis.com/auth/classroom.student-submissions.me',
      'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',

      // Guardian access
      'https://www.googleapis.com/auth/classroom.guardianlinks.students',
      'https://www.googleapis.com/auth/classroom.guardianlinks.me.readonly',

      // Push notifications
      'https://www.googleapis.com/auth/classroom.push-notifications',

      // Drive access for classroom materials
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
      // Full Drive access (optional, requires additional verification)
      'https://www.googleapis.com/auth/drive',
    ],
    // Only provide clientId on web platform
    clientId: kIsWeb
        ? '1060232368338-ns1b8bmbh62197gjjnec6en1j67sg3bd.apps.googleusercontent.com'
        : null,
  );

  final UserPreferencesService _prefsService = UserPreferencesService();

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
        await _prefsService.saveUserLoginDetails(silentSignIn);
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

        // Save user details to SharedPreferences
        await _prefsService.saveUserLoginDetails(signedInAccount);
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
      await _prefsService.clearUserLoginDetails();
      print('✅ Successfully signed out from Google');
    } catch (error) {
      print('❌ Error signing out: $error');
    }
  }

  Future<bool> isSignedIn() async {
    return await _prefsService.isUserLoggedIn();
  }

  Future<Map<String, String>> getUserDetails() async {
    return await _prefsService.getUserDetails();
  }
}
