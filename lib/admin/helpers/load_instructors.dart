import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/admin/helpers/get_day__abbreviation.dart';

Future<List<Map<String, dynamic>>> loadInstructors({
  required FirebaseFirestore firestore,
  void Function(Object?)? log,
}) async {
  final instructorsSnapshot = await firestore.collection('instructors').get();

  final allDeptsSnapshot = await firestore.collection('departments').get();
  final Map<String, Map<String, dynamic>> deptCache = {};
  for (var doc in allDeptsSnapshot.docs) {
    deptCache[doc.id] = doc.data();
  }

  final allUsersSnapshot = await firestore.collection('users').get();
  final Map<String, Map<String, dynamic>> userCacheById = {};
  final Map<String, Map<String, dynamic>> userCacheByStudentId = {};
  for (var doc in allUsersSnapshot.docs) {
    final data = doc.data();
    userCacheById[doc.id] = data;
    if (data['studentId'] != null) {
      userCacheByStudentId[data['studentId']] = data;
    }
  }

  final List<Map<String, dynamic>> instructors = [];

  for (var instructorDoc in instructorsSnapshot.docs) {
    final instructorData = instructorDoc.data();
    final instructorName = instructorData['name']?.toString().trim() ?? '';
    final instructorStatus = instructorData['status']?.toString() ?? 'Pending';

    if (instructorName.isEmpty || instructorName.toLowerCase() == 'unknown') {
      continue;
    }

    if (instructorStatus != 'Approved') {
      log?.call(
        '⏭️ Skipping instructor $instructorName - Status: $instructorStatus',
      );
      continue;
    }

    log?.call('🔍 Instructor: $instructorName');
    log?.call('   Document ID: ${instructorDoc.id}');

    final Map<String, String> departmentCodeToId = {};
    final Set<String> departmentCodes = {};
    final Set<String> departmentNames = {};

    final assignments = instructorData['assignments'];
    if (assignments != null && assignments is List && assignments.isNotEmpty) {
      log?.call('   📋 Found ${assignments.length} assignments');

      for (var i = 0; i < assignments.length; i++) {
        final assignmentData = assignments[i];

        if (assignmentData is Map) {
          final departmentId = assignmentData['departmentId']?.toString();
          final departmentCode = assignmentData['departmentCode']?.toString();

          if (departmentId != null && departmentCode != null) {
            departmentCodeToId[departmentCode] = departmentId;
            departmentCodes.add(departmentCode);

            log?.call(
              '   🔍 Assignment $i - DeptCode: $departmentCode, DeptId: $departmentId',
            );

            try {
              final departmentData = deptCache[departmentId];

              if (departmentData != null) {
                final deptName =
                    departmentData['displayName'] ??
                    departmentData['name'] ??
                    departmentData['code'] ??
                    departmentCode;

                departmentNames.add(deptName);
                log?.call('   ✅ Assignment $i - Department: $deptName');
              }
            } catch (e) {
              log?.call('   ❌ Error fetching department $departmentId: $e');
            }
          }
        }
      }
    }

    final departmentName =
        departmentNames.isNotEmpty
            ? departmentNames.join(', ')
            : (instructorData['department']?.toString() ?? 'N/A');

    log?.call('   ✅ Final department: $departmentName');
    log?.call('   ✅ Department codes: ${departmentCodes.join(', ')}');

    final classesSnapshot =
        await firestore
            .collection('instructors')
            .doc(instructorDoc.id)
            .collection('classes')
            .get();

    final studentsSnapshot =
        await firestore
            .collection('instructors')
            .doc(instructorDoc.id)
            .collection('students')
            .get();

    final List<Map<String, dynamic>> sections = [];
    final int totalStudents = studentsSnapshot.docs.length;

    final Map<String, List<Map<String, dynamic>>> studentsBySection = {};
    for (var studentDoc in studentsSnapshot.docs) {
      final studentData = studentDoc.data();
      final sectionName =
          studentData['selectedSectionCode']?.toString().trim() ?? 'Unknown';

      if (!studentsBySection.containsKey(sectionName)) {
        studentsBySection[sectionName] = [];
      }

      String studentProgramCode = 'N/A';
      final studentSectionCode =
          studentData['selectedSectionCode']?.toString().trim() ?? '';
      if (studentSectionCode.isNotEmpty) {
        final studentSectionMatch = RegExp(
          r'^([A-Z]+)',
        ).firstMatch(studentSectionCode);
        if (studentSectionMatch != null) {
          studentProgramCode = studentSectionMatch.group(1) ?? 'N/A';
        }
      }

      String idNumber = '';
      String profileImage = '';
      try {
        final userData = userCacheById[studentDoc.id];

        if (userData != null) {
          idNumber = userData['idNumber']?.toString() ?? '';
          profileImage =
              userData['profileImage']?.toString() ??
              userData['profileImageUrl']?.toString() ??
              userData['profileUrl']?.toString() ??
              '';
        } else {
          final studentId = studentData['studentId']?.toString() ?? '';

          if (studentId.isNotEmpty) {
            final fallbackUserData = userCacheByStudentId[studentId];

            if (fallbackUserData != null) {
              idNumber = fallbackUserData['idNumber']?.toString() ?? '';
              profileImage =
                  fallbackUserData['profileImage']?.toString() ??
                  fallbackUserData['profileImageUrl']?.toString() ??
                  fallbackUserData['profileUrl']?.toString() ??
                  '';
            }
          }
        }
      } catch (_) {}

      log?.call(
        '📝 Student: ${studentData['studentName']}, idNumber: "$idNumber"',
      );

      studentsBySection[sectionName]!.add({
        'name': studentData['studentName']?.toString() ?? 'Unknown',
        'studentName': studentData['studentName']?.toString() ?? 'Unknown',
        'email': studentData['email']?.toString() ?? '',
        'studentId': studentData['studentId']?.toString() ?? '',
        'idNumber': idNumber,
        'profileImage': profileImage,
        'status': studentData['isActive'] == true ? 'active' : 'inactive',
        'program': studentProgramCode,
      });
    }

    for (var classDoc in classesSnapshot.docs) {
      final classData = classDoc.data();
      final sectionName = classData['section']?.toString().trim() ?? '';

      if (sectionName.isEmpty) continue;

      final students = studentsBySection[sectionName] ?? [];
      final activeStudents =
          students.where((s) => s['status'] == 'active').length;
      final inactiveStudents = students.length - activeStudents;

      String sectionDeptCode = 'N/A';
      final sectionCodeMatch = RegExp(r'^([A-Z]+)').firstMatch(sectionName);
      if (sectionCodeMatch != null) {
        sectionDeptCode = sectionCodeMatch.group(1) ?? 'N/A';
      }

      String programCode = sectionDeptCode;
      if (!departmentCodes.contains(sectionDeptCode) &&
          departmentCodes.isNotEmpty) {
        programCode = departmentCodes.first;
      }

      final scheduleString = _formatSchedule(classData);

      sections.add({
        'id': classDoc.id,
        'name': sectionName,
        'code': classData['course'] ?? 'N/A',
        'schedule': scheduleString,
        'program': programCode,
        'active': activeStudents,
        'inactive': inactiveStudents,
        'students': students,
      });
    }

    instructors.add({
      'id': instructorDoc.id,
      'name': instructorName,
      'email': instructorData['email'] ?? 'N/A',
      'phone': instructorData['phone'] ?? '',
      'department': departmentName,
      'departmentCodes': departmentCodes.toList(),
      'profileUrl':
          instructorData['profileUrl'] ??
          instructorData['profileImageUrl'] ??
          '',
      'about': instructorData['about'] ?? '',
      'sections': sections,
      'totalSections': sections.length,
      'totalStudents': totalStudents,
    });
  }

  return instructors;
}

