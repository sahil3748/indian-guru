import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'classroom_service.dart';
import 'classwork_detail_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  final ClassroomApi classroomApi;

  CourseDetailPage({required this.course, required this.classroomApi});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final ClassroomService _classroomService = ClassroomService();

  List<Announcement>? _announcements;
  List<CourseWork>? _courseWork;
  Map<String, List<Student>>? _people;
  bool _isLoading = false;

  String? _getValidPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Convert file:// URLs to https://
    if (url.startsWith('file://')) {
      url = 'https://' + url.substring('file://'.length);
    }
    // Ensure URL starts with https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);

    try {
      final announcements = await _classroomService.listAnnouncements(
        widget.classroomApi,
        widget.course.id!,
      );

      final courseWork = await _classroomService.listCourseWork(
        widget.classroomApi,
        widget.course.id!,
      );

      final people = await _classroomService.listPeople(
        widget.classroomApi,
        widget.course.id!,
      );

      if (mounted) {
        setState(() {
          _announcements = announcements;
          _courseWork = courseWork;
          _people = people;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course.name ?? 'Course Details'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.stream), text: 'Stream'),
              Tab(icon: Icon(Icons.assignment), text: 'Classwork'),
              Tab(icon: Icon(Icons.people), text: 'People'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildStreamTab(),
                  _buildClassworkTab(),
                  _buildPeopleTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStreamTab() {
    if (_announcements == null) {
      return Center(child: Text('No announcements available'));
    }

    return ListView.builder(
      itemCount: _announcements!.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final announcement = _announcements![index];
        final teacher = _people?['teachers']?.firstWhere(
          (t) => t.userId == announcement.creatorUserId,
          orElse: () => Student(),
        );
        final photoUrl = _getValidPhotoUrl(teacher?.profile?.photoUrl);

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null ? Icon(Icons.person) : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.text ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (announcement.updateTime != null)
                            Text(
                              'Posted on ${announcement.updateTime}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassworkTab() {
    if (_courseWork == null) {
      return Center(child: Text('No classwork available'));
    }

    return ListView.builder(
      itemCount: _courseWork!.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final work = _courseWork![index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.assignment),
            title: Text(work.title ?? 'Untitled Assignment'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (work.description != null)
                  Text(
                    work.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (work.dueDate != null)
                  Text(
                    'Due: ${work.dueDate?.month}/${work.dueDate?.day}/${work.dueDate?.year}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassworkDetailPage(
                    courseWork: work,
                    courseId: widget.course.id!,
                    classroomApi: widget.classroomApi,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    if (_people == null) {
      return Center(child: Text('No people data available'));
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Teachers', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _people!['teachers']?.length ?? 0,
          itemBuilder: (context, index) {
            final teacher = _people!['teachers']![index];
            final photoUrl = _getValidPhotoUrl(teacher.profile?.photoUrl);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null ? Icon(Icons.person) : null,
              ),
              title: Text(teacher.profile?.name?.fullName ?? 'Unknown Teacher'),
              subtitle: Text(teacher.profile?.emailAddress ?? ''),
            );
          },
        ),
        SizedBox(height: 24),
        Text('Students', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _people!['students']?.length ?? 0,
          itemBuilder: (context, index) {
            final student = _people!['students']![index];
            final photoUrl = _getValidPhotoUrl(student.profile?.photoUrl);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null ? Icon(Icons.person) : null,
              ),
              title: Text(student.profile?.name?.fullName ?? 'Unknown Student'),
              subtitle: Text(student.profile?.emailAddress ?? ''),
            );
          },
        ),
      ],
    );
  }
}
