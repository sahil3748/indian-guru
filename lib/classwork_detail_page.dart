import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:indian_guru/screens/pdf_viewer_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'classroom_service.dart';

class ClassworkDetailPage extends StatefulWidget {
  final classroom.CourseWork courseWork;
  final String courseId;
  final classroom.ClassroomApi classroomApi;

  ClassworkDetailPage({
    required this.courseWork,
    required this.courseId,
    required this.classroomApi,
  });

  @override
  _ClassworkDetailPageState createState() => _ClassworkDetailPageState();
}

class _ClassworkDetailPageState extends State<ClassworkDetailPage>
    with SingleTickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  bool _isLoading = false;
  List<classroom.Material>? _materials;
  classroom.StudentSubmission? _mySubmission;
  late TabController _tabController;
  int _selectedTab = 1; // Default to Student Work tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedTab,
    );
    _loadClassworkDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassworkDetails() async {
    setState(() => _isLoading = true);

    try {
      final submissions = await _classroomService.listSubmissions(
        widget.classroomApi,
        widget.courseId,
        widget.courseWork.id!,
      );

      if (mounted) {
        setState(() {
          _materials = widget.courseWork.materials?.toList() ?? [];
          _mySubmission = submissions?.firstOrNull;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classwork details: $e')),
        );
      }
    }
  }

  Future<void> _openMaterial(classroom.Material material) async {
    if (material.driveFile != null) {
      print('🔄 Opening Drive file: ${material.driveFile!.driveFile?.title}');
      // Get the file ID from the driveFile object
      final fileId = material.driveFile!.driveFile?.id;
      if (fileId != null) {
        // Get file metadata to check if it's a PDF
        final fileName =
            material.driveFile!.driveFile?.title?.toLowerCase() ?? '';
        final isPDF = fileName.endsWith('.pdf');

        // Construct the appropriate URL
        final url = isPDF
            ? 'https://drive.google.com/uc?export=download&id=$fileId'
            : 'https://drive.google.com/file/d/$fileId/view';

        print('🔄 Opening Drive file: $url');
        try {
          if (isPDF) {
            // Use PDF viewer for PDF files
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerPage(
                  url: url,
                  title: material.driveFile!.driveFile?.title ?? 'PDF File',
                ),
              ),
            );
          } else {
            // Open other files in external browser
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
              webViewConfiguration: WebViewConfiguration(
                enableDomStorage: true,
              ),
            );
          }
        } catch (e) {
          print('❌ Error opening Drive file: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
        }
      }
    } else if (material.link != null) {
      final url = material.link!.url;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else if (material.youtubeVideo != null) {
      final videoId = material.youtubeVideo!.id;
      if (videoId != null) {
        // Construct the YouTube embed URL
        final url = 'https://www.youtube.com/embed/$videoId';
        if (await canLaunchUrl(Uri.parse(url))) {
          // For YouTube videos, show in WebView
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(material.youtubeVideo!.title ?? 'YouTube Video'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.open_in_browser),
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
                body: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(url)),
                ),
              ),
            ),
          );
        }
      }
    } else if (material.form != null) {
      final url = material.form!.formUrl;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildMaterialItem(classroom.Material material) {
    IconData icon;
    String title = 'Material';
    String? subtitle;

    if (material.driveFile != null) {
      icon = Icons.insert_drive_file;
      title = material.driveFile!.driveFile?.title ?? 'Drive File';
      subtitle = 'Google Drive';
    } else if (material.link != null) {
      icon = Icons.link;
      title = material.link!.title ?? material.link!.url ?? 'Link';
      subtitle = 'Web Link';
    } else if (material.youtubeVideo != null) {
      icon = Icons.play_circle_fill;
      title = material.youtubeVideo!.title ?? 'YouTube Video';
      subtitle = 'YouTube';
    } else if (material.form != null) {
      icon = Icons.assignment;
      title = material.form!.title ?? 'Google Form';
      subtitle = 'Google Forms';
    } else {
      icon = Icons.attachment;
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () => _openMaterial(material),
    );
  }

  Widget _buildPointsPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 18),
          SizedBox(width: 4),
          Text(
            '${widget.courseWork.maxPoints ?? 0} points',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    final turnedIn = _mySubmission?.state == 'TURNED_IN' ? 1 : 0;
    final assigned = 1; // Assuming 1 student is assigned

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                '$turnedIn',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Turned in'),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.grey[800]),
          Column(
            children: [
              Text(
                '$assigned',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('Assigned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadline() {
    final dueDate = widget.courseWork.dueDate;
    final dueTime = widget.courseWork.dueTime;
    if (dueDate == null) return SizedBox.shrink();

    final deadline = DateTime(
      dueDate.year ?? 2025,
      dueDate.month ?? 1,
      dueDate.day ?? 1,
      dueTime?.hours ?? 23,
      dueTime?.minutes ?? 59,
    );

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Submissions will close ${deadline.month}/${deadline.day}/${deadline.year}, '
            '${(dueTime?.hours ?? 23).toString().padLeft(2, '0')}:'
            '${(dueTime?.minutes ?? 59).toString().padLeft(2, '0')} PM',
            style: TextStyle(fontSize: 16),
          ),
          Spacer(),
          Icon(Icons.edit_outlined),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.people, color: Colors.blue),
          ),
          title: Text('All students'),
          trailing: Checkbox(value: false, onChanged: (value) {}),
        ),
        ListTile(title: Text('ASSIGNED'), dense: true),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green,
            child: Text('I'),
          ),
          title: Text('Ishika Chudasama'),
          trailing: Text('Assigned'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildPointsPill(),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Instructions'),
                    Tab(text: 'Student Work'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Instructions Tab
                      SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.courseWork.description != null)
                                Text(widget.courseWork.description!),
                              if (_materials != null &&
                                  _materials!.isNotEmpty) ...[
                                SizedBox(height: 24),
                                Text(
                                  'Attachments',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _materials!.length,
                                  itemBuilder: (context, index) =>
                                      _buildMaterialItem(_materials![index]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Student Work Tab
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSubmissionStatus(),
                            _buildDeadline(),
                            _buildStudentList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
