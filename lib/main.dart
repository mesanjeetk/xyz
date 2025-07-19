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
  Map<String, dynamic> folderTrees = {};

  @override
  void initState() {
    super.initState();
    checkAndLoadFolders();
  }

  Future<void> pickDirectory() async {
    await platform.invokeMethod('pickDirectory', {"folderName": "Folder"});
    await checkAndLoadFolders();
  }

  Future<void> checkAndLoadFolders() async {
    final result = await platform.invokeMethod('getFolders');
    final loaded = List<Map<String, String>>.from(
      (result as List).map((e) => Map<String, String>.from(e)),
    );
    // Remove stale roots if path is invalid
    List<Map<String, String>> valid = [];
    for (final folder in loaded) {
      final key = folder['key']!;
      final tree = await platform.invokeMethod('getFolderTree', {"folderKey": key});
      if (tree != null) {
        valid.add(folder);
        folderTrees[key] = tree;
      }
    }
    setState(() {
      folders = valid;
    });
  }

  Future<void> createFolder(String parentUri) async {
    final name = await _prompt("New Folder Name");
    if (name == null) return;
    await platform.invokeMethod('createFolder', {"parentUri": parentUri, "name": name});
    await checkAndLoadFolders();
  }

  Future<void> createFile(String parentUri) async {
    final name = await _prompt("New File Name");
    if (name == null) return;
    await platform.invokeMethod('createFile', {"parentUri": parentUri, "name": name});
    await checkAndLoadFolders();
  }

  Future<void> rename(String uri) async {
    final name = await _prompt("New Name");
    if (name == null) return;
    await platform.invokeMethod('renameDocument', {"uri": uri, "name": name});
    await checkAndLoadFolders();
  }

  Future<void> deleteDocument(String uri) async {
    await platform.invokeMethod('deleteDocument', {"uri": uri});
    await checkAndLoadFolders();
  }

  Future<void> removeFolder(String folderKey) async {
    await platform.invokeMethod('removeFolder', {"folderKey": folderKey});
    await checkAndLoadFolders();
  }

  Future<String?> _prompt(String hint) async {
    final c = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(hint),
        content: TextField(controller: c),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context, c.text.trim()),
          )
        ],
      ),
    );
  }

  Widget buildTree(Map<String, dynamic> node) {
    final type = node['type'];
    final name = node['name'];
    final uri = node['uri'];

    final actions = <PopupMenuEntry<String>>[
      if (type == 'folder')
        const PopupMenuItem(value: 'create_folder', child: Text("New Folder")),
      if (type == 'folder')
        const PopupMenuItem(value: 'create_file', child: Text("New File")),
      const PopupMenuItem(value: 'rename', child: Text("Rename")),
      const PopupMenuItem(value: 'delete', child: Text("Delete")),
    ];

    return ExpansionTile(
      leading: Icon(type == 'file' ? Icons.insert_drive_file : Icons.folder),
      title: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'create_folder':
                  await createFolder(uri);
                  break;
                case 'create_file':
                  await createFile(uri);
                  break;
                case 'rename':
                  await rename(uri);
                  break;
                case 'delete':
                  await deleteDocument(uri);
                  break;
              }
            },
            itemBuilder: (_) => actions,
          )
        ],
      ),
      children: (node['children'] as List)
          .map((e) => buildTree(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Widget buildRoot(Map<String, String> folder) {
    final key = folder['key']!;
    final tree = folderTrees[key];
    final name = folder['name']!;
    final uri = folder['uri']!;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_special),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'create_folder':
                    await createFolder(uri);
                    break;
                  case 'create_file':
                    await createFile(uri);
                    break;
                  case 'remove_root':
                    await removeFolder(key);
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'create_folder', child: Text("New Folder")),
                PopupMenuItem(value: 'create_file', child: Text("New File")),
                PopupMenuItem(value: 'remove_root', child: Text("Remove Folder")),
              ],
            ),
          ],
        ),
        children: tree != null
            ? (tree['children'] as List)
                .map((e) => buildTree(Map<String, dynamic>.from(e)))
                .toList()
            : [const ListTile(title: Text("Empty"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VS Code File Tree',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("VS Code File Explorer"),
          actions: [
            IconButton(onPressed: pickDirectory, icon: const Icon(Icons.add))
          ],
        ),
        body: folders.isEmpty
            ? const Center(child: Text("No folders added"))
            : ListView(
                padding: const EdgeInsets.all(8),
                children: folders.map(buildRoot).toList(),
              ),
      ),
    );
  }
}
