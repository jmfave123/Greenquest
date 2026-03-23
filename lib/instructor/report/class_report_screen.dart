import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/instructor/instructor_appbar.dart';
import '../../shared/instructor/instructor_sidebar.dart';
import '../../shared/instructor/instructor_navigation_constants.dart';
import '../../shared/class_record/class_record_table.dart';
import '../../shared/widgets/skeleton_loading.dart';
import 'class_report_controller.dart';
import '../../shared/services/export_service.dart';
import '../../shared/widgets/excel_export_preview_dialog.dart';
import '../../shared/widgets/excel_preview_table.dart';

class ClassReportScreen extends StatefulWidget {
  const ClassReportScreen({super.key});

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  late ClassReportController _classReportController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

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
    _loadSemesters().then((_) {
      // After loading semesters, fetch items with the selected semester filter
      _fetchClassStandingItems();
      _fetchQuizPrelimItems();
      _fetchMidtermExamItems();
      _fetchPitItems();
      // Finals
      _fetchFinalClassStandingItems();
      _fetchFinalQuizItems();
      _fetchFinalExamItems();
      _fetchFinalPitItems();
    });
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
    _log('🔍 Building Syncfusion DataGrid with ${scores.length} students');
    _log('🔍 Class standing items: ${_classStandingItems.length}');
    _log('🔍 Quiz/prelim items: ${_quizPrelimItems.length}');
    _log('🔍 Midterm exam items: ${_midtermExamItems.length}');
    _log('🔍 PIT items: ${_pitItems.length}');

