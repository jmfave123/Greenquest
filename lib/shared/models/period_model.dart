import 'package:cloud_firestore/cloud_firestore.dart';

class Period {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isActive;

  Period({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory Period.fromMap(Map<String, dynamic> map, String id) {
    return Period(
      id: id,
      name: map['name'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
