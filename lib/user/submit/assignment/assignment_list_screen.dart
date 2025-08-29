import 'package:flutter/material.dart';
import 'package:greenquest/user/submit/assignment/assignment_detail_screen.dart';

class AssignmentListScreen extends StatelessWidget {
  const AssignmentListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assignments = List.generate(10, (i) => {
      'title': 'Mia Castro posted new assignment: Assignment ${10 - i}',
      'date': 'July ${28 - i * 2}',
    });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chose Assignment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
        backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: assignments.length,
        itemBuilder: (context, i) {
          final a = assignments[i];
          return GestureDetector(
            onTap: () => 
              Navigator.push(context, MaterialPageRoute(builder: (_) =>  AssignmentDetailScreen())),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      shape: BoxShape.circle,
                    ),
                    child:Image.asset('assets/icons/solar_document-outline.png', width: 24, ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(a['date']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 