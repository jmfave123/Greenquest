// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure Flutter is fully initialized before proceeding
  await Future.delayed(const Duration(milliseconds: 100));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize OneSignal only on mobile platforms (not web)
  if (!kIsWeb) {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize("679023d3-f6ec-425a-8370-8828fbdac926");
      OneSignal.Notifications.requestPermission(false);
      print('✅ OneSignal initialized (mobile only)');
    } catch (e) {
      print('⚠️ OneSignal initialization error (non-critical): $e');
      // Don't throw - allow app to continue even if OneSignal fails
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
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
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
        GetPage(name: '/home', page: () => const HomeScreen()),

        // Web routes
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/admin-dashboard', page: () => const AdminDashboard()),
        GetPage(
          name: '/admin-manage-instructors',
          page: () => const ManageInstructorsScreen(),
        ),
        GetPage(
          name: '/admin-manage-departments',
          page: () => const DepartmentManagementScreen(),
        ),
        GetPage(
          name: '/admin-manage-classes',
          page: () => const AdminClassManagementScreen(),
        ),
        GetPage(
          name: '/admin-manage-trees',
          page: () => const ManageTreesScreen(),
        ),
        GetPage(
          name: '/instructor-dashboard',
          page: () => const InstructorDashboardScreen(),
        ),
        GetPage(
          name: '/instructor-message-list',
          page: () => const InstructorMessageListScreen(),
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
          name: '/instructor-forgot-password',
          page: () => const InstructorForgotPasswordScreen(),
        ),
        GetPage(
          name: '/instructor-announcement',
          page: () => const InstructorAnnouncementScreen(),
        ),
        GetPage(
          name: '/instructor-planted-trees',
          page: () => const InstructorPlantedTreesScreen(),
        ),
        GetPage(
          name: '/instructor-profile',
          page: () => const InstructorProfileScreen(),
        ),
        GetPage(
          name: '/instructor-report',
          page: () => const InstructorReportScreen(),
        ),
        GetPage(
          name: '/instructor-class-report',
          page: () => const ClassReportScreen(),
        ),
        GetPage(name: '/instructor-create', page: () => const CreateScreen()),
        GetPage(name: '/assignment', page: () => const AssignmentScreen()),
        GetPage(name: '/activity', page: () => const ActivityScreen()),
        GetPage(
          name: '/quiz',
          page: () => const QuizzesScreen(period: 'Prelim'),
        ),
        GetPage(name: '/instructor-class', page: () => const ClassScreen()),
        GetPage(
          name: '/instructor-class-detail',
          page: () => const ClassDetailScreen(classData: {}),
        ),
        GetPage(
          name: '/image-upload-example',
          page: () => const ImageUploadExampleScreen(),
        ),
        GetPage(
          name: '/file-picker',
          page: () => const FilePickerScreen(type: 'assignment', itemData: {}),
        ),
      ],
    );
  }
}
