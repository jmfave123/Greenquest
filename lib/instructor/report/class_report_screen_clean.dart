// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../shared/instructor/instructor_appbar.dart';
// import '../../shared/instructor/instructor_sidebar.dart';
// import '../../shared/instructor/instructor_navigation_constants.dart';
// import '../../shared/services/export_service.dart';
// import '../../shared/class_record/class_record_table.dart';
// import 'class_report_controller.dart';

// class ClassReportScreen extends StatefulWidget {
//   const ClassReportScreen({super.key});

//   @override
//   State<ClassReportScreen> createState() => _ClassReportScreenState();
// }

// class _ClassReportScreenState extends State<ClassReportScreen> {
//   late ClassReportController _classReportController;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // State variables for different item types
//   List<Map<String, dynamic>> _classStandingItems = [];
//   List<Map<String, dynamic>> _quizPrelimItems = [];
//   List<Map<String, dynamic>> _midtermExamItems = [];
//   List<Map<String, dynamic>> _pitItems = [];

//   // UI controllers
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _activityNameController = TextEditingController();
//   final TextEditingController _maxScoreController = TextEditingController();
//   final TextEditingController _activityTypeController = TextEditingController();

//   // UI state
//   String _searchQuery = '';
//   bool _showAddActivity = false;
//   InstructorNavigationItem _selectedItem = InstructorNavigationItem.reports;

//   @override
//   void initState() {
//     super.initState();
//     _classReportController = Get.put(ClassReportController());
//     _fetchClassStandingItems();
//     _fetchQuizPrelimItems();
//     _fetchMidtermExamItems();
//     _fetchPitItems();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _activityNameController.dispose();
//     _maxScoreController.dispose();
//     _activityTypeController.dispose();
//     super.dispose();
//   }

//   // Build simple dynamic table for class standing
//   Widget _buildDynamicClassStandingTable(List<Map<String, dynamic>> scores) {
//     print('🔍 Building Syncfusion DataGrid with ${scores.length} students');
//     print('🔍 Class standing items: ${_classStandingItems.length}');
//     print('🔍 Quiz/prelim items: ${_quizPrelimItems.length}');
//     print('🔍 Midterm exam items: ${_midtermExamItems.length}');
//     print('🔍 PIT items: ${_pitItems.length}');

//     // Show message if no class standing items
//     if (_classStandingItems.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.assignment, size: 64, color: Colors.grey),
//               SizedBox(height: 16),
//               Text(
//                 'No Class Standing Items Found',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Create assignments, activities, or quizzes with category "class_standing"',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // Use the new Syncfusion DataGrid component
//     return ClassRecordTable(
//       students: scores,
//       classStandingItems: _classStandingItems,
//       quizPrelimItems: _quizPrelimItems,
//       midtermExamItems: _midtermExamItems,
//       pitItems: _pitItems,
//       onCellValueChanged: (student, itemKey, value) {
//         // Handle cell editing if needed in the future
//         print(
//           'Cell value changed: $itemKey = $value for student ${student['name']}',
//         );
//       },
//     );
//   }

//   // Fetch class standing items from database (all item types) - filtered by current section
//   Future<void> _fetchClassStandingItems() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get current section code for filtering
//       final currentSectionCode = _classReportController.sectionName.value;
//       if (currentSectionCode.isEmpty) {
//         print(
//           '⚠️ No section code available for filtering class standing items',
//         );
//         return;
//       }

//       print(
//         '🔍 Fetching class standing items for section: $currentSectionCode',
//       );
//       List<Map<String, dynamic>> items = [];

//       // Fetch assignments with category: 'class_standing' AND selectedClasses containing current section
//       final assignmentsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('assignments')
//               .where('category', isEqualTo: 'class_standing')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in assignmentsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'assignment',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add activities
//       final activitiesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('activities')
//               .where('category', isEqualTo: 'class_standing')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in activitiesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'activity',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add quizzes
//       final quizzesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('quizzes')
//               .where('category', isEqualTo: 'class_standing')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in quizzesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'quiz',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add PITs
//       final pitsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('pits')
//               .where('category', isEqualTo: 'class_standing')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in pitsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'pit',
//           'category': doc.data()['category'],
//         });
//       }

//       // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
//       items.sort((a, b) => a['title'].compareTo(b['title']));

//       setState(() {
//         _classStandingItems = items;
//       });

//       print(
//         '✅ Fetched ${_classStandingItems.length} class standing items (all types) for section $currentSectionCode',
//       );
//       for (int i = 0; i < _classStandingItems.length; i++) {
//         var item = _classStandingItems[i];
//         print(
//           '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
//         );
//       }
//     } catch (e) {
//       print('❌ Error fetching class standing items: $e');
//     }
//   }

//   // Fetch quiz/prelim items from database (all item types) - filtered by current section
//   Future<void> _fetchQuizPrelimItems() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get current section code for filtering
//       final currentSectionCode = _classReportController.sectionName.value;
//       if (currentSectionCode.isEmpty) {
//         print('⚠️ No section code available for filtering quiz/prelim items');
//         return;
//       }

//       print('🔍 Fetching quiz/prelim items for section: $currentSectionCode');
//       List<Map<String, dynamic>> items = [];

//       // Fetch assignments with category: 'quiz_prelim' AND selectedClasses containing current section
//       final assignmentsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('assignments')
//               .where('category', isEqualTo: 'quiz_prelim')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in assignmentsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'assignment',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add activities
//       final activitiesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('activities')
//               .where('category', isEqualTo: 'quiz_prelim')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in activitiesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'activity',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add quizzes
//       final quizzesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('quizzes')
//               .where('category', isEqualTo: 'quiz_prelim')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in quizzesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'quiz',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add PITs
//       final pitsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('pits')
//               .where('category', isEqualTo: 'quiz_prelim')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in pitsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'pit',
//           'category': doc.data()['category'],
//         });
//       }

