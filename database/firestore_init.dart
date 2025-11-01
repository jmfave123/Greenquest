// Firestore Database Initialization Script
// Run this script to set up default data in your Firestore database

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize default data
  Future<void> initializeDatabase() async {
    try {
      print('🚀 Initializing Firestore database...');

      // Create default admin
      await _createDefaultAdmin();

      // Create default instructor
      await _createDefaultInstructor();

      // Create sample classes
      await _createSampleClasses();

      // Create sample activities
      await _createSampleActivities();

      // Create sample announcements
      await _createSampleAnnouncements();

      print('✅ Database initialization completed successfully!');
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  // Create default admin user
  Future<void> _createDefaultAdmin() async {
    try {
      await _firestore.collection('admins').doc('admin_001').set({
        'name': 'System Admin',
        'email': 'admin@greenquest.com',
        'isActive': true,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'admin',
        'permissions': ['user_management', 'content_management', 'analytics'],
      });
      print('✅ Default admin created');
    } catch (e) {
      print('❌ Error creating admin: $e');
    }
  }

  // Create default instructor
  Future<void> _createDefaultInstructor() async {
    try {
      await _firestore.collection('instructors').doc('instructor_001').set({
        'name': 'Mia Castro',
        'email': 'miacastro@university.edu',
        'phone': '+639123456789',
        'department': 'NSTP Department',
        'isActive': true,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'classes': [
          {
            'id': '1704067200000',
            'section': 'BSIT 1A',
            'course': 'NSTP',
            'room': 'MSC01',
            'day': 'Monday',
            'startTime': '1:00 PM',
            'endTime': '2:30 PM',
            'instructorId': 'instructor_001',
            'createdAt': FieldValue.serverTimestamp(),
          },
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Default instructor created');
    } catch (e) {
      print('❌ Error creating instructor: $e');
    }
  }

  // Create sample classes
  Future<void> _createSampleClasses() async {
    try {
      await _firestore.collection('classes').doc('class_001').set({
        'section': 'BSIT 1A',
        'course': 'NSTP',
        'room': 'MSC01',
        'day': 'Monday',
        'startTime': '1:00 PM',
        'endTime': '2:30 PM',
        'instructorId': 'instructor_001',
        'instructorName': 'Mia Castro',
        'students': [
          {
            'userId': 'user_001',
            'name': 'Bryant Carlos',
            'email': 'bryantcarlos@gmail.com',
            'status': 'active',
            'joinedAt': FieldValue.serverTimestamp(),
          },
          {
            'userId': 'user_002',
            'name': 'Clarence Angelo Yu',
            'email': 'clarenceangelyu@gmail.com',
            'status': 'active',
            'joinedAt': FieldValue.serverTimestamp(),
          },
          {
            'userId': 'user_003',
            'name': 'Kristene Melody Aves',
            'email': 'kristeneaves@gmail.com',
            'status': 'active',
            'joinedAt': FieldValue.serverTimestamp(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Sample classes created');
    } catch (e) {
      print('❌ Error creating classes: $e');
    }
  }

  // Create sample activities
  Future<void> _createSampleActivities() async {
    try {
      await _firestore.collection('activities').doc('activity_001').set({
        'title': 'Tree Planting in Barangay Carmen',
        'description':
            'Community tree planting activity to promote environmental awareness',
        'instructorId': 'instructor_001',
        'classId': 'class_001',
        'date': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
        'location': {
          'name': 'Barangay Carmen',
          'latitude': 8.4799,
          'longitude': 124.6439,
          'address': 'Cagayan de Oro, Philippines',
        },
        'maxParticipants': 30,
        'registeredParticipants': [
          {
            'userId': 'user_001',
            'name': 'Bryant Carlos',
            'registeredAt': FieldValue.serverTimestamp(),
          },
        ],
        'status': 'scheduled',
        'pointsReward': 100,
        'requirements': [
          'Bring water bottle',
          'Wear comfortable clothes',
          'Bring gardening gloves',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Sample activities created');
    } catch (e) {
      print('❌ Error creating activities: $e');
    }
  }

  // Create sample announcements
  Future<void> _createSampleAnnouncements() async {
    try {
      await _firestore.collection('announcements').doc('announcement_001').set({
        'title': 'Tree Planting Activity Next Week',
        'content':
            'We will have a tree planting activity next week in Barangay Carmen. Please prepare your materials and be ready at 8:00 AM.',
        'instructorId': 'instructor_001',
        'classId': 'class_001',
        'priority': 'high',
        'targetAudience': 'students',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
      });
      print('✅ Sample announcements created');
    } catch (e) {
      print('❌ Error creating announcements: $e');
    }
  }

  // Create test user accounts (for development)
  Future<void> createTestUsers() async {
    try {
      print('👥 Creating test user accounts...');

      // Test student 1
      await _firestore.collection('users').doc('user_001').set({
        'fullName': 'Bryant Carlos',
        'phoneNumber': '+639123456789',
        'email': 'bryantcarlos@gmail.com',
        'idNumber': '2024-001234',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': true,
        'points': 150,
        'level': 3,
        'badges': ['eco_warrior'],
        'totalTreesPlanted': 3,
        'totalPointsEarned': 150,
      });

      // Test student 2
      await _firestore.collection('users').doc('user_002').set({
        'fullName': 'Clarence Angelo Yu',
        'phoneNumber': '+639123456790',
        'email': 'clarenceangelyu@gmail.com',
        'idNumber': '2024-001235',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': true,
        'points': 200,
        'level': 4,
        'badges': ['eco_warrior', 'tree_planter'],
        'totalTreesPlanted': 5,
        'totalPointsEarned': 200,
      });

      // Test student 3
      await _firestore.collection('users').doc('user_003').set({
        'fullName': 'Kristene Melody Aves',
        'phoneNumber': '+639123456791',
        'email': 'kristeneaves@gmail.com',
        'idNumber': '2024-001236',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': true,
        'points': 100,
        'level': 2,
        'badges': ['eco_warrior'],
        'totalTreesPlanted': 2,
        'totalPointsEarned': 100,
      });

      print('✅ Test users created');
    } catch (e) {
      print('❌ Error creating test users: $e');
    }
  }

  // Initialize leaderboard
  Future<void> initializeLeaderboard() async {
    try {
      print('🏆 Initializing leaderboard...');

      // Get all users and create leaderboard entries
      QuerySnapshot users = await _firestore.collection('users').get();

      List<Map<String, dynamic>> leaderboardData = [];

      for (var doc in users.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        leaderboardData.add({
          'userId': doc.id,
          'name': userData['fullName'],
          'email': userData['email'],
          'points': userData['points'] ?? 0,
          'level': userData['level'] ?? 1,
          'totalTreesPlanted': userData['totalTreesPlanted'] ?? 0,
          'badges': userData['badges'] ?? [],
          'rank': 0, // Will be calculated
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Sort by points and assign ranks
      leaderboardData.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      for (int i = 0; i < leaderboardData.length; i++) {
        leaderboardData[i]['rank'] = i + 1;
        await _firestore
            .collection('leaderboard')
            .doc(leaderboardData[i]['userId'])
            .set(leaderboardData[i]);
      }

      print('✅ Leaderboard initialized');
    } catch (e) {
      print('❌ Error initializing leaderboard: $e');
    }
  }
}

// Usage example:
void main() async {
  // Initialize Firebase first
  // await Firebase.initializeApp();

  FirestoreInitializer initializer = FirestoreInitializer();

  // Initialize database
  await initializer.initializeDatabase();

  // Create test users
  await initializer.createTestUsers();

  // Initialize leaderboard
  await initializer.initializeLeaderboard();

  print('🎉 All done! Your Firestore database is ready.');
}
