class FileTypeUtils {
  // Image file extensions
  static const List<String> _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'ico',
  ];

  // Video file extensions
  static const List<String> _videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'wmv',
    'flv',
    'webm',
    'm4v',
  ];

  // Audio file extensions
  static const List<String> _audioExtensions = [
    'mp3',
    'wav',
    'aac',
    'flac',
    'ogg',
    'm4a',
    'wma',
  ];

  // Document file extensions
  static const List<String> _documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf',
  ];

  // Spreadsheet file extensions
  static const List<String> _spreadsheetExtensions = ['xls', 'xlsx', 'csv'];

  // Presentation file extensions
  static const List<String> _presentationExtensions = ['ppt', 'pptx'];

  // Archive file extensions
  static const List<String> _archiveExtensions = [
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
  ];

  /// Check if file is an image
  static bool isImageFile(String fileType) {
    return _imageExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is a video
  static bool isVideoFile(String fileType) {
    return _videoExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is audio
  static bool isAudioFile(String fileType) {
    return _audioExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is a document
  static bool isDocumentFile(String fileType) {
    return _documentExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is a spreadsheet
  static bool isSpreadsheetFile(String fileType) {
    return _spreadsheetExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is a presentation
  static bool isPresentationFile(String fileType) {
    return _presentationExtensions.contains(fileType.toLowerCase());
  }

  /// Check if file is an archive
  static bool isArchiveFile(String fileType) {
    return _archiveExtensions.contains(fileType.toLowerCase());
  }

  /// Get file category for display
  static String getFileCategory(String fileType) {
    if (isImageFile(fileType)) return 'image';
    if (isVideoFile(fileType)) return 'video';
    if (isAudioFile(fileType)) return 'audio';
    if (isDocumentFile(fileType)) return 'document';
    if (isSpreadsheetFile(fileType)) return 'spreadsheet';
    if (isPresentationFile(fileType)) return 'presentation';
    if (isArchiveFile(fileType)) return 'archive';
    return 'file';
  }

  /// Get appropriate icon for file type
  static String getFileIcon(String fileType) {
    final category = getFileCategory(fileType);

    switch (category) {
      case 'image':
        return '🖼️';
      case 'video':
        return '🎥';
      case 'audio':
        return '🎵';
      case 'document':
        return '📄';
      case 'spreadsheet':
        return '📊';
      case 'presentation':
        return '📽️';
      case 'archive':
        return '📦';
      default:
        return '📁';
    }
  }

  /// Get file type color
  static int getFileColor(String fileType) {
    final category = getFileCategory(fileType);

    switch (category) {
      case 'image':
        return 0xFF4CAF50; // Green
      case 'video':
        return 0xFF2196F3; // Blue
      case 'audio':
        return 0xFF9C27B0; // Purple
      case 'document':
        return 0xFFF44336; // Red
      case 'spreadsheet':
        return 0xFF4CAF50; // Green
      case 'presentation':
        return 0xFFFF9800; // Orange
      case 'archive':
        return 0xFF607D8B; // Blue Grey
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Check if file should be displayed inline (image/video)
  static bool shouldDisplayInline(String fileType) {
    return isImageFile(fileType) || isVideoFile(fileType);
  }

  /// Check if file should be downloaded
  static bool shouldDownload(String fileType) {
    return isDocumentFile(fileType) ||
        isSpreadsheetFile(fileType) ||
        isPresentationFile(fileType) ||
        isArchiveFile(fileType);
  }
}
