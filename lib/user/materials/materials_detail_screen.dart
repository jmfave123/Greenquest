import 'package:flutter/material.dart';

class MaterialsDetailScreen extends StatelessWidget {
  const MaterialsDetailScreen({Key? key}) : super(key: key);

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
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/image 328.png', height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 18),
            const Text('Lesson: Introduction to Environmental Science', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 18),
            const Text('Climate Change and Its Impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 16),
            const Text('Explore how rising global temperatures, greenhouse gas emissions, and environmental degradation are altering ecosystems. Thermoregulation, biodiversity, and shaping the future of human and non-human life on Earth. This lesson tackles the biological, ecological, and evolutionary consequences of climate change, offering learners a foundational understanding of one of the most urgent challenges of our time.\n\nThe lesson will cover: climate change, biodiversity & endangered species, short-and-long-term effects of climate change. From melting glaciers and rising sea levels to shifting habitats and endangered species, this lesson empowers learners to recognize biological responses to a warming planet and inspires informed action.', style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6)),
            const SizedBox(height: 18),
            Row(
              children: const [
                Text('Source: ', style: TextStyle(color: Colors.black54, fontSize: 13)),
                Flexible(
                  child: Text('www.climatekids.nasa.gov/lesson/cc-impact', style: TextStyle(color: Color(0xFF2886D7), fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Uploaded Date: 03/01/2024', style: TextStyle(color: Colors.black38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
} 