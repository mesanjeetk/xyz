import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class FileManagerItem extends StatelessWidget {
  final FileSystemEntity entity;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileManagerItem({
    super.key,
    required this.entity,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDirectory = entity is Directory;
    final fileName = path.basename(entity.path);
    final extension = isDirectory ? '' : path.extension(fileName).replaceFirst('.', '');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Selection indicator
              if (isSelected)
                Container(
                  width: 24.w,
                  height: 24.h,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              
              // File/Directory icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: _getIconColor(isDirectory, extension).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getIcon(isDirectory, extension),
                  size: 24.sp,
                  color: _getIconColor(isDirectory, extension),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    FutureBuilder<String>(
                      future: _getFileDetails(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // More options
              IconButton(
                onPressed: () => _showContextMenu(context),
                icon: Icon(
                  Icons.more_vert,
                  size: 20.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(bool isDirectory, String extension) {
    if (isDirectory) return Icons.folder;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Icons.description;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getIconColor(bool isDirectory, String extension) {
    if (isDirectory) return Colors.blue;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Colors.orange;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Colors.indigo;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.brown;
      case 'apk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<String> _getFileDetails() async {
    try {
      final stat = await entity.stat();
      final isDirectory = entity is Directory;
      
      if (isDirectory) {
        // Count items in directory
        final dir = entity as Directory;
        final itemCount = await dir.list().length;
        return '$itemCount items • ${_formatDate(stat.modified)}';
      } else {
        return '${_formatFileSize(stat.size)} • ${_formatDate(stat.modified)}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showContextMenu(BuildContext context) {
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
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle rename
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle copy
                },
              ),
              ListTile(
                leading: const Icon(Icons.cut),
                title: const Text('Cut'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle cut
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle delete
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Properties'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle properties
                },
              ),
            ],
          ),
        );
      },
    );
  }
}