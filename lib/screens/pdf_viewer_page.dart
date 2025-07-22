import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerPage extends StatefulWidget {
  final String url;
  final String title;

  PDFViewerPage({required this.url, required this.title});

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPath;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPDF();
  }

  Future<void> _downloadAndOpenPDF() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';

      // Download file
      print('🔄 Downloading PDF from: ${widget.url}');
      final dio = Dio();
      await dio.download(
        widget.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
              '📥 Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );
      print('✅ PDF downloaded successfully');

      if (mounted) {
        setState(() {
          localPath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error downloading PDF: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up temporary file
    if (localPath != null) {
      try {
        File(localPath!).deleteSync();
        print('🗑️ Temporary PDF file deleted');
      } catch (e) {
        print('⚠️ Error deleting temporary file: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isLoading && !_hasError) ...[
            // Page navigation
            Row(
              children: [
                Text(
                  'Page: ${_currentPage + 1}/$_totalPages',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.navigate_before),
                  onPressed: _currentPage > 0
                      ? () {
                          _pdfViewController?.setPage(_currentPage - 1);
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.navigate_next),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          _pdfViewController?.setPage(_currentPage + 1);
                        }
                      : null,
                ),
              ],
            ),
            // Open in browser button
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse(widget.url),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading PDF...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading PDF',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _downloadAndOpenPDF,
                child: Text('Try Again'),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse(widget.url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages!;
        });
        print('📄 PDF rendered with $pages pages');
      },
      onError: (error) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
        print('❌ Error rendering PDF: $error');
      },
      onPageError: (page, error) {
        print('❌ Error on page $page: $error');
      },
      onViewCreated: (PDFViewController pdfViewController) {
        setState(() {
          _pdfViewController = pdfViewController;
        });
      },
      onPageChanged: (int? page, int? total) {
        if (page != null) {
          setState(() {
            _currentPage = page;
          });
        }
      },
    );
  }
}
