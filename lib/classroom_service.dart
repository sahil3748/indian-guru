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

  // Create a new class
  Future<Course?> createCourse(ClassroomApi classroomApi, Course course) async {
    print('🔄 Creating new course: ${course.name}');
    try {
      final createdCourse = await classroomApi.courses.create(course);
      print(
        '✅ Successfully created course: ${createdCourse.name} (ID: ${createdCourse.id})',
      );
      return createdCourse;
    } catch (error) {
      print('❌ Error creating course: $error');
      return null;
    }
  }

  // Update an existing class
  Future<Course?> updateCourse(
    ClassroomApi classroomApi,
    String courseId,
    Course course,
  ) async {
    print('🔄 Updating course: $courseId');
    try {
      final updatedCourse = await classroomApi.courses.update(course, courseId);
      print('✅ Successfully updated course: ${updatedCourse.name}');
      return updatedCourse;
    } catch (error) {
      print('❌ Error updating course: $error');
      return null;
    }
  }

  // Create a new announcement
  Future<Announcement?> createAnnouncement(
    ClassroomApi classroomApi,
    String courseId,
    Announcement announcement,
  ) async {
    print('🔄 Creating announcement for course: $courseId');
    try {
      final createdAnnouncement = await classroomApi.courses.announcements
          .create(announcement, courseId);
      print('✅ Successfully created announcement');
      return createdAnnouncement;
    } catch (error) {
      print('❌ Error creating announcement: $error');
      return null;
    }
  }

  // Create a new assignment
  Future<CourseWork?> createAssignment(
    ClassroomApi classroomApi,
    String courseId,
    CourseWork assignment,
  ) async {
    print('🔄 Creating assignment for course: $courseId');
    try {
      final createdAssignment = await classroomApi.courses.courseWork.create(
        assignment,
        courseId,
      );
      print('✅ Successfully created assignment: ${createdAssignment.title}');
      return createdAssignment;
    } catch (error) {
      print('❌ Error creating assignment: $error');
      return null;
    }
  }

  // Create a new topic
  Future<Topic?> createTopic(
    ClassroomApi classroomApi,
    String courseId,
    Topic topic,
  ) async {
    print('🔄 Creating topic for course: $courseId');
    try {
      final createdTopic = await classroomApi.courses.topics.create(
        topic,
        courseId,
      );
      print('✅ Successfully created topic: ${createdTopic.name}');
      return createdTopic;
    } catch (error) {
      print('❌ Error creating topic: $error');
      return null;
    }
  }

  // Add a teacher to a course
  Future<Teacher?> addTeacher(
    ClassroomApi classroomApi,
    String courseId,
    String teacherEmail,
  ) async {
    print('🔄 Adding teacher to course: $courseId');
    try {
      final teacher = Teacher(userId: teacherEmail);
      final addedTeacher = await classroomApi.courses.teachers.create(
        teacher,
        courseId,
      );
      print('✅ Successfully added teacher: ${addedTeacher.profile?.name}');
      return addedTeacher;
    } catch (error) {
      print('❌ Error adding teacher: $error');
      return null;
    }
  }

  // Add a student to a course
  Future<Student?> addStudent(
    ClassroomApi classroomApi,
    String courseId,
    String studentEmail,
  ) async {
    print('🔄 Adding student to course: $courseId');
    try {
      final student = Student(userId: studentEmail);
      final addedStudent = await classroomApi.courses.students.create(
        student,
        courseId,
      );
      print('✅ Successfully added student: ${addedStudent.profile?.name}');
      return addedStudent;
    } catch (error) {
      print('❌ Error adding student: $error');
      return null;
    }
  }

  // Create a material
  Future<CourseWork?> createMaterial(
    ClassroomApi classroomApi,
    String courseId,
    CourseWork material,
  ) async {
    print('🔄 Creating material for course: $courseId');
    try {
      // Ensure workType is set to MATERIAL
      material.workType = 'MATERIAL';
      final createdMaterial = await classroomApi.courses.courseWork.create(
        material,
        courseId,
      );
      print('✅ Successfully created material: ${createdMaterial.title}');
      return createdMaterial;
    } catch (error) {
      print('❌ Error creating material: $error');
      return null;
    }
  }

  // Create a question
  Future<CourseWork?> createQuestion(
    ClassroomApi classroomApi,
    String courseId,
    CourseWork question,
  ) async {
    print('🔄 Creating question for course: $courseId');
    try {
      // Ensure workType is set to ASSIGNMENT
      question.workType = 'ASSIGNMENT';
      final createdQuestion = await classroomApi.courses.courseWork.create(
        question,
        courseId,
      );
      print('✅ Successfully created question: ${createdQuestion.title}');
      return createdQuestion;
    } catch (error) {
      print('❌ Error creating question: $error');
      return null;
    }
  }

  // Get course invite code
  Future<String?> getCourseInviteCode(
    ClassroomApi classroomApi,
    String courseId,
  ) async {
    print('🔄 Fetching invite code for course: $courseId');
    try {
      final course = await classroomApi.courses.get(courseId);
      print('✅ Successfully fetched invite code: ${course.enrollmentCode}');
      return course.enrollmentCode;
    } catch (error) {
      print('❌ Error fetching invite code: $error');
      return null;
    }
  }
}
