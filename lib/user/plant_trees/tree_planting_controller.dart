import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:greenquest/core/utils/app_logger.dart';

class TreePlantingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxBool isSubmitting = false.obs;
  final RxList<Map<String, dynamic>> myTreeSubmissions =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingSubmissions = false.obs;
  final RxInt totalTreesPlanted = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyTreeSubmissions();
  }

  /// Submits a tree planting activity record.
  ///
  /// [quantity] — number of trees planted.
  /// [plantDate] — ISO date string (yyyy-MM-dd).
  /// [location] — place where trees were planted.
  /// [treeNames] — names of trees planted (up to 5 entries).
  /// [uploadedFiles] — Cloudinary upload metadata for photo evidence.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitTreePlanting({
    required int quantity,
    required String plantDate,
    required String location,
    required List<String> treeNames,
    required List<Map<String, dynamic>> uploadedFiles,
  }) async {
    try {
      isSubmitting.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data for student information and instructor
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Get student's selected instructor
      final selectedInstructorId = userData['selectedInstructorId'];
      final selectedSectionCode = userData['selectedSectionCode'];

      if (selectedInstructorId == null || selectedSectionCode == null) {
        throw Exception('Please select an instructor and section first');
      }

      // Get instructor name
      final instructorDoc =
          await _firestore
              .collection('instructors')
              .doc(selectedInstructorId)
              .get();
      final instructorName =
          instructorDoc.data()?['name'] ?? 'Unknown Instructor';

      // Create simplified tree planting submission data
      final submissionData = {
        'activityType': 'tree_planting',
        'activityId': 'tree_planting',
        'activityTitle': 'Tree Planting',
        'studentId': user.uid,
        'studentName':
            userData['fullName'] ?? user.displayName ?? 'Unknown Student',
        'studentIdNumber': userData['idNumber'] ?? user.uid,
        'nstpComponent': userData['nstpComponent'] ?? '',
        'instructorId': selectedInstructorId,
        'instructorName': instructorName,
        'sectionName': selectedSectionCode,
        'quantity': quantity,
        'plantDate': Timestamp.fromDate(DateTime.parse(plantDate)),
        'location': location,
        'treeNames': treeNames,
        'files':
            uploadedFiles
                .map(
                  (f) => {
                    'name': f['name'],
                    'url': f['url'],
                    'publicId': f['publicId'],
                    'size': f['size'],
                    'type': f['type'],
                  },
                )
                .toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'feedback': null,
        if (userData['assignedSemester'] != null)
          'assignedSemester': userData['assignedSemester'],
      };

      // Save directly to submissions collection
      await _firestore.collection('submissions').add(submissionData);

      AppLogger('Tree planting submission saved successfully');

      // Reload submissions
      await loadMyTreeSubmissions();

      isSubmitting.value = false;
      return true;
    } catch (e) {
      AppLogger('Error submitting tree planting');
      isSubmitting.value = false;
      return false;
    }
  }

  /// Load user's tree planting submissions
  Future<void> loadMyTreeSubmissions() async {
    try {
      isLoadingSubmissions.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        myTreeSubmissions.value = [];
        totalTreesPlanted.value = 0;
        isLoadingSubmissions.value = false;
        return;
      }

      final snapshot =
          await _firestore
              .collection('submissions')
              .where('activityType', isEqualTo: 'tree_planting')
              .where('studentId', isEqualTo: user.uid)
              .get();

      final submissions =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();

      // Sort by submittedAt in memory to avoid Firebase index requirement
      submissions.sort((a, b) {
        final aTime = a['submittedAt'] as Timestamp?;
        final bTime = b['submittedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      myTreeSubmissions.value = submissions;

      // Calculate total approved trees
      final approvedTrees = submissions
          .where((s) => s['status'] == 'approved')
          .fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));

      totalTreesPlanted.value = approvedTrees;
      isLoadingSubmissions.value = false;
    } catch (e) {
      AppLogger('Error loading tree submissions');
      myTreeSubmissions.value = [];
      totalTreesPlanted.value = 0;
      isLoadingSubmissions.value = false;
    }
  }

  /// Get status badge color
  String getStatusBadgeColor(String status) {
    switch (status) {
      case 'approved':
        return '0xFF34A853'; // Green
      case 'rejected':
        return '0xFFEA4335'; // Red
      case 'submitted':
      default:
        return '0xFFFBBC04'; // Yellow/Orange
    }
  }

  /// Get status display text
  String getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'submitted':
      default:
        return 'Pending Review';
    }
  }
}
