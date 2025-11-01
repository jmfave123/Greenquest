import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/class_record/class_record_table.dart';
import 'class_report_controller.dart';
import '../../shared/services/export_service.dart';

class ClassReportScreen extends StatefulWidget {
  const ClassReportScreen({super.key});

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  late ClassReportController _classReportController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for different item types (Midterm)
  List<Map<String, dynamic>> _classStandingItems = [];
  List<Map<String, dynamic>> _quizPrelimItems = [];
  List<Map<String, dynamic>> _midtermExamItems = [];
  List<Map<String, dynamic>> _pitItems = [];

  // State variables for Final items
  List<Map<String, dynamic>> _finalClassStandingItems = [];
  List<Map<String, dynamic>> _finalQuizItems = [];
  List<Map<String, dynamic>> _finalExamItems = [];
  List<Map<String, dynamic>> _finalPitItems = [];

  // Semester filter state
  List<Map<String, dynamic>> _semesters = [];
  String? _selectedSemesterId; // null => All
  bool _isFiltering = false;

  // UI controllers (keeping for future use)
  // final TextEditingController _searchController = TextEditingController();
  // final TextEditingController _activityNameController = TextEditingController();
  // final TextEditingController _maxScoreController = TextEditingController();
  // final TextEditingController _activityTypeController = TextEditingController();

  // UI state
  InstructorNavigationItem _selectedItem = InstructorNavigationItem.reports;

  @override
  void initState() {
    super.initState();
    _classReportController = Get.put(ClassReportController());
    _loadSemesters();
    _fetchClassStandingItems();
    _fetchQuizPrelimItems();
    _fetchMidtermExamItems();
    _fetchPitItems();
    // Finals
    _fetchFinalClassStandingItems();
    _fetchFinalQuizItems();
    _fetchFinalExamItems();
    _fetchFinalPitItems();
  }

  @override
  void dispose() {
    // Controllers are commented out for now
    // _searchController.dispose();
    // _activityNameController.dispose();
    // _maxScoreController.dispose();
    // _activityTypeController.dispose();
    super.dispose();
  }

  // Build simple dynamic table for class standing
  Widget _buildDynamicClassStandingTable(List<Map<String, dynamic>> scores) {
    print('🔍 Building Syncfusion DataGrid with ${scores.length} students');
    print('🔍 Class standing items: ${_classStandingItems.length}');
    print('🔍 Quiz/prelim items: ${_quizPrelimItems.length}');
    print('🔍 Midterm exam items: ${_midtermExamItems.length}');
    print('🔍 PIT items: ${_pitItems.length}');

    // Show message if no class standing items
    if (_classStandingItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Class Standing Items Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Create assignments, activities, or quizzes with category "class_standing"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Use the new Syncfusion DataGrid component
    return ClassRecordTable(
      students: scores,
      classStandingItems: _classStandingItems,
      quizPrelimItems: _quizPrelimItems,
      midtermExamItems: _midtermExamItems,
      pitItems: _pitItems,
      finalClassStandingItems: [],
      finalQuizItems: [],
      finalExamItems: [],
      finalPitItems: [],
      onCellValueChanged: (student, itemKey, value) {
        // Handle cell editing if needed in the future
        print(
          'Cell value changed: $itemKey = $value for student ${student['name']}',
        );
      },
    );
  }

  // Build semester filter dropdown
  Widget _buildSemesterFilter() {
    final List<DropdownMenuItem<String?>> items = [
      const DropdownMenuItem<String?>(value: null, child: Text('All')),
      ..._semesters.map(
        (s) => DropdownMenuItem<String?>(
          value: s['id'] as String,
          child: Text(s['displayName']?.toString() ?? 'Unnamed Semester'),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Semester:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: _selectedSemesterId,
          items: items,
          onChanged: (val) {
            setState(() {
              _selectedSemesterId = val; // null => All
            });
            // Re-fetch all item groups with new filter with loading overlay
            _refetchAllItems();
          },
        ),
      ],
    );
  }

  Future<void> _refetchAllItems() async {
    setState(() {
      _isFiltering = true;
    });
    try {
      await Future.wait([
        _fetchClassStandingItems(),
        _fetchQuizPrelimItems(),
        _fetchMidtermExamItems(),
        _fetchPitItems(),
        _fetchFinalClassStandingItems(),
        _fetchFinalQuizItems(),
        _fetchFinalExamItems(),
        _fetchFinalPitItems(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isFiltering = false;
        });
      }
    }
  }

  Future<void> _loadSemesters() async {
    try {
      final snapshot =
          await _firestore
              .collection('semesters')
              .orderBy('createdAt', descending: true)
              .get();

      _semesters =
          snapshot.docs
              .map((d) {
                final data = d.data();
                return {
                  'id': d.id,
                  'displayName': data['displayName'] ?? '',
                  'year': data['year'] ?? '',
                  'semester': data['semester'] ?? '',
                  'isActive': data['isActive'] ?? true,
                };
              })
              .where((s) => (s['displayName'] as String).trim().isNotEmpty)
              .toList();

      setState(() {});
    } catch (e) {
      print('Error loading semesters for filter: $e');
    }
  }

  // Fetch class standing items from database (all item types) - filtered by current section
  Future<void> _fetchClassStandingItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current section code for filtering
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) {
        print(
          '⚠️ No section code available for filtering class standing items',
        );
        return;
      }

