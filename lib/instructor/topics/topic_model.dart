import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String id;
  final String topic;
  final String instructorId;
  final DateTime createdAt;

  Topic({
    required this.id,
    required this.topic,
    required this.instructorId,
    required this.createdAt,
  });

  // Convert Topic to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'instructorId': instructorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create Topic from Firestore document
  factory Topic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Topic(
      id: doc.id,
      topic: data['topic'] ?? '',
      instructorId: data['instructorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create Topic from Map
  factory Topic.fromMap(Map<String, dynamic> map, String id) {
    return Topic(
      id: id,
      topic: map['topic'] ?? '',
      instructorId: map['instructorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
