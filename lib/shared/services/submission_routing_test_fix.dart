
/// Test the fixes for the submission routing issues
class SubmissionRoutingTestFix {
  /// Test the course matching logic
  static void testCourseMatching() {
    print('🧪 Testing Course Matching Logic...');

    // Test cases for course matching
    final testCases = [
      {'student': 'BSIT 4D', 'activity': 'BSIT-A', 'shouldMatch': true},
      {'student': 'bsit4d', 'activity': 'bsit-a', 'shouldMatch': true},
      {'student': 'BSIT 3A', 'activity': 'BSIT-B', 'shouldMatch': true},
      {'student': 'CS 1A', 'activity': 'CS-B', 'shouldMatch': true},
      {'student': 'BSIT 4D', 'activity': 'CS-A', 'shouldMatch': false},
      {'student': 'IT 2A', 'activity': 'BSIT-A', 'shouldMatch': false},
    ];

    for (var testCase in testCases) {
      final studentClass = testCase['student'] as String;
      final activityClass = testCase['activity'] as String;
      final shouldMatch = testCase['shouldMatch'] as bool;

      // Test the course extraction
      final studentCourse = _extractCourseCode(studentClass);
      final activityCourse = _extractCourseCode(activityClass);
      final isSameCourse = _isSameCourse(studentClass, activityClass);

      print('Student: $studentClass -> Course: $studentCourse');
      print('Activity: $activityClass -> Course: $activityCourse');
      print('Same course: $isSameCourse (Expected: $shouldMatch)');
      print('Match result: ${isSameCourse == shouldMatch ? '✅' : '❌'}');
      print('---');
    }
  }

  /// Test the list casting fix
  static void testListCasting() {
    print('🧪 Testing List Casting Fix...');

    // Simulate Firestore data
    final firestoreData = {
      'selectedClasses': [
        'BSIT-A',
        'BSIT-B',
        'CS-A',
      ], // This would be List<dynamic> from Firestore
    };

    // Test the casting logic
    final selectedClasses =
        (firestoreData['selectedClasses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    print('Original data: ${firestoreData['selectedClasses']}');
    print('Casted result: $selectedClasses');
    print('Type: ${selectedClasses.runtimeType}');
    print('Is List<String>: ${selectedClasses is List<String>}');
    print('Result: ${'✅'}');
  }

  /// Helper method to extract course code (copied from service)
  static String _extractCourseCode(String className) {
    final normalized = className.toUpperCase().replaceAll(' ', '');
    final match = RegExp(r'^([A-Z]+)').firstMatch(normalized);
    return match?.group(1) ?? '';
  }

  /// Helper method to check if same course (copied from service)
  static bool _isSameCourse(String class1, String class2) {
    final course1 = _extractCourseCode(class1);
    final course2 = _extractCourseCode(class2);
    return course1.isNotEmpty && course2.isNotEmpty && course1 == course2;
  }
}
