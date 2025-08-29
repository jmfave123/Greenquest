import 'package:flutter/material.dart';

class InstructorAppBar extends StatelessWidget {
  final String instructorName;
  final String instructorRole;
  const InstructorAppBar({Key? key, required this.instructorName, this.instructorRole = 'Instructor'}) : super(key: key);

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
          // Search bar
          Container(
            width: 400,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Image.asset('assets/instructor/icons/akar-icons_search.png', width: 20, color: Color(0xFFBDBDBD)),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search..',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                    ),
                    style: TextStyle(fontSize: 15),
                    cursorColor: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Instructor avatar and name
          Row(
            children: [
              ClipOval(
                child: Image.asset('assets/instructor/images/Avatar.png', width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(instructorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(instructorRole, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
} 