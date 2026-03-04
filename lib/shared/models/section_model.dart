import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a section within a department.
///
/// Firestore collection: `sections`
/// Fields: departmentId, year, sectionLetter, subCode (optional),
///         sectionCode (stored derived value), createdAt, updatedAt
class Section {
  final String id;
  final String departmentId;

  /// Academic year level (e.g. "1st", "2nd", "3rd", "4th").
  final String year;

  /// Single-letter section identifier (e.g. "A", "B").
  final String sectionLetter;

  /// Optional sub-code inserted between department code and year
  /// (e.g. "NSTP" → "BSIT-NSTP-1A").
  final String? subCode;

  /// Full generated section code stored in Firestore
  /// (e.g. "BSIT-1A" or "BSIT-NSTP-1A").
  final String sectionCode;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Section({
    required this.id,
    required this.departmentId,
    required this.year,
    required this.sectionLetter,
    required this.sectionCode,
    this.subCode,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Section] from a Firestore document snapshot.
  factory Section.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Section.fromMap(data, doc.id);
  }

  /// Creates a [Section] from a raw map and a document [id].
  factory Section.fromMap(Map<String, dynamic> map, String id) {
    return Section(
      id: id,
      departmentId: map['departmentId']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      sectionLetter: map['sectionLetter']?.toString() ?? '',
      subCode: map['subCode']?.toString(),
      sectionCode: map['sectionCode']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this model to a map suitable for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'year': year,
      'sectionLetter': sectionLetter,
      'subCode': subCode,
      'sectionCode': sectionCode,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  Section copyWith({
    String? id,
    String? departmentId,
    String? year,
    String? sectionLetter,
    String? subCode,
    String? sectionCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Section(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      year: year ?? this.year,
      sectionLetter: sectionLetter ?? this.sectionLetter,
      subCode: subCode ?? this.subCode,
      sectionCode: sectionCode ?? this.sectionCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Section(id: $id, sectionCode: $sectionCode, departmentId: $departmentId)';
}
