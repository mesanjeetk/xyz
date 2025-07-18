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
  Map<String, dynamic> folderTrees = {}; // key: folderKey, value: tree map

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> pickDirectory() async {
    try {
      await platform.invokeMethod('pickDirectory', {"folderName": "New Folder"});
      await loadFolders();
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> loadFolders() async {
    try {
      final result = await platform.invokeMethod('getFolders');
      final loaded = List<Map<String, String>>.from(
        (result as List).map((e) => Map<String, String>.from(e)),
      );

      setState(() {
        folders = loaded;
      });

      // Load tree for each
      for (final folder in loaded) {
        await loadFolderTree(folder['key']!);
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> loadFolderTree(String folderKey) async {
    try {
      final result = await platform.invokeMethod('getFolderTree', {"folderKey": folderKey});
      if (result != null) {
        setState(() {
          folderTrees[folderKey] = result;
        });
      }
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> createFolder(String parentUri) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Folder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Folder name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Create"),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await platform.invokeMethod('createFolder', {
        "parentUri": parentUri,
        "name": name,
      });
      await loadFolders();
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> createFile(String parentUri) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create File"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "File name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Create"),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await platform.invokeMethod('createFile', {
        "parentUri": parentUri,
        "name": name,
      });
      await loadFolders();
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> readFileContent(String uri) async {
    try {
      final result = await platform.invokeMethod('readFileContent', {"uri": uri});
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("File Content"),
          content: SingleChildScrollView(child: Text(result ?? "")),
        ),
      );
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> deleteDocument(String uri) async {
    try {
      await platform.invokeMethod('deleteDocument', {"uri": uri});
      await loadFolders();
    } catch (e) {
      showError(e.toString());
    }
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
      ),
    );
  }

  Widget buildTree(Map<String, dynamic> node) {
    final String type = node['type'];
    final String name = node['name'];
    final String uri = node['uri'];

    if (type == 'file') {
      return ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(name),
        onTap: () => readFileContent(uri),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 16),
          onPressed: () => deleteDocument(uri),
        ),
      );
    } else if (type == 'folder') {
      final children = node['children'] as List<dynamic>;
      return ExpansionTile(
        leading: const Icon(Icons.folder),
        title: Text(name),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                onPressed: () => createFolder(uri),
              ),
              IconButton(
                icon: const Icon(Icons.note_add, size: 20),
                onPressed: () => createFile(uri),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => deleteDocument(uri),
              ),
              const Text("Actions")
            ],
          ),
          ...children.map((e) => buildTree(Map<String, dynamic>.from(e))).toList(),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced SAF Tree',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Advanced SAF File Explorer"),
          actions: [
            IconButton(
              onPressed: pickDirectory,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: ListView(
          children: folders.map((folder) {
            final tree = folderTrees[folder['key']];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_special),
                  title: Text(folder['name'] ?? "Root"),
                  subtitle: Text(folder['uri'] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => loadFolderTree(folder['key']!),
                  ),
                ),
                if (tree != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: buildTree(Map<String, dynamic>.from(tree)),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text("No tree loaded"),
                  ),
                const Divider(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
