import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a notification in the system.
/// Supports multiple types like assignment, activity, quiz, pit, material, and announcement.
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final String itemId;
  final String targetType;
  final List<String> targetSections;
  final List<String> targetUsers;
  final Timestamp? createdAt;
  final String status;
  final List<String> readBy;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.itemId,
    required this.targetType,
    this.targetSections = const [],
    this.targetUsers = const [],
    this.createdAt,
    this.status = 'active',
    this.readBy = const [],
    this.metadata = const {},
  });

  /// Factory to create a NotificationModel from a Firestore map.
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: map['type']?.toString() ?? 'activity',
      title: map['title']?.toString() ?? 'New Notification',
      description: map['description']?.toString() ?? '',
      instructorId: map['instructorId']?.toString() ?? '',
      instructorName: map['instructorName']?.toString() ?? 'Unknown Instructor',
      itemId: map['itemId']?.toString() ?? '',
      targetType: map['targetType']?.toString() ?? '',
      targetSections: List<String>.from(map['targetSections'] ?? []),
      targetUsers: List<String>.from(map['targetUsers'] ?? []),
      createdAt: map['createdAt'],
      status: map['status']?.toString() ?? 'active',
      readBy: List<String>.from(map['readBy'] ?? []),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }

  /// Check if the notification has been read by a specific user.
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  /// Converts the model to a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'itemId': itemId,
      'targetType': targetType,
      'targetSections': targetSections,
      'targetUsers': targetUsers,
      'createdAt': createdAt,
      'status': status,
      'readBy': readBy,
      'metadata': metadata,
    };
  }
}
