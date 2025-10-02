import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class TreeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  var registrations = <Map<String, dynamic>>[].obs;
  // Reactive variable for total trees
  var totalTrees = 0.obs;
  // Reactive variable for recent activity (trees added this week)
  var recentActivity = 0.obs;
  // Loading state
  var isLoading = false.obs;
  var instructorName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrees();
    fetchTotalTrees();
    fetchRecentActivity();
    loadInstructor();
  }

  // Fetch total number of trees registered
  Future<void> fetchTotalTrees() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid) // instructor document
              .collection('trees')
              .get();

      // Calculate total quantity from all trees
      int totalQuantity = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalQuantity += (data['quantity'] ?? 1) as int;
      }
      
      totalTrees.value = totalQuantity;
    } catch (e) {
      print("Error fetching total trees: $e");
    }
  }

  // Fetch recent activity (trees added this week)
  Future<void> fetchRecentActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('trees')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      int recentQuantity = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        recentQuantity += (data['quantity'] ?? 1) as int;
      }
      
      recentActivity.value = recentQuantity;
    } catch (e) {
      print("Error fetching recent activity: $e");
    }
  }

  // Fetch trees from Firestore
  Future<void> fetchTrees() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot =
          await _firestore
              .collection('instructors')
              .doc(user.uid) // assumes instructor = logged in user
              .collection('trees')
              .orderBy('createdAt', descending: true)
              .get();

      registrations.value =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final Timestamp? createdAtTs = data['createdAt'] as Timestamp?;
            final String dateString =
                createdAtTs != null
                    ? createdAtTs.toDate().toString().split(' ')[0]
                    : '';
            return {
              "id": doc.id,
              "date": dateString,
              "name": data['treeName'] ?? '',
              "location": data['location'] ?? '',
              "by": data['plantedBy'] ?? '',
              "quantity": data['quantity'] ?? 1,
            };
          }).toList();
    } catch (e) {
      print("Error fetching trees: $e");
    }
  }

  // Function to add a new tree
  Future<void> addTree({
    required String treeName,
    required String location,
    required String plantedBy,
    required String plantDate,
    required int quantity,
  }) async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("No logged-in user found");
      }

      // Tree data
      final treeData = {
        "treeName": treeName,
        "location": location,
        "plantedBy": plantedBy,
        "plantDate": plantDate,
        "quantity": quantity,
        "ownerId": user.uid, // store logged-in user id
        "createdAt": FieldValue.serverTimestamp(),
      };

      // 1 Save under instructor -> trees (user-specific collection)
      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('trees')
          .add(treeData);

      // Refresh data after adding
      await fetchTrees();
      await fetchTotalTrees();
      await fetchRecentActivity();

      Get.snackbar("Success", "Tree added successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to add tree: $e");
    } finally {
      isLoading.value = false;
    }
  }

  //  Edit tree
  Future<void> editTree(String docId, Map<String, dynamic> updatedData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('trees')
          .doc(docId)
          .update(updatedData);

      fetchTrees(); // refresh list
      fetchTotalTrees(); // refresh total count
      fetchRecentActivity(); // refresh recent activity
    } catch (e) {
      print("Error editing tree: $e");
    }
  }

  //  Delete tree
  Future<void> deleteTree(String docId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('trees')
          .doc(docId)
          .delete();

      registrations.removeWhere((r) => r['id'] == docId); // update local list
      fetchTotalTrees(); // refresh total count
      fetchRecentActivity(); // refresh recent activity
    } catch (e) {
      print("Error deleting tree: $e");
    }
  }

  /// Load instructor name using FirebaseAuth user.uid
  Future<void> loadInstructor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        instructorName.value = 'No user logged in';
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('instructors')
              .doc(user.uid) //  use user.uid here
              .get();

      if (doc.exists) {
        instructorName.value = doc['name'] ?? 'Unknown Instructor';
      } else {
        instructorName.value = 'Instructor not found';
      }
    } catch (e) {
      instructorName.value = 'Error loading name';
    }
  }
}
