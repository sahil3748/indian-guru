import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'classroom_service.dart';
import 'pdf_viewer_page.dart';

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

class _ClassworkDetailPageState extends State<ClassworkDetailPage> {
  final ClassroomService _classroomService = ClassroomService();
  bool _isLoading = false;
  List<classroom.Material>? _materials;
  classroom.StudentSubmission? _mySubmission;

  @override
  void initState() {
    super.initState();
    _loadClassworkDetails();
  }

  Future<void> _loadClassworkDetails() async {
    setState(() => _isLoading = true);

    try {
      // Get student submission if available
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

  @override
  Widget build(BuildContext context) {
    final dueDate = widget.courseWork.dueDate;
    final dueTime = widget.courseWork.dueTime;
    String? dueDateStr;

    if (dueDate != null) {
      dueDateStr = 'Due: ${dueDate.month}/${dueDate.day}/${dueDate.year}';
      if (dueTime != null) {
        dueDateStr +=
            ' at ${dueTime.hours}:${dueTime.minutes.toString().padLeft(2, '0')}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseWork.title ?? 'Assignment Details'),
        actions: [
          if (widget.courseWork.alternateLink != null)
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: () async {
                final url = widget.courseWork.alternateLink!;
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and type
                  Text(
                    widget.courseWork.title ?? 'Untitled Assignment',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.courseWork.workType ?? 'Assignment',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),

                  // Due date
                  if (dueDateStr != null) ...[
                    SizedBox(height: 16),
                    Text(
                      dueDateStr,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.red),
                    ),
                  ],

                  // Points
                  if (widget.courseWork.maxPoints != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Points: ${widget.courseWork.maxPoints}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],

                  // Description
                  if (widget.courseWork.description != null) ...[
                    SizedBox(height: 24),
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(widget.courseWork.description!),
                  ],

                  // Materials
                  if (_materials != null && _materials!.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      'Materials',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: _materials!
                            .map((material) => _buildMaterialItem(material))
                            .toList(),
                      ),
                    ),
                  ],

                  // Submission status
                  if (_mySubmission != null) ...[
                    SizedBox(height: 24),
                    Text(
                      'Your Submission',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${_mySubmission!.state ?? 'Not submitted'}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_mySubmission!.assignedGrade != null) ...[
                              SizedBox(height: 8),
                              Text(
                                'Grade: ${_mySubmission!.assignedGrade}/${widget.courseWork.maxPoints ?? 'N/A'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
