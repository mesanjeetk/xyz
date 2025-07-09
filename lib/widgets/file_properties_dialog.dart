import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FilePropertiesDialog extends StatelessWidget {
  final Map<String, dynamic> properties;

  const FilePropertiesDialog({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Properties'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPropertyRow('Name', properties['name']?.toString() ?? 'Unknown'),
            _buildPropertyRow('Type', properties['type']?.toString() ?? 'Unknown'),
            _buildPropertyRow('Size', _formatSize(properties['size'] ?? 0)),
            _buildPropertyRow('Path', properties['path']?.toString() ?? 'Unknown'),
            _buildPropertyRow('Modified', _formatDate(properties['modified'])),
            _buildPropertyRow('Accessed', _formatDate(properties['accessed'])),
            _buildPropertyRow('Permissions', properties['permissions']?.toString() ?? 'Unknown'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }
}