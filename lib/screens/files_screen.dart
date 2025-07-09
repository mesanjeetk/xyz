import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/file_model.dart';
import '../services/file_service.dart';
import '../widgets/file_item.dart';
import '../widgets/permission_request_dialog.dart';
import '../utils/route_constants.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final FileService _fileService = FileService();
  List<FileModel> _files = [];
  bool _isLoading = false;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final hasPermission = await _fileService.requestStoragePermission();
    if (hasPermission) {
      _loadFiles();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _fileService.getDeviceFiles();
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load files: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => PermissionRequestDialog(
        onGranted: () {
          Navigator.of(context).pop();
          _requestPermissions();
        },
        onDenied: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        final file = result.files.first;
        if (file.path != null) {
          _openFile(file.path!);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  void _openFile(String filePath) {
    if (filePath.toLowerCase().endsWith('.pdf')) {
      context.push('${RouteConstants.pdfViewer}?filePath=$filePath');
    } else {
      _showErrorSnackBar('File type not supported for viewing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(
            onPressed: _pickFile,
            icon: const Icon(Icons.add),
            tooltip: 'Pick File',
          ),
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_files.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: FileItem(
                    file: file,
                    onTap: () => _openFile(file.path),
                    onLongPress: () => _showFileOptions(file),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 80.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No files found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to add files',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.add),
            label: const Text('Pick File'),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(FileModel file) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context);
                  _openFile(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Properties'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileProperties(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFileProperties(FileModel file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('File Properties'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyRow('Name', file.name),
              _buildPropertyRow('Size', file.formattedSize),
              _buildPropertyRow('Type', file.extension.toUpperCase()),
              _buildPropertyRow('Modified', file.formattedDate),
              _buildPropertyRow('Path', file.path),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}