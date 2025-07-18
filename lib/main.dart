import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('directory_permission_advanced');

  List<Map<String, String>> folders = [];

  Future<void> pickDirectory() async {
    try {
      final result = await platform.invokeMethod('pickDirectory');
      debugPrint('Picked: $result');
      loadFolders();
    } on PlatformException catch (e) {
      debugPrint("Error picking folder: ${e.message}");
    }
  }

  Future<void> loadFolders() async {
    try {
      final result = await platform.invokeMethod('getFolders');
      setState(() {
        folders = List<Map<String, String>>.from(
          (result as List).map((e) => Map<String, String>.from(e)),
        );
      });
    } on PlatformException catch (e) {
      debugPrint("Error loading folders: ${e.message}");
    }
  }

  Future<void> writeFile(String folderKey) async {
    final fileController = TextEditingController();
    final contentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Write file"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fileController,
              decoration: const InputDecoration(labelText: "File name"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Content"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Write"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        fileController.text.trim().isNotEmpty &&
        contentController.text.isNotEmpty) {
      try {
        await platform.invokeMethod('writeToDirectory', {
          "folderKey": folderKey,
          "fileName": fileController.text.trim(),
          "content": contentController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File written successfully')),
        );
      } on PlatformException catch (e) {
        debugPrint("Error writing file: ${e.message}");
      }
    }
  }

  Future<void> readFile(String folderKey) async {
    final fileController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Read file"),
        content: TextField(
          controller: fileController,
          decoration: const InputDecoration(labelText: "File name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Read"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true && fileController.text.trim().isNotEmpty) {
      try {
        final result = await platform.invokeMethod('readFromDirectory', {
          "folderKey": folderKey,
          "fileName": fileController.text.trim(),
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("File Content"),
              content: SingleChildScrollView(
                child: Text(result?.toString() ?? "No content"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        }
      } on PlatformException catch (e) {
        debugPrint("Error reading file: ${e.message}");
      }
    }
  }

  Future<void> removeFolder(String folderKey) async {
    try {
      await platform.invokeMethod('removeFolder', {"folderKey": folderKey});
      loadFolders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder removed')),
      );
    } on PlatformException catch (e) {
      debugPrint("Error removing folder: ${e.message}");
    }
  }

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced SAF App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced SAF App'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: pickDirectory,
              child: const Text("Add New Folder"),
            ),
            Expanded(
              child: folders.isEmpty
                  ? const Center(child: Text('No folders yet'))
                  : ListView.builder(
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return ListTile(
                          title: Text(folder['name'] ?? "Folder"),
                          subtitle: Text(folder['uri'] ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: "Write File",
                                onPressed: () => writeFile(folder['key']!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye),
                                tooltip: "Read File",
                                onPressed: () => readFile(folder['key']!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: "Remove Folder",
                                onPressed: () => removeFolder(folder['key']!),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