      print(
        '🔍 Fetching class standing items for section: $currentSectionCode',
      );
      List<Map<String, dynamic>> items = [];

      // Fetch assignments with category: 'class_standing' AND selectedClasses containing current section
      Query<Map<String, dynamic>> assignmentsQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        assignmentsQuery = assignmentsQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final assignmentsSnap = await assignmentsQuery.get();

      for (var doc in assignmentsSnap.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Add activities
      Query<Map<String, dynamic>> activitiesQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        activitiesQuery = activitiesQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final activitiesSnap = await activitiesQuery.get();

      for (var doc in activitiesSnap.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Add quizzes
      Query<Map<String, dynamic>> quizzesQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        quizzesQuery = quizzesQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final quizzesSnap = await quizzesQuery.get();

      for (var doc in quizzesSnap.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // Add PITs
      Query<Map<String, dynamic>> pitsQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pitsQuery = pitsQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pitsSnap = await pitsQuery.get();

      for (var doc in pitsSnap.docs) {
        items.add({
          'id': doc.id,
          'title': doc.data()['title'],
          'points': doc.data()['points'],
          'type': 'pit',
          'category': doc.data()['category'],
        });
      }

      // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _classStandingItems = items;
      });

      print(
        '✅ Fetched ${_classStandingItems.length} class standing items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _classStandingItems.length; i++) {
        var item = _classStandingItems[i];
        print(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching class standing items: $e');
    }
  }

  // Fetch quiz/prelim items from database (all item types) - filtered by current section
  Future<void> _fetchQuizPrelimItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current section code for filtering
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) {
        print('⚠️ No section code available for filtering quiz/prelim items');
        return;
      }

      print('🔍 Fetching quiz/prelim items for section: $currentSectionCode');
      List<Map<String, dynamic>> items = [];

      // Fetch assignments with category and optional semester filter
      Query<Map<String, dynamic>> assignmentsQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        assignmentsQuery = assignmentsQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final assignmentsSnap = await assignmentsQuery.get();

      for (var doc in assignmentsSnap.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Add activities
      Query<Map<String, dynamic>> activitiesQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        activitiesQuery = activitiesQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final activitiesSnap2 = await activitiesQuery.get();

      for (var doc in activitiesSnap2.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Add quizzes
      Query<Map<String, dynamic>> quizzesQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        quizzesQuery = quizzesQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final quizzesSnap2 = await quizzesQuery.get();

      for (var doc in quizzesSnap2.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // Add PITs
      Query<Map<String, dynamic>> pitsQuery = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pitsQuery = pitsQuery.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pitsSnap2 = await pitsQuery.get();

      for (var doc in pitsSnap2.docs) {
        items.add({
          'id': doc.id,
          'title': doc.data()['title'],
          'points': doc.data()['points'],
          'type': 'pit',
          'category': doc.data()['category'],
        });
      }

      // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _quizPrelimItems = items;
      });

      print(
        '✅ Fetched ${_quizPrelimItems.length} quiz/prelim items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _quizPrelimItems.length; i++) {
        var item = _quizPrelimItems[i];
        print(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching quiz/prelim items: $e');
    }
  }

  // Fetch Final Class Standing items (period == 'Final')
  Future<void> _fetchFinalClassStandingItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) return;

