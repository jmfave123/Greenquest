import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'topic_model.dart';

class TopicController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list of topics
  final RxList<Topic> topics = <Topic>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTopics();
  }

  /// Load all topics for the current instructor
  Future<void> loadTopics() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      print('🔍 Loading topics for instructor: ${user.uid}');

      final querySnapshot =
          await _firestore
              .collection('topics')
              .where('instructorId', isEqualTo: user.uid)
              .get();

      topics.value =
          querySnapshot.docs.map((doc) => Topic.fromFirestore(doc)).toList();

      print('✅ Loaded ${topics.length} topics for instructor');
      for (var topic in topics) {
        print('   - ${topic.topic}');
      }
    } catch (e) {
      print('❌ Error loading topics: $e');
      topics.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new topic
  Future<Topic?> createTopic({required String topicName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      // Create new topic document
      final docRef = _firestore.collection('topics').doc();

      final newTopic = Topic(
        id: docRef.id,
        topic: topicName,
        instructorId: user.uid,
        createdAt: DateTime.now(),
      );

      await docRef.set(newTopic.toMap());

      // Add to local list
      topics.add(newTopic);

      print('✅ Topic created: ${newTopic.topic}');
      return newTopic;
    } catch (e) {
      print('❌ Error creating topic: $e');
      return null;
    }
  }

  /// Get topic by ID
  Topic? getTopicById(String? topicId) {
    if (topicId == null || topicId.isEmpty) return null;
    try {
      return topics.firstWhere((topic) => topic.id == topicId);
    } catch (e) {
      return null;
    }
  }

  /// Check if topic name already exists
  bool topicExists(String topicName) {
    return topics.any(
      (topic) => topic.topic.toLowerCase() == topicName.toLowerCase(),
    );
  }
}
