import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FileManagerToolbar extends StatelessWidget {
  final VoidCallback onCreateFile;
  final VoidCallback onCreateDirectory;
  final VoidCallback? onPaste;
  final int clipboardCount;

  const FileManagerToolbar({
    super.key,
    required this.onCreateFile,
    required this.onCreateDirectory,
    this.onPaste,
    this.clipboardCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            context,
            icon: Icons.note_add,
            label: 'New File',
            onPressed: onCreateFile,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.create_new_folder,
            label: 'New Folder',
            onPressed: onCreateDirectory,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.paste,
            label: clipboardCount > 0 ? 'Paste ($clipboardCount)' : 'Paste',
            onPressed: onPaste,
            enabled: onPaste != null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24.sp,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}