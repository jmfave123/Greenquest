import 'package:flutter/material.dart';

class MaterialsDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? material;

  const MaterialsDetailScreen({Key? key, required this.material})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle null material case
    if (material == null || material!.isEmpty) {
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
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Material not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This material may have been removed or is no longer available',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
              child: _getMaterialImage(material!['topic']?.toString() ?? ''),
            ),
            const SizedBox(height: 18),
            Text(
              'Topic: ${material!['topic']?.toString() ?? 'No Topic'}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text(
              material!['title']?.toString() ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(
              material!['description']?.toString() ??
                  'No description available',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Instructor: ',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Flexible(
                  child: Text(
                    material!['instructorName']?.toString() ??
                        'Unknown Instructor',
                    style: const TextStyle(
                      color: Color(0xFF2886D7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Uploaded Date: ',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Text(
                  material!['createdAt']?.toString() ?? 'Unknown Date',
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
            if (material!['attachments'] != null &&
                (material!['attachments'] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ...((material!['attachments'] as List).map(
                (attachment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attachment.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2886D7),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  /// Get appropriate image based on material topic
  Widget _getMaterialImage(String topic) {
    // Default images based on topic
    String imagePath;
    double imageHeight = 200.0;

    if (topic.toLowerCase().contains('climate') ||
        topic.toLowerCase().contains('environment')) {
      imagePath = 'assets/images/image 328.png';
    } else if (topic.toLowerCase().contains('deforestation') ||
        topic.toLowerCase().contains('forest')) {
      imagePath = 'assets/images/engineering-supplies-blueprint 2.png';
    } else if (topic.toLowerCase().contains('renewable') ||
        topic.toLowerCase().contains('energy')) {
      imagePath = 'assets/images/image 328.png';
    } else {
      imagePath = 'assets/images/engineering-supplies-blueprint 2.png';
    }

    return Image.asset(
      imagePath,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: imageHeight,
          width: double.infinity,
          color: const Color(0xFF34A853).withOpacity(0.1),
          child: const Icon(
            Icons.library_books,
            size: 60,
            color: Color(0xFF34A853),
          ),
        );
      },
    );
  }
}
