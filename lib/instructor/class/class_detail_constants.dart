import 'package:flutter/material.dart';

/// Constants used throughout the Class Detail Screen
/// Following agent.md guidelines: Section 18.1 - Use named constants instead of magic numbers
class ClassDetailConstants {
  // Color Constants
  static const Color primaryGreen = Color(0xFF34A853);
  static const Color approvedColor = Color(0xFF34A853);
  static const Color pendingColor = Color(0xFFFBBC04);
  static const Color rejectedColor = Color(0xFFEA4335);
  static const Color lateSubmissionColor = Color(0xFFEA4335);
  static const Color gradedColor = Color(0xFF34A853);
  static const Color submittedColor = Color(0xFF4285F4);

  // Dimension Constants
  static const double bannerHeight = 200.0;
  static const double profileAvatarRadius = 30.0;
  static const double studentAvatarRadius = 24.0;
  static const double cardBorderRadius = 12.0;
  static const double tabIndicatorHeight = 3.0;
  static const double tabIndicatorWidth = 40.0;

  // Spacing Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double horizontalPagePadding = 50.0;
  static const double cardVerticalSpacing = 8.0;

  // Filter Options
  static const List<String> studentFilterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  static const List<String> postedItemTypeFilterOptions = [
    'All Types',
    'Assignment',
    'Activity',
    'Quiz',
    'PIT',
    'Material',
  ];

  static const List<String> submissionTypeFilterOptions = [
    'All Types',
    'Assignment',
    'Activity',
    'Quiz',
    'PIT',
  ];

  static const List<String> submissionStatusFilterOptions = [
    'All Status',
    'Submitted (Not Yet Graded)',
    'Graded',
    'Late',
  ];

  // Time Constants
  static const int snackbarDurationSeconds = 3;
  static const int onlineThresholdMinutes = 5;

  // Text Constants
  static const String defaultStudentName = 'Unknown Student';
  static const String defaultInstructor = 'Unknown Instructor';
  static const String noTopicLabel = 'No Topic';
  static const String allTopicsLabel = 'All Topics';

  // Badge Constants
  static const int maxBadgeCount = 9;
  static const double badgeMinSize = 18.0;
  static const double badgeFontSize = 11.0;

  // Asset Paths
  static const String defaultBannerImage =
      'assets/instructor/images/Group 1171274927.png';
  static const String defaultAvatarImage = 'assets/images/Avatar.png';

  // Firestore Collection Names
  static const String submissionsCollection = 'submissions';
  static const String classesCollection = 'classes';
  static const String usersCollection = 'users';

  // Activity Types
  static const String activityTypeTreePlanting = 'tree_planting';
  static const String activityTypeAssignment = 'assignment';
  static const String activityTypeActivity = 'activity';
  static const String activityTypeQuiz = 'quiz';
  static const String activityTypePIT = 'PIT';

  // Status Values
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusSubmitted = 'submitted';
  static const String statusGraded = 'graded';
  static const String statusLate = 'late';

  // Notification Types
  static const String notificationTypeTreeRejected = 'tree_rejected';
  static const String notificationTypeTreeApproved = 'tree_approved';
  static const String notificationTypeGraded = 'graded';

  // Validation Constants
  static const int maxReasonLength = 500;
  static const int minGrade = 0;
  static const int maxGrade = 100;

  // Tab Indices
  static const int tabIndexStream = 0;
  static const int tabIndexPeople = 1;
  static const int tabIndexClasswork = 2;
  static const int tabIndexTrees = 3;

  // Error Messages
  static const String errorLoadingSubmissions = 'Failed to load submissions';
  static const String errorApprovingStudent = 'Failed to approve student';
  static const String errorRejectingStudent = 'Failed to reject student';
  static const String errorGradingSubmission = 'Failed to grade submission';
  static const String errorLoadingStudents = 'Failed to load students';

  // Success Messages
  static const String successStudentApproved = 'Student approved successfully';
  static const String successStudentRejected = 'Student rejected';
  static const String successTreeApproved =
      'Tree planting approved successfully';
  static const String successTreeRejected = 'Tree planting rejected';
  static const String successSubmissionGraded =
      'Submission graded successfully';

  // Private constructor to prevent instantiation
  ClassDetailConstants._();
}
