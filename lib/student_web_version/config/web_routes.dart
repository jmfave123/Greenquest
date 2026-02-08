import 'package:get/get.dart';
import '../screens/home/student_home_screen.dart';

/// Web routes configuration for student portal
/// Defines all navigation routes and their corresponding screens

class WebRoutes {
  // Route names
  static const String home = '/student-web-home';
  static const String activities = '/student-web-activities';
  static const String assignments = '/student-web-assignments';
  static const String quizzes = '/student-web-quizzes';
  static const String leaderboard = '/student-web-leaderboard';
  static const String materials = '/student-web-materials';
  static const String messages = '/student-web-messages';
  static const String profile = '/student-web-profile';
  static const String login = '/student-web-login';

  /// Get all routes for the student web portal
  static List<GetPage> getPages() {
    return [
      GetPage(
        name: home,
        page: () => const WebStudentHomeScreen(),
        transition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 200),
      ),
      // TODO: Add more routes as screens are implemented
      // GetPage(name: activities, page: () => const WebActivityListScreen()),
      // GetPage(name: assignments, page: () => const WebAssignmentListScreen()),
      // GetPage(name: quizzes, page: () => const WebQuizListScreen()),
      // GetPage(name: leaderboard, page: () => const WebLeaderboardScreen()),
      // GetPage(name: materials, page: () => const WebMaterialsListScreen()),
      // GetPage(name: messages, page: () => const WebMessageListScreen()),
      // GetPage(name: profile, page: () => const WebProfileScreen()),
      // GetPage(name: login, page: () => const WebStudentLoginScreen()),
    ];
  }

  // Prevent instantiation
  WebRoutes._();
}
