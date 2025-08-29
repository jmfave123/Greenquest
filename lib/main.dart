// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:greenquest/instructor/message/message_list_screen.dart';
import 'package:greenquest/instructor/report/class_report_screen.dart';
import 'package:greenquest/instructor/report/report_screen.dart';
import 'package:greenquest/user/auth/login_screen.dart';
import 'dart:io' show Platform;
import 'package:greenquest/user/home_screen.dart';
import 'package:greenquest/user/select/select_instructor_screen.dart';
import 'user/auth/splash_screen.dart';
import 'user/auth/register_screen.dart';
import 'user/select/select_course_screen.dart';
import 'shared/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'instructor/instructor_register_screen.dart';
import 'instructor/instructor_forgot_password_screen.dart';
import 'instructor/instructor_dashboard.dart';
import 'instructor/announcement/announcement_screen.dart';
import 'instructor/planted_trees/planted_trees_screen.dart';
import 'instructor/profile/profile_screen.dart';
import 'instructor/create/create_screen.dart';
import 'instructor/class/class_screen.dart';
import 'instructor/class/class_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(kIsWeb ? const GreenQuestWeb() : const GreenQuestApp());
}

class GreenQuestApp extends StatelessWidget {
  const GreenQuestApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GreenQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login_app', page: () => const LoginScreenApp()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/select-course', page: () => const SelectCourseScreen()),
        GetPage(
          name: '/select-instructor',
          page: () => const SelectInstructorScreen(),
        ),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}

class GreenQuestWeb extends StatelessWidget {
  const GreenQuestWeb({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GreenQuest Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/admin-dashboard', page: () => const AdminDashboard()),
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
        GetPage(name: '/instructor-class', page: () => const ClassScreen()),
        GetPage(
          name: '/instructor-class-detail',
          page: () => const ClassDetailScreen(classData: {}),
        ),
      ],
    );
  }
}
