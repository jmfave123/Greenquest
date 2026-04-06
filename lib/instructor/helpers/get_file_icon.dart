import 'package:flutter/material.dart';

IconData getFileIcon(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return Icons.image;
    case 'mp4':
    case 'avi':
    case 'mov':
      return Icons.video_file;
    case 'zip':
    case 'rar':
      return Icons.archive;
    default:
      return Icons.attach_file;
  }
}
