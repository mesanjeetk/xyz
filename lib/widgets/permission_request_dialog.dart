import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestDialog extends StatelessWidget {
  final VoidCallback onGranted;
  final VoidCallback onDenied;

  const PermissionRequestDialog({
    super.key,
    required this.onGranted,
    required this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.storage,
            size: 24.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12.w),
          const Text('Storage Permission'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This app needs access to your device storage to display and manage files.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Required for PDF viewing and file management features',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDenied,
          child: const Text('Deny'),
        ),
        ElevatedButton(
          onPressed: () async {
            await openAppSettings();
            onGranted();
          },
          child: const Text('Grant Permission'),
        ),
      ],
    );
  }
}