    // Always show the table structure, even if empty
    // The table will display with empty student rows if no students exist
    // and will show column structure even if no items are created yet
    return ClassRecordTable(
      students: scores, // Will be empty list if no students exist
      classStandingItems: _classStandingItems,
      quizPrelimItems: _quizPrelimItems,
      midtermExamItems: _midtermExamItems,
      pitItems: _pitItems,
      finalClassStandingItems: _finalClassStandingItems,
      finalQuizItems: _finalQuizItems,
      finalExamItems: _finalExamItems,
      finalPitItems: _finalPitItems,
      onCellValueChanged: (student, itemKey, value) {
        // Handle cell editing if needed in the future
        _log(
          'Cell value changed: $itemKey = $value for student ${student['name']}',
        );
      },
    );
  }

  // Build semester filter dropdown
  Widget _buildSemesterFilter() {
    // Only show assigned semesters (no "All" option)
    final List<DropdownMenuItem<String?>> items =
        _semesters
            .map(
              (s) => DropdownMenuItem<String?>(
                value: s['id'] as String,
                child: Text(s['displayName']?.toString() ?? 'Unnamed Semester'),
              ),
            )
            .toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

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
              _selectedSemesterId = val;
            });
            // Re-fetch all item groups with new filter
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
      final user = _auth.currentUser;
      if (user == null) return;

      // Get instructor's assigned periods from their document
      final instructorDoc =
          await _firestore.collection('instructors').doc(user.uid).get();

      if (!instructorDoc.exists) {
        debugPrint('⚠️ Instructor document not found');
        return;
      }

      final instructorData = instructorDoc.data();
      final assignedPeriods =
          (instructorData?['assignedPeriods'] as List<dynamic>?) ?? [];

      if (assignedPeriods.isEmpty) {
        debugPrint('⚠️ No assigned periods found for instructor');
        _semesters = [];
        setState(() {});
        return;
      }

      // Map each period to a display entry
      _semesters =
          assignedPeriods
              .map((p) {
                final periodData = p as Map<String, dynamic>;
                final semesterName =
                    periodData['semesterName'] as String? ?? '';
                final type = periodData['type'] as String? ?? '';
                final isActive = periodData['isActive'] as bool? ?? false;
                return {
                  'id': periodData['periodId'] as String? ?? '',
                  'displayName':
                      type.isNotEmpty
                          ? '$semesterName — $type${isActive ? ' (Active)' : ''}'
                          : semesterName,
                  'isActive': isActive,
                };
              })
              .where((s) => (s['id'] as String).isNotEmpty)
              .toList();

      // Auto-select the currently active period by default
      if (_semesters.isNotEmpty && _selectedSemesterId == null) {
        final activePeriod = _semesters.firstWhere(
          (s) => s['isActive'] == true,
          orElse: () => _semesters.first,
        );
        _selectedSemesterId = activePeriod['id'] as String;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading periods for filter: $e');
    }
  }

  /// Helper method to fetch items that don't have a semester assigned
  /// This ensures items are displayed even if they don't have a semester assigned
  /// Includes both graded and ungraded items
  Future<List<Map<String, dynamic>>> _fetchItemsWithoutSemester({
    required String sectionCode,
    required String category,
    required List<String> periods,
    required List<String>
    itemTypes, // ['assignment', 'activity', 'quiz', 'pit']
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      _log(
        '🔍 Fetching items without semester for section: $sectionCode, category: $category',
      );

      List<Map<String, dynamic>> items = [];

      // Fetch items from each collection type
      for (String itemType in itemTypes) {
        String collectionName = '';
        switch (itemType) {
          case 'assignment':
            collectionName = 'assignments';
            break;
          case 'activity':
            collectionName = 'activities';
            break;
          case 'quiz':
            collectionName = 'quizzes';
            break;
          case 'pit':
            collectionName = 'pits';
            break;
          default:
            continue;
        }

        try {
          // Query items without assignedSemester or with null assignedSemester
          // Firestore doesn't support "where field is null" directly, so we need to:
          // 1. Query all items for the category and section
          // 2. Filter out items that have assignedSemester.periodId matching selected period
          Query<Map<String, dynamic>> query = _firestore
              .collection('instructors')
              .doc(user.uid)
              .collection(collectionName)
              .where('category', isEqualTo: category)
              .where('selectedClasses', arrayContains: sectionCode);

          final snapshot = await query.get();

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final assignedSemester =
                data['assignedSemester'] as Map<String, dynamic>?;
            final periodId = assignedSemester?['periodId'] as String?;
            final itemPeriod = data['period'] as String?;

            // Include items that don't have a period assigned (null or empty)
            // AND match the period filter (if specified)
            if ((periodId == null || periodId.isEmpty) &&
                (periods.isEmpty ||
                    (itemPeriod != null && periods.contains(itemPeriod)))) {
              items.add({
                'id': doc.id,
                'title': data['title'] ?? '',
                'points': data['points'] ?? 0,
                'type': itemType,
                'category': category,
              });
            }
          }
        } catch (e) {
          _log('  ⚠️ Error fetching $itemType items: $e');
        }
      }

      _log(
        '✅ Found ${items.length} items without semester for category $category',
      );
      return items;
    } catch (e) {
      _log('❌ Error fetching items without semester: $e');
      return [];
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
        _log('⚠️ No section code available for filtering class standing items');
        return;
      }

      _log('🔍 Fetching class standing items for section: $currentSectionCode');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'class_standing',
        periods: ['Prelim', 'Midterm'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _classStandingItems = items;
      });

      _log(
        '✅ Fetched ${_classStandingItems.length} class standing items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _classStandingItems.length; i++) {
        var item = _classStandingItems[i];
        _log(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching class standing items: $e');
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
        _log('⚠️ No section code available for filtering quiz/prelim items');
        return;
      }

      _log('🔍 Fetching quiz/prelim items for section: $currentSectionCode');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'quiz_prelim',
        periods: ['Prelim', 'Midterm'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      // Sort items by title to ensure proper order (Quiz 1, Quiz 2, etc.)
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _quizPrelimItems = items;
      });

      _log(
        '✅ Fetched ${_quizPrelimItems.length} quiz/prelim items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _quizPrelimItems.length; i++) {
        var item = _quizPrelimItems[i];
        _log(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching quiz/prelim items: $e');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'class_standing',
        periods: ['Final'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalClassStandingItems = items);
    } catch (e) {
      _log('❌ Error fetching final class standing items: $e');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'quiz_prelim',
        periods: ['Final'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalQuizItems = items);
    } catch (e) {
      _log('❌ Error fetching final quiz items: $e');
    }
  }

  // Fetch Final Exam items (category 'final_exam' OR category 'midterm_exam' with period 'Final')
  Future<void> _fetchFinalExamItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final currentSectionCode = _classReportController.sectionName.value;
      if (currentSectionCode.isEmpty) return;

      List<Map<String, dynamic>> items = [];

      // Assignments - Query for final_exam category
      Query<Map<String, dynamic>> aQ1 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'final_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ1 = aQ1.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap1 = await aQ1.get();
      for (var doc in aSnap1.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'title': data['title'],
          'points': data['points'],
          'type': 'assignment',
          'category': data['category'],
        });
      }

      // Assignments - Query for midterm_exam category with Final period (backward compatibility)
      Query<Map<String, dynamic>> aQ2 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('assignments')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        aQ2 = aQ2.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final aSnap2 = await aQ2.get();
      for (var doc in aSnap2.docs) {
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

      // Activities - Query for final_exam category
      Query<Map<String, dynamic>> actQ1 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'final_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ1 = actQ1.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap1 = await actQ1.get();
      for (var doc in actSnap1.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'title': data['title'],
          'points': data['points'],
          'type': 'activity',
          'category': data['category'],
        });
      }

      // Activities - Query for midterm_exam category with Final period (backward compatibility)
      Query<Map<String, dynamic>> actQ2 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('activities')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        actQ2 = actQ2.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final actSnap2 = await actQ2.get();
      for (var doc in actSnap2.docs) {
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

      // Quizzes - Query for final_exam category
      Query<Map<String, dynamic>> qQ1 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'final_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ1 = qQ1.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap1 = await qQ1.get();
      for (var doc in qSnap1.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'title': data['title'],
          'points': data['points'],
          'type': 'quiz',
          'category': data['category'],
        });
      }

      // Quizzes - Query for midterm_exam category with Final period (backward compatibility)
      Query<Map<String, dynamic>> qQ2 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('quizzes')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        qQ2 = qQ2.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final qSnap2 = await qQ2.get();
      for (var doc in qSnap2.docs) {
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

      // PITs - Query for final_exam category
      Query<Map<String, dynamic>> pQ1 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'final_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ1 = pQ1.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap1 = await pQ1.get();
      for (var doc in pSnap1.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'title': data['title'],
          'points': data['points'],
          'type': 'pit',
          'category': data['category'],
        });
      }

      // PITs - Query for midterm_exam category with Final period (backward compatibility)
      Query<Map<String, dynamic>> pQ2 = _firestore
          .collection('instructors')
          .doc(user.uid)
          .collection('pits')
          .where('category', isEqualTo: 'midterm_exam')
          .where('selectedClasses', arrayContains: currentSectionCode);
      if (_selectedSemesterId != null) {
        pQ2 = pQ2.where(
          'assignedSemester.periodId',
          isEqualTo: _selectedSemesterId,
        );
      }
      final pSnap2 = await pQ2.get();
      for (var doc in pSnap2.docs) {
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      // Fetch for both final_exam category and midterm_exam with Final period
      final itemsWithoutSemesterFinalExam = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'final_exam',
        periods: [], // final_exam doesn't use periods
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      final itemsWithoutSemesterMidtermFinal = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'midterm_exam',
        periods: ['Final'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester from final_exam category
      for (var item in itemsWithoutSemesterFinalExam) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester from midterm_exam with Final period
      for (var item in itemsWithoutSemesterMidtermFinal) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalExamItems = items);
    } catch (e) {
      _log('❌ Error fetching final exam items: $e');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'pit',
        periods: ['Final'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      items.sort((a, b) => a['title'].compareTo(b['title']));
      setState(() => _finalPitItems = items);
    } catch (e) {
      _log('❌ Error fetching final PIT items: $e');
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
        _log('⚠️ No section code available for filtering midterm exam items');
        return;
      }

      _log('🔍 Fetching midterm exam items for section: $currentSectionCode');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'midterm_exam',
        periods: ['Prelim', 'Midterm'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      // Sort items by title to ensure proper order
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _midtermExamItems = items;
      });

      _log(
        '✅ Fetched ${_midtermExamItems.length} midterm exam items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _midtermExamItems.length; i++) {
        var item = _midtermExamItems[i];
        _log(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching midterm exam items: $e');
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
        _log('⚠️ No section code available for filtering PIT items');
        return;
      }

      _log('🔍 Fetching PIT items for section: $currentSectionCode');
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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
          'assignedSemester.periodId',
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

      // Also fetch items without semester assigned (includes both graded and ungraded)
      // This ensures all items are displayed even if they don't have a semester assigned
      final itemsWithoutSemester = await _fetchItemsWithoutSemester(
        sectionCode: currentSectionCode,
        category: 'pit',
        periods: ['Midterm'],
        itemTypes: ['assignment', 'activity', 'quiz', 'pit'],
      );

      // Merge items: use a Map to track by ID to avoid duplicates
      Map<String, Map<String, dynamic>> itemsMap = {};

      // Add items from semester filter first
      for (var item in items) {
        itemsMap[item['id'] as String] = item;
      }

      // Add items without semester (includes both graded and ungraded)
      for (var item in itemsWithoutSemester) {
        itemsMap[item['id'] as String] = item;
      }

      // Convert back to list
      items = itemsMap.values.toList();

      // Sort items by title to ensure proper order
      items.sort((a, b) => a['title'].compareTo(b['title']));

      setState(() {
        _pitItems = items;
      });

      _log(
        '✅ Fetched ${_pitItems.length} PIT items (all types) for section $currentSectionCode',
      );
      for (int i = 0; i < _pitItems.length; i++) {
        var item = _pitItems[i];
        _log(
          '  ${i + 1}. ${item['title']} (${item['type']}) - ID: ${item['id']}',
        );
      }
    } catch (e) {
      _log('❌ Error fetching PIT items: $e');
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

  /// Export class report data with preview
  Future<void> _exportData() async {
    try {
      // Snapshot current data
      final students = _classReportController.students.toList();
      final sectionName = _classReportController.sectionName.value;
      final courseName = _classReportController.courseName.value;
      final instructorName = _classReportController.instructorName.value;
      final departmentName = _classReportController.departmentName.value;

      // Generate preview data matching actual Excel structure
      final exportService = ExportService();
      final previewResult = exportService.generateExcelPreviewData(
        students: students,
        classStandingItems: _classStandingItems,
        quizPrelimItems: _quizPrelimItems,
        midtermExamItems: _midtermExamItems,
        pitItems: _pitItems,
        finalClassStandingItems: _finalClassStandingItems,
        finalQuizItems: _finalQuizItems,
        finalExamItems: _finalExamItems,
        finalPitItems: _finalPitItems,
        previewRowCount: 10,
      );

      final previewData =
          previewResult['previewData'] as List<Map<String, dynamic>>;
      final columnHeaders = previewResult['columnHeaders'] as List<String>;

      // Get export summary
      final summary = exportService.getExportSummary(
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
      );

      // Generate filename
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final fileName = '${sectionName}_ClassRecord_$timestamp.xlsx';

      // Build summary text
      final summaryText =
          '${summary['studentCount']} students • ${summary['totalColumns']} columns • $sectionName';

      // Show preview dialog
      final shouldExport = await ExcelExportPreviewDialog.show(
        context: context,
        title: 'Class Record Export',
        fileName: fileName,
        summaryText: summaryText,
        previewContent: ExcelPreviewTable(
          previewData: previewData,
          columnHeaders: columnHeaders,
        ),
        exportOptions: const [],
        onExport: () {},
      );

      // If user cancelled, do nothing
      if (shouldExport != true) {
        return;
      }

      // Perform actual export outside dialog so exceptions are caught
      await exportService.exportCompleteClassRecord(
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

      // Show success message
      Get.snackbar(
        'Export Successful',
        'Class record exported successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate available height for the table
                        // Account for: header, buttons, semester filter, and padding
                        const double headerHeight =
                            60; // Approximate header height
                        const double buttonsHeight =
                            60; // Approximate buttons height
                        const double filterHeight =
                            50; // Approximate filter height
                        const double spacingHeight =
                            16 + 16; // SizedBox heights
                        final double availableHeight =
                            constraints.maxHeight -
                            headerHeight -
                            buttonsHeight -
                            filterHeight -
                            spacingHeight;

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    builder: (context, buttonConstraints) {
                                      // If screen is too narrow, stack buttons vertically
                                      if (buttonConstraints.maxWidth < 600) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                              // Table with fixed height - scrollable independently
                              SizedBox(
                                height:
                                    availableHeight > 400
                                        ? availableHeight
                                        : 400, // Minimum height of 400
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
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SkeletonListItem(),
                                                SizedBox(height: 12),
                                                SkeletonListItem(),
                                                SizedBox(height: 12),
                                                SkeletonListItem(),
                                              ],
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF34A853,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
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
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SkeletonListItem(),
                                                    SizedBox(height: 12),
                                                    SkeletonListItem(),
                                                    SizedBox(height: 12),
                                                    SkeletonListItem(),
                                                  ],
                                                ),
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
                                                    Text(
                                                      'Error: ${snapshot.error}',
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            final studentScores =
                                                snapshot.data ?? [];
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
                        );
                      },
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
