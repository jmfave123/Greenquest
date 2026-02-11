import 'package:get/get.dart';
import '../screens/home/student_home_screen.dart';
import '../screens/activities/web_activity_list_screen.dart';
import '../screens/assignments/web_assignment_list_screen.dart';
import '../screens/quizzes/web_quiz_list_screen.dart';
import '../screens/leaderboard/web_leaderboard_screen.dart';
import '../screens/materials/web_materials_list_screen.dart';
import '../screens/messages/web_message_list_screen.dart';
import '../screens/profile/web_profile_screen.dart';
import '../screens/notifications/web_announcement_list_screen.dart';
import '../screens/pit/web_pit_list_screen.dart';
import '../screens/auth/web_pending_approval_screen.dart';
import '../screens/auth/web_select_instructor_screen.dart';
import '../screens/auth/web_select_course_screen.dart';
import '../screens/auth/web_upload_cor_screen.dart';
import '../screens/auth/web_register_screen.dart';

/// Web routes configuration for student portal
/// Defines all navigation routes and their corresponding screens

class WebRoutes {
  // Route names
  static const String home = '/student-web-home';
  static const String activities = '/student-web-activities';
  static const String assignments = '/student-web-assignments';
  static const String quizzes = '/student-web-quizzes';
  static const String leaderboard = '/leaderboard';
  static const String materials = '/materials';
  static const String messages = '/student-web-messages';
  static const String profile = '/student-web-profile';
  static const String announcements = '/student-web-announcements';
  static const String pits = '/student-web-pits';
  static const String login = '/student-web-login';
  static const String register = '/student-web-register';
  static const String pendingApproval = '/student-web-pending-approval';
  static const String selectInstructor = '/student-web-select-instructor';
  static const String selectCourse = '/student-web-select-course';
  static const String uploadCor = '/student-web-upload-cor';

  /// Get all routes for the student web portal
  static List<GetPage> getPages() {
    return [
      GetPage(
        name: home,
        page: () => WebStudentHomeScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: activities,
        page: () => const WebActivityListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: assignments,
        page: () => const WebAssignmentListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: quizzes,
        page: () => const WebQuizListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      // TODO: Add more routes as screens are implemented
      GetPage(
        name: leaderboard,
        page: () => const WebLeaderboardScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: materials,
        page: () => const WebMaterialsListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: messages,
        page: () => const WebMessageListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: profile,
        page: () => const WebProfileScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: announcements,
        page: () => const WebAnnouncementListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: pits,
        page: () => const WebPitListScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: pendingApproval,
        page: () => const WebPendingApprovalScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: selectInstructor,
        page: () => const WebSelectInstructorScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: selectCourse,
        page: () => const WebSelectCourseScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: uploadCor,
        page: () => const WebUploadCorScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      GetPage(
        name: register,
        page: () => const WebRegisterScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      // GetPage(name: login, page: () => const WebStudentLoginScreen()),
    ];
  }

  // Prevent instantiation
  WebRoutes._();
}
