import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your privacy matters. At GreenQuest, we are committed to protecting your personal data while helping you actively engage in environmental learning and NSTP-related activities with confidence and security.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 18),
            Text(
              '1. What We Collect',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'We only collect information that helps improve your experience and support your learning journey:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Name, and optional profile details',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  Text(
                    '• Activity participation logs (e.g., tree planting, clean-up drives)',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  Text(
                    '• Environmental quiz scores and progress tracking',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Text(
              '2. How Your Data Is Used',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'We use your information to:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Track and display your progress in NSTP environmental modules',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  Text(
                    '• Send reminders and motivational tips for community activities',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  Text(
                    '• Personalize learning resources and sustainability goals',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Text(
              '3. What We Don’t Do',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'We do not sell, rent, or share your personal information with advertisers or unauthorized third parties.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 18),
            Text(
              '4. Your Privacy Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'You have full control over your data. You can view, update, or delete your records and activity logs at any time within the app settings.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 18),
            Text(
              '5. Data Protection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Your data is stored securely using end-to-end encryption and industry-standard security practices to ensure confidentiality and safety.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 18),
            Text(
              '6. Need Help or Want to Delete Your Data?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Feel free to message us directly within the app or email us at ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SelectableText(
              'support@greenquest.app',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF34A853),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            Text(
              ' if you have any questions or wish to permanently delete your data.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
