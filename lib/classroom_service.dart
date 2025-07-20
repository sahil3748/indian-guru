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

  // Fetch course announcements (Stream)
  Future<List<Announcement>?> listAnnouncements(
    ClassroomApi classroomApi,
    String courseId,
  ) async {
    print('🔄 Fetching announcements for course: $courseId');
    try {
      final announcements = await classroomApi.courses.announcements.list(
        courseId,
      );
      print(
        '✅ Successfully fetched ${announcements.announcements?.length ?? 0} announcements',
      );
      return announcements.announcements?.toList();
    } catch (error) {
      print('❌ Error listing announcements: $error');
      return null;
    }
  }

  // Fetch course work
  Future<List<CourseWork>?> listCourseWork(
    ClassroomApi classroomApi,
    String courseId,
  ) async {
    print('🔄 Fetching coursework for course: $courseId');
    try {
      final courseWork = await classroomApi.courses.courseWork.list(courseId);
      print(
        '✅ Successfully fetched ${courseWork.courseWork?.length ?? 0} coursework items',
      );
      return courseWork.courseWork?.toList();
    } catch (error) {
      print('❌ Error listing coursework: $error');
      return null;
    }
  }

  // Fetch course students and teachers
  Future<Map<String, List<Student>>?> listPeople(
    ClassroomApi classroomApi,
    String courseId,
  ) async {
    print('🔄 Fetching people for course: $courseId');
    try {
      final students = await classroomApi.courses.students.list(courseId);
      final teachers = await classroomApi.courses.teachers.list(courseId);

      print(
        '✅ Successfully fetched ${students.students?.length ?? 0} students and ${teachers.teachers?.length ?? 0} teachers',
      );

      return {
        'students': students.students?.toList() ?? [],
        'teachers':
            teachers.teachers
                ?.map(
                  (t) => Student(
                    userId: t.userId,
                    profile: UserProfile(
                      name: t.profile?.name,
                      emailAddress: t.profile?.emailAddress,
                      photoUrl: t.profile?.photoUrl,
                    ),
                  ),
                )
                .toList() ??
            [],
      };
    } catch (error) {
      print('❌ Error listing people: $error');
      return null;
    }
  }

  // Fetch student submissions for a coursework
  Future<List<StudentSubmission>?> listSubmissions(
    ClassroomApi classroomApi,
    String courseId,
    String courseWorkId,
  ) async {
    print('🔄 Fetching submissions for coursework: $courseWorkId');
    try {
      final submissions = await classroomApi
          .courses
          .courseWork
          .studentSubmissions
          .list(courseId, courseWorkId);
      print(
        '✅ Successfully fetched ${submissions.studentSubmissions?.length ?? 0} submissions',
      );
      return submissions.studentSubmissions?.toList();
    } catch (error) {
      print('❌ Error listing submissions: $error');
      return null;
    }
  }
}
