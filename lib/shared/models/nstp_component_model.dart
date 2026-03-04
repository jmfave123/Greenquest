import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single NSTP (National Service Training Program) component.
///
/// Firestore collection: `nstp_components`
/// Fields: name, description, isActive, createdAt, updatedAt
class NstpComponent {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NstpComponent({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [NstpComponent] from a Firestore document snapshot.
  factory NstpComponent.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NstpComponent.fromMap(data, doc.id);
  }

  /// Creates an [NstpComponent] from a raw map and a document [id].
  factory NstpComponent.fromMap(Map<String, dynamic> map, String id) {
    return NstpComponent(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this model to a map suitable for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  NstpComponent copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NstpComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NstpComponent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NstpComponent(id: $id, name: $name, isActive: $isActive)';
}
