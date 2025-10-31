/// Model representing a single class schedule (meeting time)
class ClassSchedule {
  final String day;
  final String startTime;
  final String endTime;
  final String? room; // Optional: can be different per schedule or same for all

  ClassSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      if (room != null && room!.isNotEmpty) 'room': room,
    };
  }

  /// Create from Map (Firestore)
  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      room: map['room'],
    );
  }

  /// Create a copy with modified fields
  ClassSchedule copyWith({
    String? day,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return ClassSchedule(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }
}
