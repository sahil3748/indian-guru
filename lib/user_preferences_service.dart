import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserPreferencesService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserDisplayName = 'userDisplayName';
  static const String _keyUserPhotoUrl = 'userPhotoUrl';
  static const String _keyLastLoginTime = 'lastLoginTime';

  static final UserPreferencesService _instance =
      UserPreferencesService._internal();

  factory UserPreferencesService() {
    return _instance;
  }

  UserPreferencesService._internal();

  Future<void> saveUserLoginDetails(GoogleSignInAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, account.email);
    await prefs.setString(_keyUserDisplayName, account.displayName ?? '');
    await prefs.setString(_keyUserPhotoUrl, account.photoUrl ?? '');
    await prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());
  }

  Future<void> clearUserLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserDisplayName);
    await prefs.remove(_keyUserPhotoUrl);
    await prefs.remove(_keyLastLoginTime);
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail) ?? '',
      'displayName': prefs.getString(_keyUserDisplayName) ?? '',
      'photoUrl': prefs.getString(_keyUserPhotoUrl) ?? '',
      'lastLoginTime': prefs.getString(_keyLastLoginTime) ?? '',
    };
  }
}
