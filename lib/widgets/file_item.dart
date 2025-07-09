import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/file_model.dart';

class FileItem extends StatelessWidget {
  final FileModel file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FileItem({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: _getFileTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getFileTypeIcon(),
                  size: 24.sp,
                  color: _getFileTypeColor(),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          file.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          file.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileTypeIcon() {
    if (file.isPDF) return Icons.picture_as_pdf;
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileTypeColor() {
    if (file.isPDF) return Colors.red;
    if (file.isImage) return Colors.blue;
    if (file.isVideo) return Colors.purple;
    if (file.isAudio) return Colors.orange;
    if (file.isDocument) return Colors.green;
    return Colors.grey;
  }
}