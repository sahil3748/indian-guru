import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';
import 'classroom_service.dart';
import 'course_detail_page.dart';

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
  int _selectedIndex = 0;

  final List<Color> _courseColors = [
    Color(0xFFE91E63), // Pink
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFF9C27B0), // Purple
  ];

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

  Widget _buildCourseCard(Course course, int index) {
    final color = _courseColors[index % _courseColors.length];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(
                course: course,
                classroomApi: _classroomApi!,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Icon(
                      Icons.class_,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      course.name ?? 'Unnamed Course',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.section != null)
                    Text(
                      course.section!,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  SizedBox(height: 8),
                  Text(
                    course.descriptionHeading ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Classroom'),
        actions: [
          if (_isSignedIn) ...[
            IconButton(icon: Icon(Icons.grid_view), onPressed: () {}),
            IconButton(icon: Icon(Icons.account_circle), onPressed: _signOut),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : !_isSignedIn
          ? Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text('Sign in with Google'),
                onPressed: _signIn,
              ),
            )
          : _courses == null || _courses!.isEmpty
          ? Center(child: Text('No courses found'))
          : ListView.builder(
              itemCount: _courses!.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(_courses![index], index);
              },
            ),
      bottomNavigationBar: _isSignedIn
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.stream),
                  label: 'Stream',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Classwork',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'People',
                ),
              ],
            )
          : null,
      floatingActionButton: _isSignedIn
          ? FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
