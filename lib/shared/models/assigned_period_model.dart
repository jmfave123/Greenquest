/// A value object representing a semester period assigned to an instructor.
///
/// This is NOT a top-level Firestore collection — it is stored as an element
/// inside the `assignedPeriods` array on an `instructors` document.
///
/// Firestore shape (inside instructors/{id}.assignedPeriods[]):
/// ```json
/// {
///   "periodId":     "abc123",
///   "semesterName": "1st Semester 2025-2026",
///   "type":         "Regular",
///   "isActive":     true
/// }
/// ```
class AssignedPeriod {
  final String periodId;
  final String semesterName;

  /// Period type (e.g. "Regular", "Summer", or empty string).
  final String type;
  final bool isActive;

  const AssignedPeriod({
    required this.periodId,
    required this.semesterName,
    this.type = '',
    this.isActive = false,
  });

  /// Human-readable label combining [semesterName] and [type] when available.
  String get label => type.isNotEmpty ? '$semesterName — $type' : semesterName;

  /// Creates an [AssignedPeriod] from a raw Firestore map.
  factory AssignedPeriod.fromMap(Map<String, dynamic> map) {
    return AssignedPeriod(
      periodId: map['periodId']?.toString() ?? '',
      semesterName: map['semesterName']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  /// Converts this value object to a plain map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'periodId': periodId,
      'semesterName': semesterName,
      'type': type,
      'isActive': isActive,
    };
  }

  /// Returns a copy with the given fields replaced.
  AssignedPeriod copyWith({
    String? periodId,
    String? semesterName,
    String? type,
    bool? isActive,
  }) {
    return AssignedPeriod(
      periodId: periodId ?? this.periodId,
      semesterName: semesterName ?? this.semesterName,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignedPeriod &&
          runtimeType == other.runtimeType &&
          periodId == other.periodId;

  @override
  int get hashCode => periodId.hashCode;

  @override
  String toString() =>
      'AssignedPeriod(periodId: $periodId, label: $label, isActive: $isActive)';
}
