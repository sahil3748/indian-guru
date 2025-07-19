import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';
import 'classroom_service.dart';

class ClassroomHomePage extends StatefulWidget {
  @override
  _ClassroomHomePageState createState() => _ClassroomHomePageState();
}

class _ClassroomHomePageState extends State<ClassroomHomePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final ClassroomService _classroomService = ClassroomService();

  bool _isLoading = false;
  bool _isSignedIn = false;
  List<Course>? _courses;
  ClassroomApi? _classroomApi;

  Future<void> _signIn() async {
    print('\n🔐 Starting sign-in process...');
    setState(() {
      _isLoading = true;
    });
    print('⏳ Set loading state to true');

    try {
      print('🔄 Attempting Google Sign-In...');
      final account = await _authService.signInWithGoogle();

      if (account != null) {
        print('✅ Google Sign-In successful');
        print('📧 Signed in as: ${account.email}');

        print('🔄 Signing in to Firebase...');
        final firebaseResult = await _firebaseAuthService.signInWithFirebase(
          account,
        );
        print(
          firebaseResult != null
              ? '✅ Firebase Sign-In successful'
              : '❌ Firebase Sign-In failed',
        );

        print('🔄 Getting Classroom API access...');
        final api = await _classroomService.getClassroomApi(
          _authService.googleSignIn,
          account,
        );

        if (api != null) {
          print('✅ Successfully got Classroom API access');
          print('🔄 Fetching courses...');
          final courses = await _classroomService.listCourses(api);

          setState(() {
            _classroomApi = api;
            _courses = courses;
            _isSignedIn = true;
          });
          print('✅ State updated with courses and sign-in status');
          print('📚 Total courses loaded: ${courses?.length ?? 0}');
        } else {
          print('❌ Failed to get Classroom API access');
        }
      } else {
        print('❌ Google Sign-In failed or was cancelled');
      }
    } catch (e) {
      print('❌ Error during sign-in process: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing in: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('⏳ Set loading state to false');
      print('🏁 Sign-in process completed\n');
    }
  }

  Future<void> _signOut() async {
    print('\n🔐 Starting sign-out process...');
    setState(() {
      _isLoading = true;
    });
    print('⏳ Set loading state to true');

    try {
      print('🔄 Signing out from Google...');
      await _authService.signOut();
      print('✅ Successfully signed out from Google');

      setState(() {
        _isSignedIn = false;
        _courses = null;
        _classroomApi = null;
      });
      print('✅ Cleared all session data');
    } catch (e) {
      print('❌ Error during sign-out process: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('⏳ Set loading state to false');
      print('🏁 Sign-out process completed\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n🔄 Building UI with state:');
    print('   Loading: $_isLoading');
    print('   Signed In: $_isSignedIn');
    print('   Has Courses: ${_courses != null}');
    print('   Course Count: ${_courses?.length ?? 0}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Google Classroom App'),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _isLoading ? null : _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : !_isSignedIn
          ? Center(
              child: ElevatedButton(
                onPressed: _signIn,
                child: Text('Sign in with Google'),
              ),
            )
          : _courses == null || _courses!.isEmpty
          ? Center(child: Text('No courses found'))
          : ListView.builder(
              itemCount: _courses!.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final course = _courses![index];
                return Card(
                  child: ListTile(
                    title: Text(course.name ?? 'Unnamed Course'),
                    subtitle: Text(course.section ?? ''),
                    trailing: Text(course.courseState ?? ''),
                    onTap: () {
                      print('\n📚 Course tapped:');
                      print('   Name: ${course.name}');
                      print('   ID: ${course.id}');
                      print('   Section: ${course.section ?? 'N/A'}');
                      print('   State: ${course.courseState ?? 'N/A'}\n');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Course ID: ${course.id}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
