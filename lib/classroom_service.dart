import 'package:googleapis/classroom/v1.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class ClassroomService {
  Future<ClassroomApi?> getClassroomApi(
    GoogleSignIn googleSignIn,
    GoogleSignInAccount account,
  ) async {
    print('🔄 Attempting to get Classroom API for account: ${account.email}');
    try {
      // Get the HTTP client with auth
      print('🔄 Getting authenticated HTTP client...');
      final httpClient = await googleSignIn.authenticatedClient();

      if (httpClient == null) {
        print('❌ Failed to get authenticated HTTP client');
        return null;
      }

      print('✅ Successfully obtained authenticated HTTP client');
      return ClassroomApi(httpClient);
    } catch (error) {
      print('❌ Error creating Classroom API client: $error');
      print(
        '💡 Stack trace: ${error is Error ? error.stackTrace : 'Not available'}',
      );
      return null;
    }
  }

  Future<List<Course>?> listCourses(ClassroomApi classroomApi) async {
    print('🔄 Fetching courses from Google Classroom');
    try {
      final courses = await classroomApi.courses.list();
      if (courses.courses != null) {
        print('✅ Successfully fetched ${courses.courses!.length} courses:');
        for (var course in courses.courses!) {
          print('📚 Course: ${course.name} (ID: ${course.id})');
          print('   Section: ${course.section ?? 'N/A'}');
          print('   State: ${course.courseState ?? 'N/A'}');
          print('   Link: ${course.alternateLink ?? 'N/A'}');
        }
        return courses.courses?.toList();
      } else {
        print('ℹ️ No courses found for this account');
        return [];
      }
    } catch (error) {
      print('❌ Error listing courses: $error');
      print(
        '💡 Stack trace: ${error is Error ? error.stackTrace : 'Not available'}',
      );
      return null;
    }
  }
}
