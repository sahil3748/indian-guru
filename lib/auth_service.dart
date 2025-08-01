import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      'https://www.googleapis.com/auth/classroom.student-submissions.students.readonly',
      'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',

      // Guardian access
      'https://www.googleapis.com/auth/classroom.guardianlinks.students',
      'https://www.googleapis.com/auth/classroom.guardianlinks.me.readonly',

      // Push notifications
      'https://www.googleapis.com/auth/classroom.push-notifications',

      // Drive access for classroom materials
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive.file',
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

        try {
          // Get authentication
          final googleAuth = await signedInAccount.authentication;
          print('🔑 Access token obtained: ${googleAuth.accessToken != null}');
          print('🔑 ID token obtained: ${googleAuth.idToken != null}');
        } catch (authError) {
          print('❌ Authentication error: $authError');
          if (authError.toString().contains('people.googleapis.com')) {
            throw Exception(
              'People API is not enabled. Please enable it in the Google Cloud Console.',
            );
          }
          rethrow;
        }
      } else {
        print('❌ Sign-in cancelled or failed');
      }

      return signedInAccount;
    } catch (error) {
      print('❌ Error signing in with Google: $error');
      rethrow; // Rethrow the error so it can be handled by the UI
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
