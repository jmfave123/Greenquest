import 'package:flutter/material.dart';
import '../services/instructor_service.dart';

/// A reusable avatar widget that shows instructor profile image or initials
class InstructorAvatar extends StatelessWidget {
  final String? profileImage;
  final String name;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const InstructorAvatar({
    super.key,
    this.profileImage,
    required this.name,
    this.radius = 20,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final initials = InstructorService.getInitials(name);
    final avatarColor = backgroundColor ?? _getAvatarColor(name);
    final textColorFinal = textColor ?? Colors.white;
    final fontSizeFinal = fontSize ?? (radius * 0.6);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: avatarColor,
          backgroundImage:
              profileImage != null && profileImage!.isNotEmpty
                  ? NetworkImage(profileImage!)
                  : null,
          child:
              profileImage == null || profileImage!.isEmpty
                  ? Text(
                    initials,
                    style: TextStyle(
                      color: textColorFinal,
                      fontSize: fontSizeFinal,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF34A853) : Colors.grey,
                borderRadius: BorderRadius.circular(radius * 0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Generate a consistent color for the avatar based on the name
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF34A853), // Green
      const Color(0xFF4285F4), // Blue
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC04), // Yellow
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF5722), // Orange
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
    ];

    // Use the name to generate a consistent color
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

/// A specialized avatar for instructor profiles in messages
class InstructorMessageAvatar extends StatelessWidget {
  final String? profileImage;
  final String name;
  final bool isOnline;
  final double radius;

  const InstructorMessageAvatar({
    super.key,
    this.profileImage,
    required this.name,
    this.isOnline = false,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return InstructorAvatar(
      profileImage: profileImage,
      name: name,
      radius: radius,
      showOnlineIndicator: true,
      isOnline: isOnline,
    );
  }
}

/// A large avatar for instructor profiles
class InstructorProfileAvatar extends StatelessWidget {
  final String? profileImage;
  final String name;
  final bool isOnline;
  final double radius;

  const InstructorProfileAvatar({
    super.key,
    this.profileImage,
    required this.name,
    this.isOnline = false,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return InstructorAvatar(
      profileImage: profileImage,
      name: name,
      radius: radius,
      showOnlineIndicator: true,
      isOnline: isOnline,
    );
  }
}
