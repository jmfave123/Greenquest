import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class TreeSubmissionEditData {
  final int quantity;
  final DateTime plantDate;
  final String location;
  final List<String> treeNames;
  final List<Map<String, dynamic>> retainedFiles;
  final List<PlatformFile> newFiles;

  const TreeSubmissionEditData({
    required this.quantity,
    required this.plantDate,
    required this.location,
    required this.treeNames,
    required this.retainedFiles,
    required this.newFiles,
  });
}

class TreeSubmissionEditHelper {
  const TreeSubmissionEditHelper._();

  static const int maxTreeNameFields = 5;
  static const int maxAttachmentFiles = 5;

  static bool isEditableStatus(String status) {
    return status == 'submitted' || status == 'rejected';
  }

  static DateTime resolvePlantDate(dynamic plantDate) {
    if (plantDate is Timestamp) {
      return plantDate.toDate();
    }
    if (plantDate is String && plantDate.trim().isNotEmpty) {
      return DateTime.tryParse(plantDate.trim()) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static List<String> extractTreeNames(Map<String, dynamic> submission) {
    final raw = submission['treeNames'];
    if (raw is! List) {
      return <String>[];
    }

    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .take(maxTreeNameFields)
        .toList();
  }

  static List<Map<String, dynamic>> extractAttachedFiles(
    Map<String, dynamic> submission,
  ) {
    final raw = submission['files'];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw.whereType<Map>().map((file) {
      return {
        'name': (file['name'] ?? '').toString(),
        'url': (file['url'] ?? '').toString(),
        'publicId': (file['publicId'] ?? '').toString(),
        'size': _asInt(file['size']),
        'type': (file['type'] ?? '').toString(),
      };
    }).toList();
  }

  static int remainingAttachmentSlots({
    required int retainedCount,
    required int newCount,
  }) {
    final remaining = maxAttachmentFiles - (retainedCount + newCount);
    return remaining < 0 ? 0 : remaining;
  }

  static String? validateAttachmentCount({
    required int retainedCount,
    required int newCount,
  }) {
    final total = retainedCount + newCount;
    if (total <= 0) {
      return 'Please keep at least one photo as evidence.';
    }
    if (total > maxAttachmentFiles) {
      return 'You can only attach up to $maxAttachmentFiles photos.';
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? validateQuantity(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter the number of trees planted.';
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return 'Please enter a valid number greater than 0.';
    }
    return null;
  }

  static String? validateLocation(String value) {
    if (value.trim().isEmpty) {
      return 'Please enter the planting location.';
    }
    return null;
  }
}
