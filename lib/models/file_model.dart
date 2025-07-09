class FileModel {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final String extension;

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.extension,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDate {
    return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
  }

  bool get isPDF => extension.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension.toLowerCase());
  bool get isVideo => ['mp4', 'avi', 'mov', 'mkv'].contains(extension.toLowerCase());
  bool get isAudio => ['mp3', 'wav', 'aac', 'flac'].contains(extension.toLowerCase());
  bool get isDocument => ['doc', 'docx', 'txt', 'rtf'].contains(extension.toLowerCase());
}