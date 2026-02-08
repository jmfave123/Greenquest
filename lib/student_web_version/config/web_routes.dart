import 'package:get/get.dart';
import '../screens/home/student_home_screen.dart';
import '../screens/activities/web_activity_list_screen.dart';
import '../screens/assignments/web_assignment_list_screen.dart';
import '../screens/quizzes/web_quiz_list_screen.dart';
import '../screens/leaderboard/web_leaderboard_screen.dart';
import '../screens/materials/web_materials_list_screen.dart';
import '../screens/messages/web_message_list_screen.dart';
import 'web_bindings.dart';

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
  static const String login = '/student-web-login';

  /// Get all routes for the student web portal
  static List<GetPage> getPages() {
    return [
      GetPage(
        name: home,
        page: () => WebStudentHomeScreen(),
        binding: WebHomeBinding(),
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
      // GetPage(name: profile, page: () => const WebProfileScreen()),
      // GetPage(name: login, page: () => const WebStudentLoginScreen()),
    ];
  }

  // Prevent instantiation
  WebRoutes._();
}
