import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final RxString searchQuery;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    this.hintText = 'Search instructors...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(
        () => TextField(
          controller: controller,
          onChanged: (value) {
            searchQuery.value = value;
            onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.black38),
            suffixIcon:
                searchQuery.value.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black38),
                      onPressed: () {
                        controller.clear();
                        searchQuery.value = '';
                        onChanged?.call('');
                      },
                    )
                    : null,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.black38),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
