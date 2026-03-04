import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a department in the institution.
///
/// Firestore collection: `departments`
/// Fields: name (lowercase), displayName (original case), code (uppercase),
///         description, createdAt, updatedAt
class Department {
  final String id;

  /// Lowercase version of the name, used for case-insensitive comparisons.
  final String name;

  /// Original-case version of the name, used for display.
  final String displayName;

  /// Uppercase department code (e.g. "BSIT", "BSCS").
  final String code;

  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Department({
    required this.id,
    required this.name,
    required this.displayName,
    required this.code,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  /// The label shown in dropdowns and lists: "Display Name (CODE)".
  String get label => '$displayName ($code)';

  /// Creates a [Department] from a Firestore document snapshot.
  factory Department.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Department.fromMap(data, doc.id);
  }

  /// Creates a [Department] from a raw map and a document [id].
  factory Department.fromMap(Map<String, dynamic> map, String id) {
    final rawName = map['name']?.toString() ?? '';
    final rawDisplay = map['displayName']?.toString() ?? '';
    return Department(
      id: id,
      name: rawName,
      // Fall back to name if displayName is absent (legacy documents)
      displayName: rawDisplay.isNotEmpty ? rawDisplay : rawName,
      code: map['code']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this model to a map suitable for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name.toLowerCase(),
      'displayName': displayName,
      'code': code.toUpperCase(),
      'description': description,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  Department copyWith({
    String? id,
    String? name,
    String? displayName,
    String? code,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Department(id: $id, displayName: $displayName, code: $code)';
}
