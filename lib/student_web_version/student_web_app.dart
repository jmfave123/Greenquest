import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/web_theme.dart';
import 'config/web_routes.dart';

/// Main entry point for student web application
/// Configures theme, routes, and initial screen

class StudentWebApp extends StatelessWidget {
  const StudentWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GreenQuest - Student Portal',
      debugShowCheckedModeBanner: false,
      theme: WebTheme.themeData,
      initialRoute: WebRoutes.home,
      getPages: WebRoutes.getPages(),
      defaultTransition: Transition.fadeIn,
    );
  }
}
