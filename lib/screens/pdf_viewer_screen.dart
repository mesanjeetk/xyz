import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;

  const PDFViewerScreen({super.key, required this.filePath});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _validateFile();
  }

  void _validateFile() {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      setState(() {
        _errorMessage = 'File not found';
        _isLoading = false;
      });
    } else if (!widget.filePath.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _errorMessage = 'Invalid file format. Only PDF files are supported.';
        _isLoading = false;
      });
    }
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
        title: Text(
          _getFileName(),
          style: TextStyle(fontSize: 16.sp),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_totalPages > 0) ...[
            IconButton(
              onPressed: _previousPage,
              icon: const Icon(Icons.keyboard_arrow_left),
              tooltip: 'Previous Page',
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _nextPage,
              icon: const Icon(Icons.keyboard_arrow_right),
              tooltip: 'Next Page',
            ),
          ],
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
          ),
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'fit_width',
                child: Row(
                  children: [
                    Icon(Icons.fit_screen),
                    SizedBox(width: 8),
                    Text('Fit Width'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fit_height',
                child: Row(
                  children: [
                    Icon(Icons.height),
                    SizedBox(width: 8),
                    Text('Fit Height'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'jump_to_page',
                child: Row(
                  children: [
                    Icon(Icons.skip_next),
                    SizedBox(width: 8),
                    Text('Jump to Page'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _errorMessage == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SfPdfViewer.file(
      File(widget.filePath),
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
          _isLoading = false;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _errorMessage = 'Failed to load PDF: ${details.error}';
          _isLoading = false;
        });
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error Loading PDF',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  String _getFileName() {
    return widget.filePath.split('/').last;
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _zoomIn() {
    _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
  }

  void _zoomOut() {
    _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'fit_width':
        _pdfViewerController.zoomLevel = 1.0;
        break;
      case 'fit_height':
        _pdfViewerController.zoomLevel = 1.0;
        break;
      case 'jump_to_page':
        _showJumpToPageDialog();
        break;
    }
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to Page'),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page Number (1-$_totalPages)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final pageNumber = int.tryParse(pageController.text);
                if (pageNumber != null && pageNumber >= 1 && pageNumber <= _totalPages) {
                  _pdfViewerController.jumpToPage(pageNumber);
                  Navigator.pop(context);
                }
              },
              child: const Text('Jump'),
            ),
          ],
        );
      },
    );
  }
}