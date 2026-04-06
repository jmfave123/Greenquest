import 'package:flutter/material.dart';
import 'package:greenquest/admin/admin_dashboard.dart';

void showInstructorProfile(
  Map<String, dynamic> instructorData,
  BuildContext context,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: InstructorProfileView(instructor: instructorData),
        ),
      );
    },
  );
}