//       // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
//       items.sort((a, b) => a['title'].compareTo(b['title']));

//       setState(() {
//         _quizPrelimItems = items;
//       });

//       print(
//         '✅ Fetched ${_quizPrelimItems.length} quiz/prelim items (all types) for section $currentSectionCode',
//       );
//       for (int i = 0; i < _quizPrelimItems.length; i++) {
//         var item = _quizPrelimItems[i];
//         print(
//           '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
//         );
//       }
//     } catch (e) {
//       print('❌ Error fetching quiz/prelim items: $e');
//     }
//   }

//   // Fetch midterm exam items from database (all item types) - filtered by current section
//   Future<void> _fetchMidtermExamItems() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get current section code for filtering
//       final currentSectionCode = _classReportController.sectionName.value;
//       if (currentSectionCode.isEmpty) {
//         print('⚠️ No section code available for filtering midterm exam items');
//         return;
//       }

//       print('🔍 Fetching midterm exam items for section: $currentSectionCode');
//       List<Map<String, dynamic>> items = [];

//       // Fetch assignments with category: 'midterm_exam' AND selectedClasses containing current section
//       final assignmentsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('assignments')
//               .where('category', isEqualTo: 'midterm_exam')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in assignmentsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'assignment',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add activities
//       final activitiesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('activities')
//               .where('category', isEqualTo: 'midterm_exam')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in activitiesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'activity',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add quizzes
//       final quizzesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('quizzes')
//               .where('category', isEqualTo: 'midterm_exam')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in quizzesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'quiz',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add PITs
//       final pitsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('pits')
//               .where('category', isEqualTo: 'midterm_exam')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in pitsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'pit',
//           'category': doc.data()['category'],
//         });
//       }

//       // Sort items by title to ensure proper order
//       items.sort((a, b) => a['title'].compareTo(b['title']));

//       setState(() {
//         _midtermExamItems = items;
//       });

//       print(
//         '✅ Fetched ${_midtermExamItems.length} midterm exam items (all types) for section $currentSectionCode',
//       );
//       for (int i = 0; i < _midtermExamItems.length; i++) {
//         var item = _midtermExamItems[i];
//         print(
//           '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
//         );
//       }
//     } catch (e) {
//       print('❌ Error fetching midterm exam items: $e');
//     }
//   }

//   // Fetch PIT items from database (all item types) - filtered by current section
//   Future<void> _fetchPitItems() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get current section code for filtering
//       final currentSectionCode = _classReportController.sectionName.value;
//       if (currentSectionCode.isEmpty) {
//         print('⚠️ No section code available for filtering PIT items');
//         return;
//       }

//       print('🔍 Fetching PIT items for section: $currentSectionCode');
//       List<Map<String, dynamic>> items = [];

//       // Fetch assignments with category: 'pit' AND selectedClasses containing current section
//       final assignmentsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('assignments')
//               .where('category', isEqualTo: 'pit')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in assignmentsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'assignment',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add activities
//       final activitiesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('activities')
//               .where('category', isEqualTo: 'pit')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in activitiesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'activity',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add quizzes
//       final quizzesQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('quizzes')
//               .where('category', isEqualTo: 'pit')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in quizzesQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'quiz',
//           'category': doc.data()['category'],
//         });
//       }

//       // Add PITs
//       final pitsQuery =
//           await _firestore
//               .collection('instructors')
//               .doc(user.uid)
//               .collection('pits')
//               .where('category', isEqualTo: 'pit')
//               .where('selectedClasses', arrayContains: currentSectionCode)
//               .get();

//       for (var doc in pitsQuery.docs) {
//         items.add({
//           'id': doc.id,
//           'title': doc.data()['title'],
//           'points': doc.data()['points'],
//           'type': 'pit',
//           'category': doc.data()['category'],
//         });
//       }

//       // Sort items by title to ensure proper order
//       items.sort((a, b) => a['title'].compareTo(b['title']));

//       setState(() {
//         _pitItems = items;
//       });

//       print(
//         '✅ Fetched ${_pitItems.length} PIT items (all types) for section $currentSectionCode',
//       );
//       for (int i = 0; i < _pitItems.length; i++) {
//         var item = _pitItems[i];
//         print(
//           '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
//         );
//       }
//     } catch (e) {
//       print('❌ Error fetching PIT items: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: const InstructorAppBar(),
//       body: Row(
//         children: [
//           // Sidebar
//           InstructorSidebar(
//             selectedItem: _selectedItem,
//             onItemSelected: (item) {
//               setState(() {
//                 _selectedItem = item;
//               });
//               String route = InstructorNavigationHelper.getRoute(item);
//               Navigator.of(context).pushReplacementNamed(route);
//             },
//           ),
//           // Main content
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Class Report',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           // Export functionality
//                         },
//                         icon: const Icon(Icons.download),
//                         label: const Text('Export'),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   // Table
//                   Expanded(
//                     child: FutureBuilder<List<Map<String, dynamic>>>(
//                       future: _classReportController.getStudentScores(),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }

//                         if (snapshot.hasError) {
//                           return Center(
//                             child: Text('Error: ${snapshot.error}'),
//                           );
//                         }

//                         final studentScores = snapshot.data ?? [];
//                         return _buildDynamicClassStandingTable(studentScores);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
