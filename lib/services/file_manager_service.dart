import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_model.dart';

enum FileOperation { copy, cut }

class FileManagerService {
  static final FileManagerService _instance = FileManagerService._internal();
  static FileManagerService get instance => _instance;
  
  FileManagerService._internal();

  List<FileSystemEntity> _clipboard = [];
  FileOperation? _clipboardOperation;
  String? _currentDirectory;

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidInfo();
      if (androidInfo >= 33) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
          Permission.manageExternalStorage,
        ].request();
        
        return statuses.values.any((status) => status.isGranted);
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  Future<int> _getAndroidInfo() async {
    return 33; // Assume Android 13+ for demo
  }

  Future<String> getDefaultDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      return externalDir?.path ?? '/storage/emulated/0';
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    }
  }

  Future<List<FileSystemEntity>> getDirectoryContents(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist');
      }

      final contents = await directory.list().toList();
      
      // Sort: directories first, then files, alphabetically
      contents.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return path.basename(a.path).toLowerCase().compareTo(
          path.basename(b.path).toLowerCase()
        );
      });

      _currentDirectory = directoryPath;
      return contents;
    } catch (e) {
      throw Exception('Failed to read directory: $e');
    }
  }

  Future<FileModel> getFileInfo(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final fileName = path.basename(filePath);
    final extension = path.extension(fileName).replaceFirst('.', '');

    return FileModel(
      name: fileName,
      path: filePath,
      size: stat.size,
      lastModified: stat.modified,
      extension: extension,
    );
  }

  // File Operations
  Future<bool> createFile(String directoryPath, String fileName, {String content = ''}) async {
    try {
      final filePath = path.join(directoryPath, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        throw Exception('File already exists');
      }
      
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error creating file: $e');
      return false;
    }
  }

  Future<bool> createDirectory(String parentPath, String directoryName) async {
    try {
      final dirPath = path.join(parentPath, directoryName);
      final directory = Directory(dirPath);
      
      if (await directory.exists()) {
        throw Exception('Directory already exists');
      }
      
      await directory.create(recursive: true);
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  Future<bool> renameFileOrDirectory(String oldPath, String newName) async {
    try {
      final entity = await FileSystemEntity.type(oldPath);
      final parentDir = path.dirname(oldPath);
      final newPath = path.join(parentDir, newName);
      
      if (entity == FileSystemEntityType.file) {
        final file = File(oldPath);
        await file.rename(newPath);
      } else if (entity == FileSystemEntityType.directory) {
        final directory = Directory(oldPath);
        await directory.rename(newPath);
      }
      
      return true;
    } catch (e) {
      print('Error renaming: $e');
      return false;
    }
  }

  Future<bool> deleteFileOrDirectory(String filePath) async {
    try {
      final entity = await FileSystemEntity.type(filePath);
      
      if (entity == FileSystemEntityType.file) {
        final file = File(filePath);
        await file.delete();
      } else if (entity == FileSystemEntityType.directory) {
        final directory = Directory(filePath);
        await directory.delete(recursive: true);
      }
      
      return true;
    } catch (e) {
      print('Error deleting: $e');
      return false;
    }
  }

  // Clipboard Operations
  void copyToClipboard(List<String> paths) {
    _clipboard = paths.map((p) => File(p).existsSync() ? File(p) : Directory(p) as FileSystemEntity).toList();
    _clipboardOperation = FileOperation.copy;
  }

  void cutToClipboard(List<String> paths) {
    _clipboard = paths.map((p) => File(p).existsSync() ? File(p) : Directory(p) as FileSystemEntity).toList();
    _clipboardOperation = FileOperation.cut;
  }

  Future<bool> pasteFromClipboard(String destinationPath) async {
    if (_clipboard.isEmpty || _clipboardOperation == null) {
      return false;
    }

    try {
      for (final entity in _clipboard) {
        final fileName = path.basename(entity.path);
        final destinationFilePath = path.join(destinationPath, fileName);

        if (entity is File) {
          if (_clipboardOperation == FileOperation.copy) {
            await entity.copy(destinationFilePath);
          } else {
            await entity.rename(destinationFilePath);
          }
        } else if (entity is Directory) {
          if (_clipboardOperation == FileOperation.copy) {
            await _copyDirectory(entity.path, destinationFilePath);
          } else {
            await entity.rename(destinationFilePath);
          }
        }
      }

      if (_clipboardOperation == FileOperation.cut) {
        clearClipboard();
      }

      return true;
    } catch (e) {
      print('Error pasting: $e');
      return false;
    }
  }

  Future<void> _copyDirectory(String sourcePath, String destinationPath) async {
    final sourceDir = Directory(sourcePath);
    final destDir = Directory(destinationPath);
    
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final fileName = path.basename(entity.path);
      final destPath = path.join(destinationPath, fileName);

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity.path, destPath);
      }
    }
  }

  void clearClipboard() {
    _clipboard.clear();
    _clipboardOperation = null;
  }

  bool get hasClipboardContent => _clipboard.isNotEmpty;
  FileOperation? get clipboardOperation => _clipboardOperation;
  int get clipboardCount => _clipboard.length;

  // File Content Operations
  Future<String> readTextFile(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  Future<bool> writeTextFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }

  Future<Uint8List> readBinaryFile(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read binary file: $e');
    }
  }

  // Search functionality
  Future<List<FileSystemEntity>> searchFiles(String directoryPath, String query) async {
    final results = <FileSystemEntity>[];
    final directory = Directory(directoryPath);

    await for (final entity in directory.list(recursive: true)) {
      final fileName = path.basename(entity.path).toLowerCase();
      if (fileName.contains(query.toLowerCase())) {
        results.add(entity);
      }
    }

    return results;
  }

  // Get file/directory properties
  Future<Map<String, dynamic>> getProperties(String filePath) async {
    final stat = await FileStat.stat(filePath);
    final entity = await FileSystemEntity.type(filePath);
    
    return {
      'name': path.basename(filePath),
      'path': filePath,
      'size': stat.size,
      'type': entity == FileSystemEntityType.directory ? 'Directory' : 'File',
      'modified': stat.modified,
      'accessed': stat.accessed,
      'permissions': stat.modeString(),
    };
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}