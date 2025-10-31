import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void _log(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}

/*
#Para sa pag send ug group notification dapat mag trigger mo ug tag registration. Like for example, Naa mo usertype consumer ug business
#each time ang user mo login ang user, eh register sya sa tag ug unsa sya nga usertype
# pag himo ug function na ug successful login ang user, eh grab iya usertype value daun eh store ug variable, sampol
# String userType = getUserTypeValue(); <--------- declare ni
# OneSignal.User.addTagWithKey("userType", userType); <------------ kani nga code inside sa function nimo nga successful login, mo register ni sya sa onesignal tags
*/

/// Helper class for OneSignal tag registration and Player ID management
class OneSignalHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get Player IDs for students in specific sections
  /// Returns list of OneSignal Player IDs for students who are subscribed
  static Future<List<String>> getPlayerIdsForSections({
    required List<String> sectionCodes,
    String? instructorId,
  }) async {
    try {
      final List<String> playerIds = [];

      // Query users collection for students in the target sections
      for (String sectionCode in sectionCodes) {
        Query query = _firestore
            .collection('users')
            .where('selectedSectionCode', isEqualTo: sectionCode);

        // Filter by instructor if provided
        if (instructorId != null && instructorId.isNotEmpty) {
          query = query.where('selectedInstructorId', isEqualTo: instructorId);
        }

        final snapshot = await query.get();

        for (var doc in snapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>?;
          final playerId = userData?['onesignalPlayerId']?.toString();

          // Only add if Player ID exists and is not empty
          if (playerId != null && playerId.isNotEmpty) {
            playerIds.add(playerId);
          }
        }
      }

      // Remove duplicates
      final uniquePlayerIds = playerIds.toSet().toList();
      _log(
        '📱 Found ${uniquePlayerIds.length} Player IDs for sections: $sectionCodes',
      );
      return uniquePlayerIds;
    } catch (e) {
      _log('❌ Error getting Player IDs for sections: $e');
      return [];
    }
  }

  /// Get Player ID for a specific user
  static Future<String?> getPlayerIdForUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      final playerId = userData?['onesignalPlayerId']?.toString();

      if (playerId != null && playerId.isNotEmpty) {
        return playerId;
      }

      return null;
    } catch (e) {
      _log('❌ Error getting Player ID for user $userId: $e');
      return null;
    }
  }

  /// Register OneSignal tags and store Player ID for students
  static Future<void> registerStudentTags({
    String? sectionCode,
    String? instructorId,
  }) async {
    // Skip OneSignal on web platform
    if (kIsWeb) {
      _log('⚠️ OneSignal: Skipping on web platform');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _log('❌ OneSignal: No user logged in');
        return;
      }

      // Wait a bit for OneSignal to be fully initialized
      await Future.delayed(const Duration(seconds: 2));

      // Check if Player ID exists (means user is subscribed)
      String? playerId;
      try {
        playerId = OneSignal.User.pushSubscription.id;
        if (playerId!.isEmpty) {
          _log(
            '⚠️ OneSignal: Player ID not available yet, waiting for subscription...',
          );
          // Wait a bit more for subscription
          await Future.delayed(const Duration(seconds: 1));
          playerId = OneSignal.User.pushSubscription.id;
        }

        // Register only essential tags: userId and userType
        Map<String, String> tags = {'userType': 'student', 'userId': user.uid};

        // Try to add tags
        try {
          OneSignal.User.addTags(tags);
          _log('✅ OneSignal: Added tags: $tags');
        } catch (e) {
          _log(
            '⚠️ OneSignal: Could not add tags (tag limit may be reached): $e',
          );
        }

        // Wait a moment for tags to sync
        await Future.delayed(const Duration(milliseconds: 500));

        // Get and store Player ID (recheck after waiting)
        try {
          final finalPlayerId = OneSignal.User.pushSubscription.id ?? playerId;
          if (finalPlayerId != null && finalPlayerId.isNotEmpty) {
            await _firestore.collection('users').doc(user.uid).update({
              'onesignalPlayerId': finalPlayerId,
              'onesignalTags': tags,
              'lastOneSignalUpdate': FieldValue.serverTimestamp(),
            });
            _log('✅ OneSignal: Stored Player ID: $finalPlayerId');
          } else {
            _log('⚠️ OneSignal: Player ID not available yet');
          }
        } catch (e) {
          _log('⚠️ OneSignal: Error getting Player ID: $e');
        }
      } catch (e) {
        _log('⚠️ OneSignal: Error accessing OneSignal SDK: $e');
      }
    } catch (e) {
      _log('❌ OneSignal: Error registering student tags: $e');
      // Don't throw - allow login to continue even if OneSignal fails
    }
  }

  /// Register OneSignal tags and store Player ID for instructors
  /// Removed - instructors don't need tags, only students
  static Future<void> registerInstructorTags() async {
    return;
  }

  /// Register OneSignal tags and store Player ID for admins
  /// Removed - admins don't need tags, only students
  static Future<void> registerAdminTags() async {
    // Skipped - not needed
    return;
  }
}

