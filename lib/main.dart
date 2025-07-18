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
  Map<String, dynamic>? folderTree;

  Future<void> pickDirectory() async {
    await platform.invokeMethod('pickDirectory');
    await loadFolders();
  }

  Future<void> loadFolders() async {
    final result = await platform.invokeMethod('getFolders');
    setState(() {
      folders = List<Map<String, String>>.from(
        (result as List).map((e) => Map<String, String>.from(e)),
      );
    });
  }

  Future<void> loadFolderTree(String key) async {
    final result = await platform.invokeMethod('getFolderTree', {"folderKey": key});
    setState(() {
      folderTree = Map<String, dynamic>.from(result);
    });
  }

  Future<void> createFolder(String parentUri) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Folder"),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
        actions: [
          TextButton(
            child: const Text("Create"),
            onPressed: () async {
              Navigator.of(context).pop();
              await platform.invokeMethod('createFolder', {
                "parentUri": parentUri,
                "name": nameController.text.trim(),
              });
              await refreshTree();
            },
          ),
        ],
      ),
    );
  }

  Future<void> createFile(String parentUri) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create File"),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name.txt")),
        actions: [
          TextButton(
            child: const Text("Create"),
            onPressed: () async {
              Navigator.of(context).pop();
              await platform.invokeMethod('createFile', {
                "parentUri": parentUri,
                "name": nameController.text.trim(),
              });
              await refreshTree();
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteDocument(String uri) async {
    await platform.invokeMethod('deleteDocument', {"uri": uri});
    await refreshTree();
  }

  Future<void> readFile(String uri) async {
    final result = await platform.invokeMethod('readFileContent', {"uri": uri});
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("File Content"),
        content: SingleChildScrollView(child: Text(result.toString())),
      ),
    );
  }

  Future<void> refreshTree() async {
    if (folders.isNotEmpty) {
      await loadFolderTree(folders.first['key']!);
    }
  }

  Widget buildTree(Map<String, dynamic> node) {
    if (node['type'] == 'file') {
      return ListTile(
        title: Text(node['name']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => readFile(node['uri'])),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => deleteDocument(node['uri'])),
          ],
        ),
      );
    } else {
      return ExpansionTile(
        title: Text(node['name']),
        children: [
          ...((node['children'] as List).map((child) => buildTree(Map<String, dynamic>.from(child)))),
          ListTile(
            title: const Text("➕ New Folder"),
            onTap: () => createFolder(node['uri']),
          ),
          ListTile(
            title: const Text("📝 New File"),
            onTap: () => createFile(node['uri']),
          ),
        ],
      );
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
      home: Scaffold(
        appBar: AppBar(title: const Text("Advanced SAF Explorer")),
        body: Column(
          children: [
            ElevatedButton(onPressed: pickDirectory, child: const Text("Add Root Folder")),
            if (folders.isNotEmpty)
              ElevatedButton(
                onPressed: () => loadFolderTree(folders.first['key']!),
                child: const Text("Load File Tree"),
              ),
            const Divider(),
            Expanded(
              child: folderTree == null
                  ? const Center(child: Text("No tree loaded"))
                  : SingleChildScrollView(child: buildTree(folderTree!)),
            ),
          ],
        ),
      ),
    );
  }
}
