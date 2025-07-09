import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../services/file_manager_service.dart';
import '../widgets/file_manager_item.dart';
import '../widgets/file_manager_toolbar.dart';
import '../widgets/create_dialog.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/file_properties_dialog.dart';
import '../utils/route_constants.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final FileManagerService _fileManager = FileManagerService.instance;
  List<FileSystemEntity> _currentContents = [];
  String _currentPath = '';
  List<String> _selectedItems = [];
  bool _isLoading = false;
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFileManager();
  }

  Future<void> _initializeFileManager() async {
    final hasPermission = await _fileManager.requestStoragePermission();
    if (hasPermission) {
      final defaultPath = await _fileManager.getDefaultDirectory();
      await _loadDirectory(defaultPath);
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _loadDirectory(String directoryPath) async {
    setState(() {
      _isLoading = true;
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    try {
      final contents = await _fileManager.getDirectoryContents(directoryPath);
      setState(() {
        _currentContents = contents;
        _currentPath = directoryPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load directory: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text('This app needs storage permission to manage files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeFileManager();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onItemTap(FileSystemEntity entity) {
    if (_isSelectionMode) {
      _toggleSelection(entity.path);
    } else {
      if (entity is Directory) {
        _loadDirectory(entity.path);
      } else if (entity is File) {
        _openFile(entity.path);
      }
    }
  }

  void _onItemLongPress(FileSystemEntity entity) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedItems.add(entity.path);
      });
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedItems.contains(path)) {
        _selectedItems.remove(path);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(path);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  void _openFile(String filePath) {
    if (filePath.toLowerCase().endsWith('.pdf')) {
      context.push('${RouteConstants.pdfViewer}?filePath=$filePath');
    } else {
      _showErrorSnackBar('File type not supported for viewing');
    }
  }

  Future<void> _navigateUp() async {
    final parentPath = path.dirname(_currentPath);
    if (parentPath != _currentPath) {
      await _loadDirectory(parentPath);
    }
  }

  Future<void> _createFile() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateDialog(isDirectory: false),
    );

    if (result != null) {
      final success = await _fileManager.createFile(
        _currentPath,
        result['name']!,
        content: result['content'] ?? '',
      );

      if (success) {
        _showSuccessSnackBar('File created successfully');
        await _loadDirectory(_currentPath);
      } else {
        _showErrorSnackBar('Failed to create file');
      }
    }
  }

  Future<void> _createDirectory() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateDialog(isDirectory: true),
    );

    if (result != null) {
      final success = await _fileManager.createDirectory(_currentPath, result['name']!);

      if (success) {
        _showSuccessSnackBar('Directory created successfully');
        await _loadDirectory(_currentPath);
      } else {
        _showErrorSnackBar('Failed to create directory');
      }
    }
  }

  Future<void> _renameSelected() async {
    if (_selectedItems.length != 1) return;

    final currentPath = _selectedItems.first;
    final currentName = path.basename(currentPath);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(currentName: currentName),
    );

    if (newName != null && newName.isNotEmpty) {
      final success = await _fileManager.renameFileOrDirectory(currentPath, newName);

      if (success) {
        _showSuccessSnackBar('Renamed successfully');
        _clearSelection();
        await _loadDirectory(_currentPath);
      } else {
        _showErrorSnackBar('Failed to rename');
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${_selectedItems.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      for (final itemPath in _selectedItems) {
        final success = await _fileManager.deleteFileOrDirectory(itemPath);
        if (success) successCount++;
      }

      _showSuccessSnackBar('Deleted $successCount item(s)');
      _clearSelection();
      await _loadDirectory(_currentPath);
    }
  }

  void _copySelected() {
    _fileManager.copyToClipboard(_selectedItems);
    _showSuccessSnackBar('${_selectedItems.length} item(s) copied');
    _clearSelection();
  }

  void _cutSelected() {
    _fileManager.cutToClipboard(_selectedItems);
    _showSuccessSnackBar('${_selectedItems.length} item(s) cut');
    _clearSelection();
  }

  Future<void> _paste() async {
    final success = await _fileManager.pasteFromClipboard(_currentPath);
    if (success) {
      _showSuccessSnackBar('Items pasted successfully');
      await _loadDirectory(_currentPath);
    } else {
      _showErrorSnackBar('Failed to paste items');
    }
  }

  Future<void> _showProperties() async {
    if (_selectedItems.length != 1) return;

    final properties = await _fileManager.getProperties(_selectedItems.first);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => FilePropertiesDialog(properties: properties),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedItems.length} selected' : 'File Manager',
        ),
        leading: _isSelectionMode
            ? IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              )
            : IconButton(
                onPressed: _navigateUp,
                icon: const Icon(Icons.arrow_back),
              ),
        actions: _isSelectionMode ? _buildSelectionActions() : _buildNormalActions(),
      ),
      body: Column(
        children: [
          // Current Path
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: Theme.of(context).colorScheme.surface,
            child: Text(
              _currentPath,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files and folders...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: _performSearch,
            ),
          ),
          
          // File List
          Expanded(
            child: _buildFileList(),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode ? null : FileManagerToolbar(
        onCreateFile: _createFile,
        onCreateDirectory: _createDirectory,
        onPaste: _fileManager.hasClipboardContent ? _paste : null,
        clipboardCount: _fileManager.clipboardCount,
      ),
    );
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        onPressed: () => _loadDirectory(_currentPath),
        icon: const Icon(Icons.refresh),
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'sort_name':
              // Implement sorting
              break;
            case 'sort_date':
              // Implement sorting
              break;
            case 'sort_size':
              // Implement sorting
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'sort_name', child: Text('Sort by Name')),
          const PopupMenuItem(value: 'sort_date', child: Text('Sort by Date')),
          const PopupMenuItem(value: 'sort_size', child: Text('Sort by Size')),
        ],
      ),
    ];
  }

  List<Widget> _buildSelectionActions() {
    return [
      IconButton(
        onPressed: _copySelected,
        icon: const Icon(Icons.copy),
      ),
      IconButton(
        onPressed: _cutSelected,
        icon: const Icon(Icons.cut),
      ),
      if (_selectedItems.length == 1)
        IconButton(
          onPressed: _renameSelected,
          icon: const Icon(Icons.edit),
        ),
      IconButton(
        onPressed: _deleteSelected,
        icon: const Icon(Icons.delete),
      ),
      if (_selectedItems.length == 1)
        IconButton(
          onPressed: _showProperties,
          icon: const Icon(Icons.info),
        ),
    ];
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentContents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 80.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'Empty Directory',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentContents.length,
      itemBuilder: (context, index) {
        final entity = _currentContents[index];
        final isSelected = _selectedItems.contains(entity.path);

        return FileManagerItem(
          entity: entity,
          isSelected: isSelected,
          onTap: () => _onItemTap(entity),
          onLongPress: () => _onItemLongPress(entity),
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      await _loadDirectory(_currentPath);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _fileManager.searchFiles(_currentPath, query);
      setState(() {
        _currentContents = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Search failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}