import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Category completion data structure
class CategoryCompletion {
  final String category;
  final String displayName;
  final int completed;
  final int total;
  final double percentage;
  final String period; // 'midterm' or 'final'

  CategoryCompletion({
    required this.category,
    required this.displayName,
    required this.completed,
    required this.total,
    required this.percentage,
    required this.period,
  });
}

/// Progress result with completion data
class ProgressResult {
  final double progress;
  final double
  computedFinalGrade; // The computed final grade value (e.g., 4.88)
  final List<CategoryCompletion> midtermCompletions;
  final List<CategoryCompletion> finalCompletions;
  final String? activePeriodName; // Name of active period
  final String? activePeriodType; // Type: 'Midterm' or 'Final'

  ProgressResult({
    required this.progress,
    required this.computedFinalGrade,
    required this.midtermCompletions,
    required this.finalCompletions,
    this.activePeriodName,
    this.activePeriodType,
  });
}

/// Service to calculate tree progress based on class record grades
/// Follows the same logic as class_record_table.dart for consistency
class TreeProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculate tree progress for current user
  /// Returns progress as double (0.0 to 1.0)
  Future<double> calculateProgress() async {
    final result = await calculateProgressWithCompletion();
    return result.progress;
  }

  /// Get real-time stream of progress updates
  /// Listens to submission collections and recalculates on any change
  Stream<ProgressResult> progressStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(
          ProgressResult(
            progress: 0.0,
            computedFinalGrade: 5.00,
            midtermCompletions: [],
            finalCompletions: [],
            activePeriodName: null,
            activePeriodType: null,
          ),
        );
      }

      // Stream that combines user document and all submission collections
      return _createProgressStream(user.uid);
    });
  }

  /// Fetch active period from Firebase
  Future<Map<String, dynamic>?> _getActivePeriod() async {
    try {
      final snapshot =
          await _firestore
              .collection('periods')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
    } catch (e) {
      print('Error getting active period: $e');
      return null;
    }
  }

  /// Create progress stream by combining multiple Firestore streams
  Stream<ProgressResult> _createProgressStream(String userId) {
    // Get user context stream
    final userStream = _firestore.collection('users').doc(userId).snapshots();

    return userStream.asyncExpand((userDoc) {
      if (!userDoc.exists) {
        return Stream.value(
          ProgressResult(
            progress: 0.0,
            computedFinalGrade: 5.00,
            midtermCompletions: [],
            finalCompletions: [],
            activePeriodName: null,
            activePeriodType: null,
          ),
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final instructorId = userData['selectedInstructorId'] as String?;
      final sectionCode = userData['selectedSectionCode'] as String?;
      final enrollmentStatus = userData['enrollmentStatus'] as String?;

      if (enrollmentStatus != 'approved' ||
          instructorId == null ||
          sectionCode == null ||
          instructorId.isEmpty ||
          sectionCode.isEmpty) {
        return Stream.value(
          ProgressResult(
            progress: 0.0,
            computedFinalGrade: 5.00,
            midtermCompletions: [],
            finalCompletions: [],
            activePeriodName: null,
            activePeriodType: null,
          ),
        );
      }

      // Create unified stream for all submission types
      final allSubmissionsStream =
          _firestore
              .collection('submissions')
              .where('studentId', isEqualTo: userId)
              .where('instructorId', isEqualTo: instructorId)
              .where('sectionName', isEqualTo: sectionCode)
              .snapshots();

      // Combine all streams using StreamController
      final controller = StreamController<ProgressResult>();
      StreamSubscription? allSubmissionsSub;

      // Emit initial value
      _calculateProgressForContext(userId, instructorId, sectionCode)
          .then((result) => controller.add(result))
          .catchError((e) => print('Error calculating initial progress: $e'));

      // Listen to unified submissions stream
      allSubmissionsSub = allSubmissionsStream.listen(
        (_) =>
            _recalculateProgress(controller, userId, instructorId, sectionCode),
        onError: (e) => print('Submissions stream error: $e'),
      );

      // Clean up subscriptions when stream is cancelled
      controller.onCancel = () {
        allSubmissionsSub?.cancel();
      };

      return controller.stream.distinct((prev, next) {
        // Only emit if progress or completion data actually changed
        if ((prev.progress - next.progress).abs() > 0.001) return false;
        if (prev.midtermCompletions.length != next.midtermCompletions.length) {
          return false;
        }
        if (prev.finalCompletions.length != next.finalCompletions.length) {
          return false;
        }
        // Check if completion counts changed
        for (var i = 0; i < prev.midtermCompletions.length; i++) {
          if (prev.midtermCompletions[i].completed !=
                  next.midtermCompletions[i].completed ||
              prev.midtermCompletions[i].total !=
                  next.midtermCompletions[i].total) {
            return false;
          }
        }
        for (var i = 0; i < prev.finalCompletions.length; i++) {
          if (prev.finalCompletions[i].completed !=
                  next.finalCompletions[i].completed ||
              prev.finalCompletions[i].total !=
                  next.finalCompletions[i].total) {
            return false;
          }
        }
        return true; // Same data, don't emit
      });
    });
  }

  Future<void> _recalculateProgress(
    StreamController<ProgressResult> controller,
    String userId,
    String instructorId,
    String sectionCode,
  ) async {
    try {
      final result = await _calculateProgressForContext(
        userId,
        instructorId,
        sectionCode,
      );
      if (!controller.isClosed) {
        controller.add(result);
      }
    } catch (e) {
      print('❌ Error recalculating progress: $e');
    }
  }

  Future<ProgressResult> _calculateProgressForContext(
    String userId,
    String instructorId,
    String sectionCode,
  ) async {
    try {
      String? semesterId;

      // Get active period
      final activePeriod = await _getActivePeriod();
      final activePeriodType =
          activePeriod?['type'] as String?; // 'Midterm' or 'Final'
      final activePeriodName = activePeriod?['semesterName'] as String?;

      // Fetch all items grouped by category and period
      final itemsData = await _fetchAllItems(
        instructorId,
        sectionCode,
        semesterId,
      );

      // Fetch student's submissions with grades
      final studentGrades = await _fetchStudentGrades(
        userId,
        instructorId,
        sectionCode,
      );

      // Calculate completion data for each category
      final midtermCompletions = _calculateCategoryCompletions(
        itemsData,
        studentGrades,
        isMidterm: true,
      );
      final finalCompletions = _calculateCategoryCompletions(
        itemsData,
        studentGrades,
        isMidterm: false,
      );

      // Calculate progress based on active period
      final result = _calculateProgressFromItems(
        itemsData,
        studentGrades,
        activePeriodType: activePeriodType,
      );

      return ProgressResult(
        progress: result['progress'] as double,
        computedFinalGrade: result['computedFinalGrade'] as double,
        midtermCompletions: midtermCompletions,
        finalCompletions: finalCompletions,
        activePeriodName: activePeriodName,
        activePeriodType: activePeriodType,
      );
    } catch (e) {
      print('❌ Error calculating tree progress: $e');
      return ProgressResult(
        progress: 0.0,
        computedFinalGrade: 5.00,
        midtermCompletions: [],
        finalCompletions: [],
        activePeriodName: null,
        activePeriodType: null,
      );
    }
  }

  /// Calculate progress with category completion data
  Future<ProgressResult> calculateProgressWithCompletion() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ProgressResult(
          progress: 0.0,
          computedFinalGrade: 5.00,
          midtermCompletions: [],
          finalCompletions: [],
          activePeriodName: null,
          activePeriodType: null,
        );
      }

      // Get user context
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return ProgressResult(
          progress: 0.0,
          computedFinalGrade: 5.00,
          midtermCompletions: [],
          finalCompletions: [],
          activePeriodName: null,
          activePeriodType: null,
        );
      }

      final userData = userDoc.data()!;
      final instructorId = userData['selectedInstructorId'] as String?;
      final sectionCode = userData['selectedSectionCode'] as String?;
      final enrollmentStatus = userData['enrollmentStatus'] as String?;

      // Check if user is approved
      if (enrollmentStatus != 'approved' ||
          instructorId == null ||
          sectionCode == null ||
          instructorId.isEmpty ||
          sectionCode.isEmpty) {
        return ProgressResult(
          progress: 0.0,
          computedFinalGrade: 5.00,
          midtermCompletions: [],
          finalCompletions: [],
          activePeriodName: null,
          activePeriodType: null,
        );
      }

      // Get active period
      final activePeriod = await _getActivePeriod();
      final activePeriodType =
          activePeriod?['type'] as String?; // 'Midterm' or 'Final'
      final activePeriodName = activePeriod?['semesterName'] as String?;

      // Get current semester (you may need to fetch from semester settings)
      // For now, we'll fetch items without semester filter
      String? semesterId;

      // Fetch all items grouped by category and period (same as class record)
      final itemsData = await _fetchAllItems(
        instructorId,
        sectionCode,
        semesterId,
      );

      // Fetch student's submissions with grades
      final studentGrades = await _fetchStudentGrades(
        user.uid,
        instructorId,
        sectionCode,
      );

      // Calculate completion data for each category
      final midtermCompletions = _calculateCategoryCompletions(
        itemsData,
        studentGrades,
        isMidterm: true,
      );
      final finalCompletions = _calculateCategoryCompletions(
        itemsData,
        studentGrades,
        isMidterm: false,
      );

      // Calculate progress and computed final grade based on active period
      final result = _calculateProgressFromItems(
        itemsData,
        studentGrades,
        activePeriodType: activePeriodType,
      );

      return ProgressResult(
        progress: result['progress'] as double,
        computedFinalGrade: result['computedFinalGrade'] as double,
        midtermCompletions: midtermCompletions,
        finalCompletions: finalCompletions,
        activePeriodName: activePeriodName,
        activePeriodType: activePeriodType,
      );
    } catch (e) {
      print('❌ Error calculating tree progress: $e');
      return ProgressResult(
        progress: 0.0,
        computedFinalGrade: 5.00,
        midtermCompletions: [],
        finalCompletions: [],
        activePeriodName: null,
        activePeriodType: null,
      );
    }
  }

  /// Fetch all items grouped by category and period
  Future<Map<String, dynamic>> _fetchAllItems(
    String instructorId,
    String sectionCode,
    String? semesterId,
  ) async {
    final items = {
      // Midterm period
      'classStandingItems': <Map<String, dynamic>>[],
      'quizPrelimItems': <Map<String, dynamic>>[],
      'midtermExamItems': <Map<String, dynamic>>[],
      'pitItems': <Map<String, dynamic>>[],
      // Final period
      'finalClassStandingItems': <Map<String, dynamic>>[],
      'finalQuizItems': <Map<String, dynamic>>[],
      'finalExamItems': <Map<String, dynamic>>[],
      'finalPitItems': <Map<String, dynamic>>[],
    };

    try {
      // Fetch Class Standing items (midterm period: Prelim or Midterm)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'class_standing',
        ['Prelim', 'Midterm'],
        items['classStandingItems']!,
      );

      // Fetch Quiz/Prelim items (midterm period)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'quiz_prelim',
        ['Prelim', 'Midterm'],
        items['quizPrelimItems']!,
      );

      // Fetch Midterm Exam items (midterm period)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'midterm_exam',
        ['Prelim', 'Midterm'],
        items['midtermExamItems']!,
      );

      // Fetch PIT items (midterm period)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'pit',
        ['Prelim', 'Midterm'],
        items['pitItems']!,
      );

      // Fetch Final Class Standing items (period: Final)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'class_standing',
        ['Final'],
        items['finalClassStandingItems']!,
      );

      // Fetch Final Quiz items (period: Final)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'quiz_prelim',
        ['Final'],
        items['finalQuizItems']!,
      );

      // Fetch Final Exam items - Query for final_exam category (always Final period)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'final_exam',
        ['Final'], // final_exam category items are always Final period
        items['finalExamItems']!,
      );

      // Fetch Final Exam items - Query for midterm_exam category with Final period (backward compatibility)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'midterm_exam',
        ['Final'],
        items['finalExamItems']!,
      );

      // Fetch Final PIT items (period: Final)
      await _fetchItemsByCategory(
        instructorId,
        sectionCode,
        semesterId,
        'pit',
        ['Final'],
        items['finalPitItems']!,
      );
    } catch (e) {
      print('❌ Error fetching items: $e');
    }

    return items;
  }

  /// Fetch items by category from all item types (assignments, activities, quizzes, pits)
  Future<void> _fetchItemsByCategory(
    String instructorId,
    String sectionCode,
    String? semesterId,
    String category,
    List<String> periods,
    List<Map<String, dynamic>> itemsList,
  ) async {
    // Fetch from assignments
    await _fetchItemsFromCollection(
      instructorId,
      sectionCode,
      semesterId,
      category,
      periods,
      'assignments',
      itemsList,
    );

    // Fetch from activities
    await _fetchItemsFromCollection(
      instructorId,
      sectionCode,
      semesterId,
      category,
      periods,
      'activities',
      itemsList,
    );

    // Fetch from quizzes
    await _fetchItemsFromCollection(
      instructorId,
      sectionCode,
      semesterId,
      category,
      periods,
      'quizzes',
      itemsList,
    );

    // Fetch from pits
    await _fetchItemsFromCollection(
      instructorId,
      sectionCode,
      semesterId,
      category,
      periods,
      'pits',
      itemsList,
    );
  }

  /// Fetch items from a specific collection
  Future<void> _fetchItemsFromCollection(
    String instructorId,
    String sectionCode,
    String? semesterId,
    String category,
    List<String> periods,
    String collection,
    List<Map<String, dynamic>> itemsList,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('instructors')
          .doc(instructorId)
          .collection(collection)
          .where('category', isEqualTo: category)
          .where('selectedClasses', arrayContains: sectionCode);

      // Add semester filter if provided
      if (semesterId != null) {
        query = query.where(
          'assignedSemester.semesterId',
          isEqualTo: semesterId,
        );
      }

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // Only include items with status='active' (uploaded items, not templates/predicted)
        final status = data['status'] as String?;
        if (status != 'active') continue;

        final period = data['period'] as String?;

        // Filter by period
        if (period != null && periods.contains(period)) {
          itemsList.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'points': data['points'] ?? 0,
            'category': category,
            'period': period,
            'type': collection.substring(
              0,
              collection.length - 1,
            ), // Remove 's'
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching from $collection: $e');
    }
  }

  /// Fetch student's submissions with grades from unified collection
  Future<Map<String, double>> _fetchStudentGrades(
    String studentId,
    String instructorId,
    String sectionCode,
  ) async {
    final grades = <String, double>{};

    try {
      // Fetch all submissions from unified collection (single query)
      Query<Map<String, dynamic>> query = _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .where('sectionName', isEqualTo: sectionCode);

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final activityType = data['activityType'] as String?;
        final activityId = data['activityId'] as String?;
        final grade = data['grade'];

        if (activityType != null && activityId != null && grade != null) {
          // Get item details based on activityType
          final itemDetails = await _getItemDetailsByActivityType(
            activityId,
            activityType,
            instructorId,
          );
          if (itemDetails != null) {
            final title = itemDetails['title'] as String?;
            if (title != null) {
              final key = _createGradeKey(title, activityId);
              final gradeValue =
                  (grade is num)
                      ? grade.toDouble()
                      : double.tryParse(grade.toString()) ?? 0.0;
              if (gradeValue > 0) {
                grades[key] = gradeValue;
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching student grades: $e');
    }

    return grades;
  }

  /// Get item details to construct the grade key (using activityType)
  Future<Map<String, dynamic>?> _getItemDetailsByActivityType(
    String itemId,
    String activityType,
    String instructorId,
  ) async {
    try {
      // Map activityType to item collection type
      String itemCollection = '';
      switch (activityType.toLowerCase()) {
        case 'assignment':
          itemCollection = 'assignments';
          break;
        case 'activity':
          itemCollection = 'activities';
          break;
        case 'quiz':
          itemCollection = 'quizzes';
          break;
        case 'pit':
          itemCollection = 'pits';
          break;
        default:
          return null;
      }

      final doc =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection(itemCollection)
              .doc(itemId)
              .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('❌ Error getting item details for $itemId ($activityType): $e');
    }
    return null;
  }

  /// Create the grade key based on title and ID (matches class record logic)
  String _createGradeKey(String title, String id) {
    // Convert title to lowercase and remove spaces
    String key = title.toLowerCase().replaceAll(' ', '');
    return '${key}_$id';
  }

  /// Calculate progress and computed final grade from items and student grades
  /// Uses Computed Final Grade (same as class record) instead of raw MGA
  /// Returns Map with 'progress' and 'computedFinalGrade'
  /// If activePeriodType is provided, only calculates for that period
  Map<String, double> _calculateProgressFromItems(
    Map<String, dynamic> itemsData,
    Map<String, double> studentGrades, {
    String? activePeriodType,
  }) {
    // If active period is specified, only calculate for that period
    if (activePeriodType == 'Midterm') {
      // Only show midterm grades
      final midtermMGA = _calculateMGA(
        itemsData['classStandingItems'] as List<Map<String, dynamic>>,
        itemsData['quizPrelimItems'] as List<Map<String, dynamic>>,
        itemsData['midtermExamItems'] as List<Map<String, dynamic>>,
        itemsData['pitItems'] as List<Map<String, dynamic>>,
        studentGrades,
      );

      if (midtermMGA > 0) {
        final midtermGradePoint = _mgaToGradePoint(midtermMGA);
        final midtermGrade = _gradePointToGrade(midtermGradePoint);
        final progress = _gradeToProgress(midtermGrade);
        return {'progress': progress, 'computedFinalGrade': midtermGrade};
      }
      return {'progress': 0.0, 'computedFinalGrade': 5.00};
    } else if (activePeriodType == 'Final') {
      // Only show final grades
      final finalMGA = _calculateMGA(
        itemsData['finalClassStandingItems'] as List<Map<String, dynamic>>,
        itemsData['finalQuizItems'] as List<Map<String, dynamic>>,
        itemsData['finalExamItems'] as List<Map<String, dynamic>>,
        itemsData['finalPitItems'] as List<Map<String, dynamic>>,
        studentGrades,
      );

      if (finalMGA > 0) {
        final finalGradePoint = _mgaToGradePoint(finalMGA);
        final finalGrade = _gradePointToGrade(finalGradePoint);
        final progress = _gradeToProgress(finalGrade);
        return {'progress': progress, 'computedFinalGrade': finalGrade};
      }
      return {'progress': 0.0, 'computedFinalGrade': 5.00};
    }

    // No active period set - calculate combined (original behavior)
    // Calculate midterm MGA
    final midtermMGA = _calculateMGA(
      itemsData['classStandingItems'] as List<Map<String, dynamic>>,
      itemsData['quizPrelimItems'] as List<Map<String, dynamic>>,
      itemsData['midtermExamItems'] as List<Map<String, dynamic>>,
      itemsData['pitItems'] as List<Map<String, dynamic>>,
      studentGrades,
    );

    // Calculate final MGA
    final finalMGA = _calculateMGA(
      itemsData['finalClassStandingItems'] as List<Map<String, dynamic>>,
      itemsData['finalQuizItems'] as List<Map<String, dynamic>>,
      itemsData['finalExamItems'] as List<Map<String, dynamic>>,
      itemsData['finalPitItems'] as List<Map<String, dynamic>>,
      studentGrades,
    );

    // Always compute final grade if midterm exists, even if final MGA is 0
    // (Final MGA = 0 means no items yet, which converts to Grade 5.00)
    final hasMidterm = midtermMGA > 0;

    if (hasMidterm) {
      // Calculate Computed Final Grade (50% midterm, 50% final)
      // Same as Comp12: 1/2 MTG + 1/2 FTG (matches _calculateHalfMtgFtg in class record)
      // Step 1: Convert MGA to Grade Points (even if finalMGA is 0, it will convert to Grade Point 5.000)
      final midtermGradePoint = _mgaToGradePoint(midtermMGA);
      final finalGradePoint = _mgaToGradePoint(
        finalMGA,
      ); // If finalMGA = 0, this gives 5.000

      print(
        '🌳 DEBUG - Midterm MGA: $midtermMGA → Grade Point: $midtermGradePoint',
      );
      print('🌳 DEBUG - Final MGA: $finalMGA → Grade Point: $finalGradePoint');

      // Step 2: Convert Grade Points to Grades (1.00, 1.25, 2.00, etc.)
      // Uses same intervals as _getMidtermGradeEquivalent in class record
      final midtermGrade = _gradePointToGrade(midtermGradePoint);
      final finalGrade = _gradePointToGrade(finalGradePoint);

      print(
        '🌳 DEBUG - Midterm Grade Point: $midtermGradePoint → Grade: $midtermGrade',
      );
      print(
        '🌳 DEBUG - Final Grade Point: $finalGradePoint → Grade: $finalGrade',
      );

      // Step 3: Calculate Computed Final Grade using Grades (same as _calculateHalfMtgFtg)
      // Formula: (50% × Midterm Grade) + (50% × Final Grade)
      // Result can be any decimal value (e.g., 4.88, 3.45, etc.)
      final computedFinalGrade = (midtermGrade * 0.5) + (finalGrade * 0.5);

      // Round to 2 decimals to match class record table display (same as .toStringAsFixed(2))
      final roundedComputedFinalGrade = double.parse(
        computedFinalGrade.toStringAsFixed(2),
      );

      print(
        '🌳 DEBUG - Computed Final Grade: ($midtermGrade × 0.5) + ($finalGrade × 0.5) = $computedFinalGrade → rounded: $roundedComputedFinalGrade',
      );

      // Step 4: Convert Computed Final Grade to tree progress
      // Grade 1.00 = 100%, Grade 5.00 = 0%
      // Use rounded value to match class record table display
      final progress = _gradeToProgress(roundedComputedFinalGrade);
      print(
        '🌳 DEBUG - Progress: $roundedComputedFinalGrade → ${(progress * 100).toStringAsFixed(2)}%',
      );
      return {
        'progress': progress,
        'computedFinalGrade': roundedComputedFinalGrade,
      };
    } else {
      // No grades yet (items exist or not): start from 0%
      return {'progress': 0.0, 'computedFinalGrade': 5.00};
    }
  }

  /// Calculate MGA (Midterm Grade Average) from category items
  double _calculateMGA(
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> examItems,
    List<Map<String, dynamic>> pitItems,
    Map<String, double> studentGrades,
  ) {
    // Calculate category percentages (0.0 to 1.0)
    final cpa = _calculateCategoryPercentage(classStandingItems, studentGrades);
    final qa = _calculateCategoryPercentage(quizPrelimItems, studentGrades);
    final exam = _calculateCategoryPercentage(examItems, studentGrades);
    final pit = _calculateCategoryPercentage(pitItems, studentGrades);

    // Calculate MGA using weights: 10% CPA, 40% QA, 30% Exam, 20% PIT
    final mga = (0.10 * cpa) + (0.40 * qa) + (0.30 * exam) + (0.20 * pit);

    return mga;
  }

  /// Convert MGA (0.0-1.0) to Grade Point (1.000-5.000)
  /// Uses same formula as class_record_table.dart
  double _mgaToGradePoint(double mga) {
    double ratio = mga; // mga is already 0.0 to 1.0
    double gradePoint;
    if (ratio >= 0.7) {
      gradePoint = (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      gradePoint = 5.0 - (20.0 / 7.0) * ratio;
    }
    return double.parse(gradePoint.toStringAsFixed(3));
  }

  /// Convert Grade Point (1.000-5.000) to Grade (1.00, 1.25, 2.00, etc.)
  /// Uses same intervals as _getMidtermGradeEquivalent in class_record_table.dart
  double _gradePointToGrade(double gradePoint) {
    final intervals = [
      [1.000, 1.125, 1.00],
      [1.125, 1.375, 1.25],
      [1.375, 1.625, 1.50],
      [1.625, 1.875, 1.75],
      [1.875, 2.125, 2.00],
      [2.125, 2.375, 2.25],
      [2.375, 2.625, 2.50],
      [2.625, 2.875, 2.75],
      [2.875, 3.125, 3.00],
      [3.125, 3.375, 3.25],
      [3.375, 3.625, 3.50],
      [3.625, 3.875, 3.75],
      [3.875, 4.125, 4.00],
      [4.125, 4.375, 4.25],
      [4.375, 4.625, 4.50],
      [4.625, 4.875, 4.75],
      [4.875, 5.125, 5.00],
    ];

    for (var range in intervals) {
      if (gradePoint >= range[0] && gradePoint < range[1]) {
        return range[2];
      }
    }
    return 5.00; // Default to 5.00 if out of range
  }

  /// Convert Grade (1.00-5.00) to Tree Progress (0.0-1.0)
  /// Uses interpolation between exact grade points based on grading scale
  /// Exact points:
  ///   1.00 → 100%, 1.25 → 96%, 1.50 → 93%, 1.75 → 90%
  ///   2.00 → 87%, 2.25 → 84%, 2.50 → 81%, 2.75 → 78%
  ///   3.00 → 75%, 3.25 → 74%, 3.50 → 71%, 3.75 → 68%
  ///   4.00 → 65%, 4.01-5.00 → interpolate 64% to 0%
  /// For decimal grades, linearly interpolates between adjacent exact points
  double _gradeToProgress(double grade) {
    print('🌳 DEBUG _gradeToProgress - Input grade: $grade');

    // Handle edge cases
    if (grade <= 1.00) {
      print('🌳 DEBUG _gradeToProgress - Grade <= 1.00, returning 1.0 (100%)');
      return 1.0; // Perfect grade = 100%
    }
    if (grade >= 5.00) {
      print('🌳 DEBUG _gradeToProgress - Grade >= 5.00, returning 0.0 (0%)');
      return 0.0; // Failing grade = 0%
    }

    // Special range: 4.01 to 5.00 → interpolate from 64% (at 4.01) to 0% (at 5.00)
    if (grade > 4.01) {
      // Linear interpolation: 4.01 = 64%, 5.00 = 0%
      final progress = 0.64 * (5.00 - grade) / (5.00 - 4.01);
      print(
        '🌳 DEBUG _gradeToProgress - Special range (4.01-5.00): 0.64 * (5.00 - $grade) / 0.99 = $progress',
      );
      final clampedProgress = progress.clamp(0.0, 1.0);
      print(
        '🌳 DEBUG _gradeToProgress - Result: $clampedProgress = ${(clampedProgress * 100).toStringAsFixed(2)}%',
      );
      return clampedProgress;
    }

    // Define exact grade points and their percentage equivalents
    final exactPoints = [
      [1.00, 1.0], // 100%
      [1.25, 0.96], // 96%
      [1.50, 0.93], // 93%
      [1.75, 0.90], // 90%
      [2.00, 0.87], // 87%
      [2.25, 0.84], // 84%
      [2.50, 0.81], // 81%
      [2.75, 0.78], // 78%
      [3.00, 0.75], // 75%
      [3.25, 0.74], // 74%
      [3.50, 0.71], // 71%
      [3.75, 0.68], // 68%
      [4.00, 0.65], // 65%
      [4.01, 0.64], // 64% (transition point)
    ];

    // Check if grade matches an exact point
    for (var point in exactPoints) {
      if ((grade - (point[0] as num)).abs() < 0.001) {
        final progress = (point[1] as num).toDouble();
        print(
          '🌳 DEBUG _gradeToProgress - Exact match: ${point[0]} → ${(progress * 100).toStringAsFixed(2)}%',
        );
        return progress;
      }
    }

    // Find the two exact points to interpolate between
    for (int i = 0; i < exactPoints.length - 1; i++) {
      final lowerGrade = (exactPoints[i][0] as num).toDouble();
      final lowerProgress = (exactPoints[i][1] as num).toDouble();
      final upperGrade = (exactPoints[i + 1][0] as num).toDouble();
      final upperProgress = (exactPoints[i + 1][1] as num).toDouble();

      if (grade >= lowerGrade && grade <= upperGrade) {
        // Linear interpolation
        final gradeRange = upperGrade - lowerGrade;
        final progressRange =
            lowerProgress - upperProgress; // Note: lower is higher percentage
        final ratio = (grade - lowerGrade) / gradeRange;
        final progress = lowerProgress - (ratio * progressRange);

        print(
          '🌳 DEBUG _gradeToProgress - Interpolating: $grade between $lowerGrade (${(lowerProgress * 100).toStringAsFixed(2)}%) and $upperGrade (${(upperProgress * 100).toStringAsFixed(2)}%)',
        );
        print(
          '🌳 DEBUG _gradeToProgress - Ratio: $ratio, Result: $progress = ${(progress * 100).toStringAsFixed(2)}%',
        );

        final clampedProgress = progress.clamp(0.0, 1.0);
        return clampedProgress;
      }
    }

    // Fallback (shouldn't reach here)
    print('🌳 DEBUG _gradeToProgress - Fallback calculation');
    return ((5.00 - grade) / 4.00).clamp(0.0, 1.0);
  }

  /// Calculate category percentage (totalScore / maxTotal)
  double _calculateCategoryPercentage(
    List<Map<String, dynamic>> items,
    Map<String, double> studentGrades,
  ) {
    if (items.isEmpty) return 0.0;

    int totalScore = 0;
    int maxTotal = 0;

    for (var item in items) {
      final itemId = item['id'] as String?;
      final title = item['title'] as String?;
      final points = item['points'] as int? ?? 0;

      if (itemId != null && title != null) {
        // Create key same way as class record
        final key = _createGradeKey(title, itemId);
        final grade = studentGrades[key] ?? 0.0;
        totalScore += grade.toInt();
        maxTotal += points;
      }
    }

    if (maxTotal == 0) return 0.0;
    return totalScore / maxTotal; // Returns 0.0 to 1.0
  }

  /// Calculate category completion data (completed/total items)
  /// Always returns all 4 categories, even if no items exist (0/0)
  List<CategoryCompletion> _calculateCategoryCompletions(
    Map<String, dynamic> itemsData,
    Map<String, double> studentGrades, {
    required bool isMidterm,
  }) {
    final completions = <CategoryCompletion>[];

    // Category names and their item lists - Always show all 4 categories
    final categories = [
      {
        'key': isMidterm ? 'classStandingItems' : 'finalClassStandingItems',
        'name': 'Class Standing',
        'category': 'class_standing',
      },
      {
        'key': isMidterm ? 'quizPrelimItems' : 'finalQuizItems',
        'name': isMidterm ? 'Quiz/Prelim' : 'Quiz/Pre-final',
        'category': 'quiz_prelim',
      },
      {
        'key': isMidterm ? 'midtermExamItems' : 'finalExamItems',
        'name': isMidterm ? 'Midterm Exam' : 'Final Exam',
        'category': 'midterm_exam',
      },
      {
        'key': isMidterm ? 'pitItems' : 'finalPitItems',
        'name': 'PIT',
        'category': 'pit',
      },
    ];

    for (var cat in categories) {
      final items = itemsData[cat['key']] as List<Map<String, dynamic>>;
      final total = items.length;
      int completed = 0;

      // Count how many items have grades
      for (var item in items) {
        final itemId = item['id'] as String?;
        final title = item['title'] as String?;

        if (itemId != null && title != null) {
          final key = _createGradeKey(title, itemId);
          if (studentGrades.containsKey(key) && studentGrades[key]! > 0) {
            completed++;
          }
        }
      }

      // Always show category, even if total is 0 (0/0)
      final percentage = total > 0 ? completed / total : 0.0;

      completions.add(
        CategoryCompletion(
          category: cat['category'] as String,
          displayName: cat['name'] as String,
          completed: completed,
          total: total,
          percentage: percentage,
          period: isMidterm ? 'midterm' : 'final',
        ),
      );
    }

    return completions;
  }
}
