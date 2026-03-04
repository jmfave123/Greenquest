/// A value object representing a single department–section assignment
/// on an instructor document.
///
/// This is NOT a top-level Firestore collection — it is stored as an element
/// inside the `assignments` array on an `instructors` document.
///
/// Firestore shape (inside instructors/{id}.assignments[]):
/// ```json
/// {
///   "departmentId": "abc123",
///   "sectionId":    "xyz789",
///   "departmentName": "Bachelor of Science in Information Technology",
///   "departmentCode": "BSIT",
///   "sectionName":    "BSIT-1A",
///   "sectionCode":    "BSIT-1A"
/// }
/// ```
class InstructorAssignment {
  final String departmentId;
  final String sectionId;
  final String departmentName;
  final String departmentCode;

  /// Mirrors [sectionCode] — kept for historical Firestore compatibility.
  final String sectionName;
  final String sectionCode;

  const InstructorAssignment({
    required this.departmentId,
    required this.sectionId,
    required this.departmentName,
    required this.departmentCode,
    required this.sectionName,
    required this.sectionCode,
  });

  /// The short display label shown in chips/lists (e.g. "BSIT-1A").
  String get label => '$departmentCode-$sectionCode';

  /// Creates an [InstructorAssignment] from a raw Firestore map.
  factory InstructorAssignment.fromMap(Map<String, dynamic> map) {
    return InstructorAssignment(
      departmentId: map['departmentId']?.toString() ?? '',
      sectionId: map['sectionId']?.toString() ?? '',
      departmentName: map['departmentName']?.toString() ?? '',
      departmentCode: map['departmentCode']?.toString() ?? '',
      sectionName: map['sectionName']?.toString() ?? '',
      sectionCode: map['sectionCode']?.toString() ?? '',
    );
  }

  /// Converts this value object to a plain map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'sectionId': sectionId,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
      'sectionName': sectionName,
      'sectionCode': sectionCode,
    };
  }

  /// Returns true when all required fields are non-empty.
  bool get isValid =>
      departmentId.isNotEmpty &&
      sectionId.isNotEmpty &&
      departmentName.isNotEmpty &&
      departmentCode.isNotEmpty &&
      sectionCode.isNotEmpty;

  /// Returns a copy of this value object with the given fields replaced.
  InstructorAssignment copyWith({
    String? departmentId,
    String? sectionId,
    String? departmentName,
    String? departmentCode,
    String? sectionName,
    String? sectionCode,
  }) {
    return InstructorAssignment(
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      sectionName: sectionName ?? this.sectionName,
      sectionCode: sectionCode ?? this.sectionCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructorAssignment &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId &&
          sectionId == other.sectionId;

  @override
  int get hashCode => Object.hash(departmentId, sectionId);

  @override
  String toString() =>
      'InstructorAssignment(dept: $departmentCode, section: $sectionCode)';
}
