import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerPage extends StatefulWidget {
  final String url;
  final String title;

  PDFViewerPage({required this.url, required this.title});

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late PdfViewerController _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initializePdfViewer();
  }

  Future<void> _initializePdfViewer() async {
    setState(() {
      _isLoading = false;
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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
            Text('Loading PDF...'),
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
                onPressed: _initializePdfViewer,
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

    return SfPdfViewer.network(
      widget.url,
      controller: _pdfViewerController,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _hasError = true;
          _errorMessage = details.error;
        });
        print('❌ Error loading PDF: ${details.error}');
      },
    );
  }
}
