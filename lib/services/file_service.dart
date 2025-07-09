import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_model.dart';

class FileService {
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API level 33+), we need different permissions
      final androidInfo = await _getAndroidInfo();
      if (androidInfo >= 33) {
        // Request media permissions for Android 13+
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
        
        return statuses.values.every((status) => status.isGranted);
      } else {
        // For older Android versions
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permissions for app documents
      return true;
    }
    return false;
  }

  Future<int> _getAndroidInfo() async {
    // This is a placeholder - in real implementation, you would use
    // device_info_plus package to get Android SDK version
    return 33; // Assume Android 13+ for demo
  }

  Future<List<FileModel>> getDeviceFiles() async {
    List<FileModel> files = [];
    
    try {
      // Get common directories
      final directories = await _getSearchDirectories();
      
      for (final directory in directories) {
        if (await directory.exists()) {
          final dirFiles = await _scanDirectory(directory);
          files.addAll(dirFiles);
        }
      }
      
      // Filter for supported file types
      files = files.where((file) => _isSupportedFileType(file.extension)).toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
    } catch (e) {
      print('Error getting device files: $e');
    }
    
    return files;
  }

  Future<List<Directory>> _getSearchDirectories() async {
    List<Directory> directories = [];
    
    if (Platform.isAndroid) {
      // Get external storage directories
      final externalStorageDir = await getExternalStorageDirectory();
      if (externalStorageDir != null) {
        directories.add(externalStorageDir);
        
        // Common document directories
        final documentsDir = Directory('${externalStorageDir.path}/Documents');
        final downloadsDir = Directory('${externalStorageDir.path}/Download');
        
        directories.addAll([documentsDir, downloadsDir]);
      }
      
      // Application documents directory
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      directories.add(appDocumentsDir);
      
    } else if (Platform.isIOS) {
      // iOS app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(documentsDir);
    }
    
    return directories;
  }

  Future<List<FileModel>> _scanDirectory(Directory directory) async {
    List<FileModel> files = [];
    
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileStat = await entity.stat();
          final fileName = entity.path.split('/').last;
          final fileExtension = fileName.split('.').last.toLowerCase();
          
          files.add(FileModel(
            name: fileName,
            path: entity.path,
            size: fileStat.size,
            lastModified: fileStat.modified,
            extension: fileExtension,
          ));
        }
      }
    } catch (e) {
      print('Error scanning directory ${directory.path}: $e');
    }
    
    return files;
  }

  bool _isSupportedFileType(String extension) {
    final supportedTypes = [
      'pdf', 'doc', 'docx', 'txt', 'rtf',
      'jpg', 'jpeg', 'png', 'gif', 'bmp',
      'mp4', 'avi', 'mov', 'mkv',
      'mp3', 'wav', 'aac', 'flac',
    ];
    
    return supportedTypes.contains(extension.toLowerCase());
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    return false;
  }

  Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();
      return _formatFileSize(size);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}