String _formatSchedule(Map<String, dynamic> classData) {
  if (classData.containsKey('schedules') && classData['schedules'] is List) {
    final schedules = List<Map<String, dynamic>>.from(classData['schedules']);
    if (schedules.isNotEmpty) {
      final allSameTime = schedules.every(
        (s) =>
            s['startTime'] == schedules[0]['startTime'] &&
            s['endTime'] == schedules[0]['endTime'],
      );

      if (allSameTime && schedules.length > 1) {
        final days = schedules
            .map((s) => getDayAbbreviation(s['day']?.toString() ?? ''))
            .join('/');
        return '$days ${schedules[0]['startTime']} - ${schedules[0]['endTime']}';
      } else {
        final scheduleStrings =
            schedules.map((schedule) {
              final dayAbbr = getDayAbbreviation(
                schedule['day']?.toString() ?? '',
              );
              return '$dayAbbr ${schedule['startTime']} - ${schedule['endTime']}';
            }).toList();
        return scheduleStrings.join(', ');
      }
    }
  }

  if (classData.containsKey('day') &&
      classData.containsKey('startTime') &&
      classData.containsKey('endTime')) {
    final dayAbbr = getDayAbbreviation(classData['day']?.toString() ?? '');
    return '$dayAbbr ${classData['startTime']} - ${classData['endTime']}';
  }

  return 'TBA';
}