      List<Map<String, dynamic>> items = [];

      // Assignments
      Query<Map<String, dynamic>> aQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ = aQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap = await aQ.get();
      for (var doc in aSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Activities
      Query<Map<String, dynamic>> actQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ = actQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap = await actQ.get();
      for (var doc in actSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Quizzes
      Query<Map<String, dynamic>> qQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ = qQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap = await qQ.get();
      for (var doc in qSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // PITs
      Query<Map<String, dynamic>> pQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'class_standing')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ = pQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap = await pQ.get();
      for (var doc in pSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'pit',
            'category': data['category'],
          });
        }
      }

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalClassStandingItems = items);
    } catch (e) {
      print('❌ Error fetching final class standing items: $e');
    }
  }

  // Fetch Final Quiz/Pre-final items (period == 'Final')
  Future<void> _fetchFinalQuizItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) return;

      List<Map<String, dynamic>> items = [];

      // Assignments
      Query<Map<String, dynamic>> aQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ = aQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap = await aQ.get();
      for (var doc in aSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Activities
      Query<Map<String, dynamic>> actQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ = actQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap = await actQ.get();
      for (var doc in actSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Quizzes
      Query<Map<String, dynamic>> qQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ = qQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap = await qQ.get();
      for (var doc in qSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // PITs
      Query<Map<String, dynamic>> pQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'quiz_prelim')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ = pQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap = await pQ.get();
      for (var doc in pSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'pit',
            'category': data['category'],
          });
        }
      }

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalQuizItems = items);
    } catch (e) {
      print('❌ Error fetching final quiz items: $e');
    }
  }

  // Fetch Final Exam items (we reuse category 'midterm_exam' but period == 'Final')
  Future<void> _fetchFinalExamItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) return;

      List<Map<String, dynamic>> items = [];

      // Assignments
      Query<Map<String, dynamic>> aQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ = aQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap = await aQ.get();
      for (var doc in aSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Activities
      Query<Map<String, dynamic>> actQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ = actQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap = await actQ.get();
      for (var doc in actSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Quizzes
      Query<Map<String, dynamic>> qQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ = qQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap = await qQ.get();
      for (var doc in qSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // PITs
      Query<Map<String, dynamic>> pQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ = pQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap = await pQ.get();
      for (var doc in pSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'pit',
            'category': data['category'],
          });
        }
      }

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalExamItems = items);
    } catch (e) {
      print('❌ Error fetching final exam items: $e');
    }
  }

  // Fetch Final PIT items (period == 'Final')
  Future<void> _fetchFinalPitItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) return;

      List<Map<String, dynamic>> items = [];

      // Assignments
      Query<Map<String, dynamic>> aQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ = aQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap = await aQ.get();
      for (var doc in aSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Activities
      Query<Map<String, dynamic>> actQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ = actQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap = await actQ.get();
      for (var doc in actSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Quizzes
      Query<Map<String, dynamic>> qQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ = qQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap = await qQ.get();
      for (var doc in qSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // PITs
      Query<Map<String, dynamic>> pQ = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ = pQ.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap = await pQ.get();
      for (var doc in pSnap.docs) {
        final data = doc.data();
        if ((data['period'] as String?) == 'Final') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'pit',
            'category': data['category'],
          });
        }
      }

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalPitItems = items);
    } catch (e) {
      print('❌ Error fetching final PIT items: $e');
    }
  }

  // Fetch midterm exam items from database (all item types) - filtered by current section
  Future<void> _fetchMidtermExamItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current section code for filtering
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) {
        print('⚠️ No section code available for filtering midterm exam items');
        return;
      }

      print('🔍 Fetching midterm exam items for section: $currentSectionCode');
      List<Map<String, dynamic>> items = [];

      // Fetch assignments with category: 'midterm_exam' AND selectedClasses containing current section
      Query<Map<String, dynamic>> assignmentsQuery2 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        assignmentsQuery2 = assignmentsQuery2.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final assignmentsSnap2 = await assignmentsQuery2.get();

      for (var doc in assignmentsSnap2.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Add activities
      Query<Map<String, dynamic>> activitiesQuery3 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        activitiesQuery3 = activitiesQuery3.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final activitiesSnap3 = await activitiesQuery3.get();

      for (var doc in activitiesSnap3.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Add quizzes
      Query<Map<String, dynamic>> quizzesQuery3 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        quizzesQuery3 = quizzesQuery3.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final quizzesSnap3 = await quizzesQuery3.get();

      for (var doc in quizzesSnap3.docs) {
        final data = doc.data();
        // Filter by period: only Prelim and Midterm
        final period = data['period'] as String?;
        if (period != null && (period == 'Prelim' || period == 'Midterm')) {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // Add PITs
      Query<Map<String, dynamic>> pitsQuery3 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pitsQuery3 = pitsQuery3.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pitsSnap3 = await pitsQuery3.get();

      for (var doc in pitsSnap3.docs) {
        items.add({
          'id': doc.id,
          'title': doc.data()['title'],
          'points': doc.data()['points'],
          'type': 'pit',
          'category': doc.data()['category'],
        });
      }

      // Sort items by title to ensure proper order
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _midtermExamItems = items;
      });

      print(
        '✅ Fetched ${_midtermExamItems.length} midterm exam items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _midtermExamItems.length; i++) {
        var item = _midtermExamItems[i];
        print(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching midterm exam items: $e');
    }
  }

  // Fetch PIT items from database (all item types) - filtered by current section
  Future<void> _fetchPitItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current section code for filtering
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) {
        print('⚠️ No section code available for filtering PIT items');
        return;
      }

      print('🔍 Fetching PIT items for section: $currentSectionCode');
      List<Map<String, dynamic>> items = [];

      // Fetch assignments with category: 'pit' and optional semester filter
      Query<Map<String, dynamic>> assignmentsQuery4 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        assignmentsQuery4 = assignmentsQuery4.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final assignmentsSnap4 = await assignmentsQuery4.get();

      for (var doc in assignmentsSnap4.docs) {
        final data = doc.data();
        // Filter by period: only Midterm (PITs can have Midterm or Final, but for midterm grades we only want Midterm)
        final period = data['period'] as String?;
        if (period != null && period == 'Midterm') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'assignment',
            'category': data['category'],
          });
        }
      }

      // Add activities
      Query<Map<String, dynamic>> activitiesQuery4 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        activitiesQuery4 = activitiesQuery4.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final activitiesSnap4 = await activitiesQuery4.get();

      for (var doc in activitiesSnap4.docs) {
        final data = doc.data();
        // Filter by period: only Midterm (PITs can have Midterm or Final, but for midterm grades we only want Midterm)
        final period = data['period'] as String?;
        if (period != null && period == 'Midterm') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'activity',
            'category': data['category'],
          });
        }
      }

      // Add quizzes
      Query<Map<String, dynamic>> quizzesQuery4 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        quizzesQuery4 = quizzesQuery4.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final quizzesSnap4 = await quizzesQuery4.get();

      for (var doc in quizzesSnap4.docs) {
        final data = doc.data();
        // Filter by period: only Midterm (PITs can have Midterm or Final, but for midterm grades we only want Midterm)
        final period = data['period'] as String?;
        if (period != null && period == 'Midterm') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'quiz',
            'category': data['category'],
          });
        }
      }

      // Add PITs
      Query<Map<String, dynamic>> pitsQuery4 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'pit')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pitsQuery4 = pitsQuery4.where(
          'assignedSemester.semesterId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pitsSnap4 = await pitsQuery4.get();

      for (var doc in pitsSnap4.docs) {
        final data = doc.data();
        // Filter by period: only Midterm (PITs can have Midterm or Final, but for midterm grades we only want Midterm)
        final period = data['period'] as String?;
        if (period != null && period == 'Midterm') {
          items.add({
            'id': doc.id,
            'title': data['title'],
            'points': data['points'],
            'type': 'pit',
            'category': data['category'],
          });
        }
      }

      // Sort items by title to ensure proper order
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _pitItems = items;
      });

      print(
        '✅ Fetched ${_pitItems.length} PIT items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _pitItems.length; i++) {
        var item = _pitItems[i];
        print(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching PIT items: $e');
    }
  }

  /// Refresh all data (students and assignment items)
  Future<void> _refreshData() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
          ),
        ),
        barrierDismissible: false,
      );

      // Refresh all data
      await Future.wait([
        _classReportController.refreshStudents(),
        _fetchClassStandingItems(),
        _fetchQuizPrelimItems(),
        _fetchMidtermExamItems(),
        _fetchPitItems(),
        _fetchFinalClassStandingItems(),
        _fetchFinalQuizItems(),
        _fetchFinalExamItems(),
        _fetchFinalPitItems(),
      ]);

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Success',
        'Data refreshed successfully',
        backgroundColor: const Color(0xFF34A853),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to refresh data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Export class report data
  Future<void> _exportData() async {
    try {
      // Snapshot current data
      final students = _classReportController.students.toList();
      final sectionName = _classReportController.sectionName.value;
      final courseName = _classReportController.courseName.value;
      final instructorName = _classReportController.instructorName.value;
      final departmentName = _classReportController.departmentName.value;

      // Invoke export (ExportService handles success/error messages)
      await ExportService().exportCompleteClassRecord(
        students: students,
        classStandingItems: _classStandingItems,
        quizPrelimItems: _quizPrelimItems,
        midtermExamItems: _midtermExamItems,
        pitItems: _pitItems,
        finalClassStandingItems: _finalClassStandingItems,
        finalQuizItems: _finalQuizItems,
        finalExamItems: _finalExamItems,
        finalPitItems: _finalPitItems,
        sectionName: sectionName,
        courseName: courseName,
        instructorName: instructorName,
        departmentName:
            departmentName.isNotEmpty
                ? departmentName
                : 'Department of NATIONAL SERVICE TRAINING PROGRAM',
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Export Failed',
        'Failed to export data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          InstructorSidebar(
            selectedItem: _selectedItem,
            onItemSelected: (item) {
              setState(() {
                _selectedItem = item;
              });
              String route = InstructorNavigationHelper.getRoute(item);
              Navigator.of(context).pushReplacementNamed(route);
            },
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Obx(
                  () => InstructorAppBar(
                    instructorName: _classReportController.instructorName.value,
                    instructorRole: 'Instructor',
                    profileImageUrl:
                        _classReportController.profileImageUrl.value,
                  ),
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Class Report',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Responsive button row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // If screen is too narrow, stack buttons vertically
                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Refresh Button
                                      ElevatedButton.icon(
                                        onPressed: _refreshData,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 18,
                                        ),
                                        label: const Text('Refresh'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF34A853,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Export Button
                                      ElevatedButton.icon(
                                        onPressed: _exportData,
                                        icon: const Icon(
                                          Icons.download,
                                          size: 18,
                                        ),
                                        label: const Text('Export'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF22C55E,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // Default horizontal layout
                                return Row(
                                  children: [
                                    // Refresh Button
                                    ElevatedButton.icon(
                                      onPressed: _refreshData,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Refresh'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF34A853,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Export Button
                                    ElevatedButton.icon(
                                      onPressed: _exportData,
                                      icon: const Icon(
                                        Icons.download,
                                        size: 18,
                                      ),
                                      label: const Text('Export'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF22C55E,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Semester Filter
                        _buildSemesterFilter(),
                        const SizedBox(height: 16),
                        // Table with Pull-to-Refresh + filtering overlay
                        Expanded(
                          child: Stack(
                            children: [
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: const Color(0xFF34A853),
                                child: Obx(() {
                                  if (_classReportController
                                      .isLoadingStudents
                                      .value) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF34A853),
                                            ),
                                      ),
                                    );
                                  }

                                  if (_classReportController
                                      .errorMessage
                                      .value
                                      .isNotEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 64,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error: ${_classReportController.errorMessage.value}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.red[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF34A853,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Use StreamBuilder for real-time updates
                                  return StreamBuilder<
                                    List<Map<String, dynamic>>
                                  >(
                                    stream:
                                        _classReportController
                                            .createRealTimeStudentsStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          !snapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                size: 48,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(height: 16),
                                              Text('Error: ${snapshot.error}'),
                                            ],
                                          ),
                                        );
                                      }

                                      final studentScores = snapshot.data ?? [];
                                      return _buildDynamicClassStandingTable(
                                        studentScores,
                                      );
                                    },
                                  );
                                }),
                              ),
                              if (_isFiltering)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.5),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF34A853),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
