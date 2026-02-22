// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:greenquest/instructor/message/message_list_screen.dart';
import 'package:greenquest/instructor/report/class_report_screen.dart';
import 'package:greenquest/instructor/report/report_screen.dart';
import 'package:greenquest/user/auth/login_screen.dart';
import 'package:greenquest/user/home_screen.dart';
import 'package:greenquest/user/select/select_instructor_screen.dart';
import 'user/auth/splash_screen.dart';
import 'user/auth/register_screen.dart';
import 'user/auth/pending_approval_screen.dart';
import 'user/select/select_course_screen.dart';
import 'user/select/upload_cor_screen.dart';
import 'shared/login/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/manage_instructors_screen.dart';
import 'admin/department_management_screen.dart';
import 'admin/admin_class_management_screen.dart';
import 'admin/manage_trees.dart';
import 'instructor/instructor_register_screen.dart';
import 'instructor/instructor_forgot_password_screen.dart';
import 'instructor/email_verification_screen.dart';
import 'instructor/phone_otp_verification_screen.dart';
import 'instructor/auth/instructor_pending_approval_screen.dart';
import 'instructor/instructor_dashboard.dart';
import 'instructor/announcement/announcement_screen.dart';
import 'instructor/planted_trees/planted_trees_screen.dart';
import 'instructor/profile/profile_screen.dart';
import 'instructor/create/create_screen.dart';
import 'instructor/create/assignment_screen.dart';
import 'instructor/create/activity_screen.dart';
import 'instructor/create/quiz_screen_new.dart';
import 'instructor/class/class_screen.dart';
import 'instructor/class/class_detail_screen.dart';
import 'user/submit/file_picker_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shared/screens/image_upload_example_screen.dart';
import 'shared/services/online_status_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/auth_middleware.dart';
import 'student_web_version/config/web_routes.dart';
import 'student_web_version/config/web_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Warning: .env file not found. Using default configuration.');
    }
  }

  // Ensure Flutter is fully initialized before proceeding
  await Future.delayed(const Duration(milliseconds: 100));

  // Initialize Firebase FIRST before any Firebase-dependent services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AuthService AFTER Firebase is ready
  Get.put(AuthService());

  // Initialize OneSignal only on mobile platforms (not web)
  if (!kIsWeb) {
    try {
      final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
      if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(oneSignalAppId);
        OneSignal.Notifications.requestPermission(false);
      } else if (kDebugMode) {
        print('⚠️ Warning: ONESIGNAL_APP_ID not configured in .env');
      }
    } catch (e) {
      // Don't throw - allow app to continue even if OneSignal fails
      if (kDebugMode) {
        print('⚠️ OneSignal initialization error: $e');
      }
    }
  }

  // Initialize online status service
  OnlineStatusService().initialize();

  // Use a single app widget that handles both web and mobile
  runApp(const GreenQuestApp());
}

class GreenQuestApp extends StatelessWidget {
  const GreenQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Determine initial route based on platform
    final String initialRoute = kIsWeb ? '/login' : '/splash';

    return GetMaterialApp(
      title: 'GreenQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF43A047),
          selectionColor: Color(0xFFB9F6CA), // Lighter green for selection
          selectionHandleColor: Color(0xFF43A047), // The droplet color
        ),
      ),
      initialBinding: kIsWeb ? WebHomeBinding() : null,
      initialRoute: initialRoute,
      getPages: [
        // Mobile routes
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login_app', page: () => const LoginScreenApp()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(
          name: '/pending-approval',
          page: () => const PendingApprovalScreen(),
        ),
        GetPage(name: '/select-course', page: () => const SelectCourseScreen()),
        GetPage(name: '/upload-cor', page: () => const UploadCorScreen()),
        GetPage(
          name: '/select-instructor',
          page: () => const SelectInstructorScreen(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
          middlewares: [StudentMiddleware()],
        ),

        // Web routes
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
          name: '/admin-dashboard',
          page: () => const AdminDashboard(),
          middlewares: [AdminMiddleware()],
        ),
        GetPage(
          name: '/admin-manage-instructors',
          page: () => const ManageInstructorsScreen(),
          middlewares: [AdminMiddleware()],
        ),
        GetPage(
          name: '/admin-manage-departments',
          page: () => const DepartmentManagementScreen(),
          middlewares: [AdminMiddleware()],
        ),
        GetPage(
          name: '/admin-manage-classes',
          page: () => const AdminClassManagementScreen(),
          middlewares: [AdminMiddleware()],
        ),
        GetPage(
          name: '/admin-manage-trees',
          page: () => const ManageTreesScreen(),
          middlewares: [AdminMiddleware()],
        ),
        GetPage(
          name: '/instructor-dashboard',
          page: () => const InstructorDashboardScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-message-list',
          page: () => const InstructorMessageListScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-register',
          page: () => const InstructorRegisterScreen(),
        ),
        GetPage(
          name: '/instructor-email-verification',
          page: () => const EmailVerificationScreen(),
        ),
        GetPage(
          name: '/instructor-phone-otp-verification',
          page: () => const PhoneOtpVerificationScreen(),
        ),
        GetPage(
          name: '/instructor-pending-approval',
          page: () => const InstructorPendingApprovalScreen(),
        ),
        GetPage(
          name: '/instructor-forgot-password',
          page: () => const InstructorForgotPasswordScreen(),
        ),
        GetPage(
          name: '/instructor-announcement',
          page: () => const InstructorAnnouncementScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-planted-trees',
          page: () => const InstructorPlantedTreesScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-profile',
          page: () => const InstructorProfileScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-report',
          page: () => const InstructorReportScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-class-report',
          page: () => const ClassReportScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-create',
          page: () => const CreateScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/assignment',
          page: () => const AssignmentScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/activity',
          page: () => const ActivityScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/quiz',
          page: () => const QuizzesScreen(period: 'Prelim'),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-class',
          page: () => const ClassScreen(),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/instructor-class-detail',
          page: () => const ClassDetailScreen(classData: {}),
          middlewares: [InstructorMiddleware()],
        ),
        GetPage(
          name: '/image-upload-example',
          page: () => const ImageUploadExampleScreen(),
        ),
        GetPage(
          name: '/file-picker',
          page: () => const FilePickerScreen(type: 'assignment', itemData: {}),
        ),

        // Student Web Portal routes
        ...WebRoutes.getPages(),
      ],
    );
  }
}
