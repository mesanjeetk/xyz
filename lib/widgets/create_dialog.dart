import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateDialog extends StatefulWidget {
  final bool isDirectory;

  const CreateDialog({super.key, required this.isDirectory});

  @override
  State<CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isDirectory ? 'Create Directory' : 'Create File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.isDirectory ? 'Directory Name' : 'File Name',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          if (!widget.isDirectory) ...[
            SizedBox(height: 16.h),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Initial Content (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, {
                'name': name,
                if (!widget.isDirectory) 'content': _contentController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}