class NotifServices {
  static String get _baseUrl {
    if (kDebugMode) {
      return dotenv.env['VERCEL_BASE_URL_LOCAL'] ?? 'http://localhost:3000';
    }
    return dotenv.env['VERCEL_BASE_URL'] ??
        'https://greenquest-seven.vercel.app';
  }

  static Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _sendViaServer(Map<String, dynamic> payload) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null || idToken.isEmpty) {
        _log('❌ Push notification skipped: user is not authenticated');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-notification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _log('✅ Push notification request sent successfully');
      } else {
        _log(
          '❌ Push notification request failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      _log('❌ Exception sending push notification request: $e');
    }
  }

  static Future<void> sendGroupNotification({
    required String userType,
    required String heading,
    required String content,
    String? bigPicture,
  }) async {
    final payload = <String, dynamic>{
      'mode': 'group',
      'userType': userType,
      'heading': heading,
      'content': content,
      if (bigPicture != null && bigPicture.isNotEmpty) 'bigPicture': bigPicture,
    };

    await _sendViaServer(payload);
  }

  static Future<void> sendIndividualNotification({
    required String playerId,
    required String heading,
    required String content,
    String? bigPicture,
  }) async {
    final payload = <String, dynamic>{
      'mode': 'individual',
      'playerId': playerId,
      'heading': heading,
      'content': content,
      if (bigPicture != null && bigPicture.isNotEmpty) 'bigPicture': bigPicture,
    };

    await _sendViaServer(payload);
  }

  /// Send push notification to multiple Player IDs (batch)
  /// Use this when you have multiple player IDs from Firestore
  static Future<void> sendBatchNotification({
    required List<String> playerIds,
    required String heading,
    required String content,
    String? bigPicture,
    Map<String, dynamic>? additionalData,
  }) async {
    if (playerIds.isEmpty) {
      _log('⚠️ No player IDs provided, skipping push notification');
      return;
    }

    final payload = <String, dynamic>{
      'mode': 'batch',
      'playerIds': playerIds,
      'heading': heading,
      'content': content,
      if (bigPicture != null && bigPicture.isNotEmpty) 'bigPicture': bigPicture,
      if (additionalData != null) 'additionalData': additionalData,
    };

    await _sendViaServer(payload);
  }
}
 
 
/*
 
#userType: "business", sample rani, depende sa imo logic sa imong tag registration
await NotifServices.sendGroupNotification(
  userType: "business", // or "consumer" depende sa imo mga usertype nga na register sa onesignal tag
  heading: "Business Alert",
  content: "New updates available for business users.",
  // Optionally include an image URL:
  // bigPicture: "https://example.com/image.png",
);
 
 
 
#para sa pag solo notification eh store ang value ani sa database: OneSignal.User.pushSubscription.id (sa register for adding, sa each successful login for updating)
#para ug gusto mo mo notify sa usa ka user kuhaa ra na nga value sa iya data sa database, kadtung ge butangan sa OneSignal.User.pushSubscription.id
 
await NotifServices.sendIndividualNotification(
  playerId: "Value sa subscriptionID sa user na imo gusto eh notify", // Use the push subscription ID.
  heading: "Personal Alert",
  content: "Hello, this is a direct notification just for you.",
);
 
 
 */