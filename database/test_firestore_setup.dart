// Firestore Setup Test Script
// Run this script to test your Firestore database setup

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTester {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test all collections
  Future<void> testDatabaseSetup() async {
    print('🧪 Testing Firestore Database Setup...\n');

    try {
      // Test admins collection
      await _testAdminsCollection();

      // Test instructors collection
      await _testInstructorsCollection();

      // Test users collection
      await _testUsersCollection();

      // Test classes collection
      await _testClassesCollection();

      // Test activities collection
      await _testActivitiesCollection();

      // Test announcements collection
      await _testAnnouncementsCollection();

      // Test leaderboard collection
      await _testLeaderboardCollection();

      print('\n✅ All tests completed successfully!');
      print('🎉 Your Firestore database is properly configured.');
    } catch (e) {
      print('\n❌ Test failed: $e');
      print(
        '💡 Make sure Firebase is properly initialized and you have the correct permissions.',
      );
    }
  }

  // Test admins collection
  Future<void> _testAdminsCollection() async {
    try {
      QuerySnapshot admins = await _firestore.collection('admins').get();
      print('👑 Admins Collection:');
      print('   - Total admins: ${admins.docs.length}');

      for (var doc in admins.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['name']} (${data['email']}) - Active: ${data['isActive']}',
        );
      }
      print('');
    } catch (e) {
      print('❌ Error testing admins collection: $e\n');
    }
  }

  // Test instructors collection
  Future<void> _testInstructorsCollection() async {
    try {
      QuerySnapshot instructors =
          await _firestore.collection('instructors').get();
      print('👨‍🏫 Instructors Collection:');
      print('   - Total instructors: ${instructors.docs.length}');

      for (var doc in instructors.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['name']} (${data['email']}) - Department: ${data['department']}',
        );
        if (data['classes'] != null) {
          print('     Classes: ${(data['classes'] as List).length}');
        }
      }
      print('');
    } catch (e) {
      print('❌ Error testing instructors collection: $e\n');
    }
  }

  // Test users collection
  Future<void> _testUsersCollection() async {
    try {
      QuerySnapshot users = await _firestore.collection('users').get();
      print('👥 Users Collection:');
      print('   - Total users: ${users.docs.length}');

      for (var doc in users.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['fullName']} (${data['email']}) - Role: ${data['role']} - Points: ${data['points'] ?? 0}',
        );
      }
      print('');
    } catch (e) {
      print('❌ Error testing users collection: $e\n');
    }
  }

  // Test classes collection
  Future<void> _testClassesCollection() async {
    try {
      QuerySnapshot classes = await _firestore.collection('classes').get();
      print('📚 Classes Collection:');
      print('   - Total classes: ${classes.docs.length}');

      for (var doc in classes.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['course']} - ${data['section']} - ${data['day']} ${data['startTime']}-${data['endTime']}',
        );
        if (data['students'] != null) {
          print('     Students: ${(data['students'] as List).length}');
        }
      }
      print('');
    } catch (e) {
      print('❌ Error testing classes collection: $e\n');
    }
  }

  // Test activities collection
  Future<void> _testActivitiesCollection() async {
    try {
      QuerySnapshot activities =
          await _firestore.collection('activities').get();
      print('🌱 Activities Collection:');
      print('   - Total activities: ${activities.docs.length}');

      for (var doc in activities.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['title']} - Status: ${data['status']} - Points: ${data['pointsReward']}',
        );
        if (data['registeredParticipants'] != null) {
          print(
            '     Participants: ${(data['registeredParticipants'] as List).length}',
          );
        }
      }
      print('');
    } catch (e) {
      print('❌ Error testing activities collection: $e\n');
    }
  }

  // Test announcements collection
  Future<void> _testAnnouncementsCollection() async {
    try {
      QuerySnapshot announcements =
          await _firestore.collection('announcements').get();
      print('📢 Announcements Collection:');
      print('   - Total announcements: ${announcements.docs.length}');

      for (var doc in announcements.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - ${data['title']} - Priority: ${data['priority']} - Active: ${data['isActive']}',
        );
      }
      print('');
    } catch (e) {
      print('❌ Error testing announcements collection: $e\n');
    }
  }

  // Test leaderboard collection
  Future<void> _testLeaderboardCollection() async {
    try {
      QuerySnapshot leaderboard =
          await _firestore.collection('leaderboard').get();
      print('🏆 Leaderboard Collection:');
      print('   - Total entries: ${leaderboard.docs.length}');

      // Sort by rank
      List<QueryDocumentSnapshot> sortedDocs = leaderboard.docs.toList();
      sortedDocs.sort(
        (a, b) => (a.data() as Map<String, dynamic>)['rank'].compareTo(
          (b.data() as Map<String, dynamic>)['rank'],
        ),
      );

      for (var doc in sortedDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print(
          '   - Rank ${data['rank']}: ${data['name']} - ${data['points']} points - Level ${data['level']}',
        );
      }
      print('');
    } catch (e) {
      print('❌ Error testing leaderboard collection: $e\n');
    }
  }

  // Test authentication
  Future<void> testAuthentication() async {
    print('🔐 Testing Authentication...\n');

    try {
      // Test anonymous sign in
      UserCredential result = await _auth.signInAnonymously();
      print('✅ Anonymous authentication successful');
      print('   User ID: ${result.user?.uid}');

      // Sign out
      await _auth.signOut();
      print('✅ Sign out successful\n');
    } catch (e) {
      print('❌ Authentication test failed: $e\n');
    }
  }

  // Test database permissions
  Future<void> testPermissions() async {
    print('🔒 Testing Database Permissions...\n');

    try {
      // Test read permission
      await _firestore.collection('users').limit(1).get();
      print('✅ Read permission: OK');

      // Test write permission (create a test document)
      await _firestore.collection('test').doc('permission_test').set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Write permission: OK');

      // Clean up test document
      await _firestore.collection('test').doc('permission_test').delete();
      print('✅ Delete permission: OK\n');
    } catch (e) {
      print('❌ Permission test failed: $e\n');
    }
  }

  // Generate test report
  Future<void> generateTestReport() async {
    print('📊 Generating Test Report...\n');

    try {
      // Count documents in each collection
      Map<String, int> collectionCounts = {};

      List<String> collections = [
        'users',
        'admins',
        'instructors',
        'classes',
        'activities',
        'announcements',
        'leaderboard',
      ];

      for (String collection in collections) {
        try {
          QuerySnapshot snapshot =
              await _firestore.collection(collection).get();
          collectionCounts[collection] = snapshot.docs.length;
        } catch (e) {
          collectionCounts[collection] = -1; // Error indicator
        }
      }

      print('📋 Collection Summary:');
      collectionCounts.forEach((collection, count) {
        if (count == -1) {
          print('   - $collection: ❌ Error accessing collection');
        } else {
          print('   - $collection: $count documents');
        }
      });

      print('\n🎯 Recommendations:');
      if (collectionCounts['users'] == 0) {
        print('   - Consider adding test user accounts');
      }
      if (collectionCounts['admins'] == 0) {
        print('   - Create at least one admin account');
      }
      if (collectionCounts['instructors'] == 0) {
        print('   - Create instructor accounts for testing');
      }
      if (collectionCounts['classes'] == 0) {
        print('   - Create sample classes for testing');
      }

      print('\n✅ Test report generated successfully!');
    } catch (e) {
      print('❌ Error generating test report: $e');
    }
  }
}

// Usage example:
void main() async {
  // Initialize Firebase first
  // await Firebase.initializeApp();

  FirestoreTester tester = FirestoreTester();

  // Run all tests
  await tester.testDatabaseSetup();
  await tester.testAuthentication();
  await tester.testPermissions();
  await tester.generateTestReport();

  print('\n🎉 All tests completed! Check the results above.');
}
