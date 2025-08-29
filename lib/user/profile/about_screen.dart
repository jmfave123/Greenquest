import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/image 297.png', width: 200,),
            
            const Text(
              'GreenQuest is a modern and user-friendly mobile app specifically developed to enhance learning in the NSTP (National Service Training Program) subject, with a strong focus on environmental awareness and action. Whether you’re completing environmental modules, participating in community cleanups, or tracking your eco-footprint — GreenQuest makes the experience interactive, educational, and impactful.\n\nWhy GreenQuest?\nGreenQuest empowers students to become environmentally conscious citizens. It supports NSTP learners in:\n• Understanding key environmental issues like climate change, pollution, and sustainability.\n• Participating in eco-friendly activities and community-based environmental initiatives.\n• Tracking progress in projects, tree planting, and more.\n• Accessing multimedia learning resources aligned with NSTP curriculum goals.\n\nTake the next step toward a greener future — with GreenQuest.',
              style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
} 