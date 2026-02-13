import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_service.dart';

/// Middleware to protect routes and check authentication/authorization
class AuthMiddleware extends GetMiddleware {
  final List<String> requiredRoles;

  AuthMiddleware({this.requiredRoles = const []});

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // Check if user is authenticated
    if (!authService.isAuthenticated) {
      debugPrint('🚫 User not authenticated. Redirecting to login.');
      return const RouteSettings(name: '/login');
    }

    // If roles are required, check authorization asynchronously
    // Note: GetX middleware redirect is synchronous, so we need to handle async checks differently
    // We'll do a double-check in the onPageCalled callback below
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    // This runs before building the page
    final authService = Get.find<AuthService>();

    if (!authService.isAuthenticated) {
      debugPrint('🚫 User not authenticated in onPageCalled. Redirecting to login.');
      Get.offAllNamed('/login');
      return null;
    }

    // Check user role asynchronously
    if (requiredRoles.isNotEmpty) {
      authService.hasAnyRole(requiredRoles).then((hasRole) {
        if (!hasRole) {
          debugPrint('🚫 User does not have required role: $requiredRoles');
          Get.snackbar(
            'Access Denied',
            'You do not have permission to access this page.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          Get.offAllNamed('/login');
        }
      });
    }

    return super.onPageCalled(page);
  }
}

/// Specific middleware for admin-only routes
class AdminMiddleware extends AuthMiddleware {
  AdminMiddleware() : super(requiredRoles: ['admin']);
}

/// Specific middleware for instructor-only routes
class InstructorMiddleware extends AuthMiddleware {
  InstructorMiddleware() : super(requiredRoles: ['instructor']);
}

/// Specific middleware for student-only routes
class StudentMiddleware extends AuthMiddleware {
  StudentMiddleware() : super(requiredRoles: ['student']);
}

/// Middleware for routes accessible by multiple roles
class MultiRoleMiddleware extends AuthMiddleware {
  MultiRoleMiddleware(List<String> roles) : super(requiredRoles: roles);
}
