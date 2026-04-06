// import 'package:cloud_firestore/cloud_firestore.dart';

// final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Future<void> loadTreeStats() async {
//   try {
//     // Query approved tree planting submissions (same as Manage Trees screen)
//     final treesSnapshot =
//         await _firestore
//             .collection('submissions')
//             .where('activityType', isEqualTo: 'tree_planting')
//             .where('status', isEqualTo: 'approved')
//             .get();

//     int totalQuantity = 0;
//     for (final doc in treesSnapshot.docs) {
//       final data = doc.data();
//       final quantity = data['quantity'];
//       if (quantity is num) {
//         totalQuantity += quantity.toInt();
//       } else {
//         totalQuantity += 1;
//       }
//     }

//     if (!mounted) return;
//     setState(() {
//       _totalTreeCount = totalQuantity;
//       _isTreeCountLoading = false;
//     });
//   } catch (e) {
//     _log('Error loading tree stats: $e');
//     if (!mounted) return;
//     setState(() {
//       _totalTreeCount = 0;
//       _isTreeCountLoading = false;
//     });
//   }
// }
