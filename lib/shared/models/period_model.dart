import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a semester / academic period.
///
/// Firestore collection: `periods`
/// Fields: semesterName, type, isActive, createdAt, updatedAt
class Period {
  final String id;

  /// Display name for the semester (e.g. "1st Semester 2025-2026").
  final String semesterName;

  /// Period type (e.g. "Regular", "Summer", or empty string).
  final String type;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Period({
    required this.id,
    required this.semesterName,
    this.type = '',
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Human-readable label combining [semesterName] and [type] when available.
  String get label => type.isNotEmpty ? '$semesterName — $type' : semesterName;

  /// Creates a [Period] from a Firestore document snapshot.
  factory Period.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Period.fromMap(data, doc.id);
  }

  /// Creates a [Period] from a raw map and a document [id].
  factory Period.fromMap(Map<String, dynamic> map, String id) {
    return Period(
      id: id,
      semesterName: map['semesterName']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isActive: map['isActive'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this model to a map suitable for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'semesterName': semesterName,
      'type': type,
      'isActive': isActive,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  Period copyWith({
    String? id,
    String? semesterName,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Period(
      id: id ?? this.id,
      semesterName: semesterName ?? this.semesterName,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Period && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Period(id: $id, semesterName: $semesterName, type: $type, isActive: $isActive)';
}
