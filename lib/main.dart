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
    TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Name your folder"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Folder name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (nameController.text.trim().isEmpty) return;

              final result = await platform.invokeMethod(
                'pickDirectory',
                {"folderName": nameController.text.trim()},
              );

              loadFolders();
            },
            child: const Text("Pick Folder"),
          ),
        ],
      ),
    );
  }

  Future<void> loadFolders() async {
    final result = await platform.invokeMethod('getFolders');
    setState(() {
      folders = List<Map<String, String>>.from(
        (result as List).map((e) => Map<String, String>.from(e)),
      );
    });
  }

  Future<void> writeFile(String folderKey) async {
    TextEditingController fileController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    await showDialog(
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
            onPressed: () async {
              Navigator.of(context).pop();
              await platform.invokeMethod('writeToDirectory', {
                "folderKey": folderKey,
                "fileName": fileController.text.trim(),
                "content": contentController.text,
              });
            },
            child: const Text("Write"),
          ),
        ],
      ),
    );
  }

  Future<void> readFile(String folderKey) async {
    TextEditingController fileController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Read file"),
        content: TextField(
          controller: fileController,
          decoration: const InputDecoration(labelText: "File name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await platform.invokeMethod('readFromDirectory', {
                "folderKey": folderKey,
                "fileName": fileController.text.trim(),
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("File Content"),
                  content: Text(result ?? "No content"),
                ),
              );
            },
            child: const Text("Read"),
          ),
        ],
      ),
    );
  }

  Future<void> removeFolder(String folderKey) async {
    await platform.invokeMethod('removeFolder', {"folderKey": folderKey});
    loadFolders();
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
              child: ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return ListTile(
                    title: Text(folder['name'] ?? "No Name"),
                    subtitle: Text(folder['uri'] ?? ""),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => writeFile(folder['key']!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          onPressed: () => readFile(folder['key']!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
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
