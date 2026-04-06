import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/core/utils/app_logger.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
List<String> programs = ['All Programs'];

Future<void> loadPrograms() async {
  try {
    final departmentsSnapshot =
        await _firestore.collection('departments').get();
    final departmentCodes =
        departmentsSnapshot.docs
            .map((doc) => doc.data()['code'] as String? ?? '')
            .where((code) => code.isNotEmpty)
            .toList();

    setState(() {
      programs = ['All Programs', ...departmentCodes];
    });
  } catch (e) {
    AppLogger('Error loading programs: $e');
  }
}

void setState(Null Function() param0) {}
