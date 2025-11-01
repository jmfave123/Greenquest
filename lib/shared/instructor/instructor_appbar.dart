import 'package:flutter/material.dart';

class InstructorAppBar extends StatelessWidget {
  final String instructorName;
  final String instructorRole;
  final String? profileImageUrl;

  const InstructorAppBar({
    super.key,
    required this.instructorName,
    this.instructorRole = 'Instructor',
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Spacer(),
          // Instructor avatar and name
          Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    instructorRole,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build profile avatar with image or initials
  Widget _buildProfileAvatar() {
    // Get initials from name
    String getInitials(String name) {
      if (name.isEmpty) return '';
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final initials = getInitials(instructorName);
    final hasImage = profileImageUrl != null && profileImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 22,
      backgroundColor: hasImage ? Colors.transparent : Colors.blue.shade700,
      backgroundImage: hasImage ? NetworkImage(profileImageUrl!) : null,
      child:
          !hasImage
              ? Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
              : null,
    );
  }
}
