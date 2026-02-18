import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InstructorInfoHeader extends StatelessWidget {
  final RxString instructorName;
  final RxString studentName;
  final String? profileImageUrl;
  final String? subtitle;
  final bool isWeb;

  const InstructorInfoHeader({
    super.key,
    required this.instructorName,
    required this.studentName,
    this.profileImageUrl,
    this.subtitle,
    this.isWeb = false,
  });

  ImageProvider? _getProfileImage() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) return null;
    if (profileImageUrl!.startsWith('data:image/') ||
        profileImageUrl!.startsWith('/9j/')) {
      try {
        return MemoryImage(base64Decode(profileImageUrl!));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(profileImageUrl!);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF43A047),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFF57C00),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0]
          .substring(0, parts[0].length > 2 ? 2 : parts[0].length)
          .toUpperCase();
    } else {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final last =
          parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      return (first + last).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (instructorName.value.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.only(bottom: isWeb ? 0 : 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: _getProfileImage(),
              backgroundColor: _getAvatarColor(instructorName.value),
              child:
                  _getProfileImage() == null
                      ? Text(
                        _getInitials(instructorName.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructor: ${instructorName.value}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle ??
                        (studentName.value.isNotEmpty
                            ? 'Student: ${studentName.value}'
                            : 'Select your department and section'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
