import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;
import 'notify_service.dart';

/// Service for managing in-app notifications
/// Supports individual, section-based, and broadcast notifications
class InAppNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // CREATE NOTIFICATIONS
  // ============================================

  /// Create a notification for specific sections
  /// Use this when an instructor creates an assignment, activity, quiz, PIT, or material
  static Future<bool> createSectionNotification({
    required String type, // 'assignment', 'activity', 'quiz', 'pit', 'material'
    required String instructorId,
    required String instructorName,
    required String itemId, // ID of the actual item (assignment, quiz, etc.)
    required String title,
    required List<String> targetSections, // e.g., ['BSIT-2A', 'BSIT-2B']
    String? description,
    Map<String, dynamic>? metadata, // e.g., dueDate, points, period
  }) async {
    try {
      dev.log('📢 Creating section notification for: $type');

      final notificationData = {
        'type': type,
        'title': title,
        'description': description ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'itemId': itemId,
        'targetType': 'section',
        'targetSections': targetSections,
        'targetUsers': [], // Empty for section notifications
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'metadata': metadata ?? {},
        'readBy': [], // Track who has read this notification
      };

      final notificationDoc = await _firestore
          .collection('notifications')
          .add(notificationData);
      final notificationId = notificationDoc.id;

      dev.log('✅ Section notification created successfully');

      // Send push notifications to students in target sections
      try {
        final playerIds = await OneSignalHelper.getPlayerIdsForSections(
          sectionCodes: targetSections,
          instructorId: instructorId,
        );

        if (playerIds.isNotEmpty) {
          // Build notification heading and content
          final heading = _getNotificationHeading(type, instructorName);
          final content = title;

          // Extract image URL from metadata for announcements
          String? imageUrl;
          if (type.toLowerCase() == 'announcement' &&
              metadata != null &&
              metadata.containsKey('imageUrl')) {
            imageUrl = metadata['imageUrl']?.toString();
            if (imageUrl != null && imageUrl.isNotEmpty) {
              // Convert HTTP to HTTPS (required by OneSignal)
              if (imageUrl.startsWith('http://')) {
                imageUrl = imageUrl.replaceFirst('http://', 'https://');
              }
              dev.log('📷 Announcement image found: $imageUrl');
            }
          }

          // Send batch push notification
          await NotifServices.sendBatchNotification(
            playerIds: playerIds,
            heading: heading,
            content: content,
            bigPicture: imageUrl,
            additionalData: {
              'type': type,
              'itemId': itemId,
              'instructorId': instructorId,
              'notificationId': notificationId,
            },
          );

          dev.log('📱 Push notification sent to ${playerIds.length} students');
        } else {
          dev.log('⚠️ No Player IDs found for sections: $targetSections');
        }
      } catch (e) {
        dev.log('❌ Error sending push notification: $e');
        // Don't throw - in-app notification was already created
      }

      return true;
    } catch (e) {
      dev.log('❌ Error creating section notification: $e');
      return false;
    }
  }

  /// Create a notification for specific users
  /// Use this for direct messages or personal notifications
  static Future<bool> createIndividualNotification({
    required String type,
    required String instructorId,
    required String instructorName,
    required String itemId,
    required String title,
    required List<String> targetUserIds,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      dev.log('📢 Creating individual notification for: $type');

      final notificationData = {
        'type': type,
        'title': title,
        'description': description ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'itemId': itemId,
        'targetType': 'individual',
        'targetUsers': targetUserIds,
        'targetSections': [], // Empty for individual notifications
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'metadata': metadata ?? {},
        'readBy': [],
      };

      final notificationDoc = await _firestore
          .collection('notifications')
          .add(notificationData);
      final notificationId = notificationDoc.id;

      dev.log('✅ Individual notification created successfully');

      // Send push notification to target users
      try {
        final List<String> playerIds = [];

        for (String userId in targetUserIds) {
          final playerId = await OneSignalHelper.getPlayerIdForUser(userId);
          if (playerId != null && playerId.isNotEmpty) {
            playerIds.add(playerId);
          }
        }

        if (playerIds.isNotEmpty) {
          // Build notification heading and content
          final heading = _getNotificationHeading(type, instructorName);
          final content = title;

          // Send batch push notification
          await NotifServices.sendBatchNotification(
            playerIds: playerIds,
            heading: heading,
            content: content,
            additionalData: {
              'type': type,
              'itemId': itemId,
              'instructorId': instructorId,
              'notificationId': notificationId,
            },
          );

          dev.log('📱 Push notification sent to ${playerIds.length} users');
        } else {
          dev.log('⚠️ No Player IDs found for target users');
        }
      } catch (e) {
        dev.log('❌ Error sending push notification: $e');
        // Don't throw - in-app notification was already created
      }

      return true;
    } catch (e) {
      dev.log('❌ Error creating individual notification: $e');
      return false;
    }
  }

  /// Create a notification for all enrolled students
  /// Use this for general announcements or important updates
  static Future<bool> createBroadcastNotification({
    required String type,
    required String instructorId,
    required String instructorName,
    required String itemId,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      dev.log('📢 Creating broadcast notification for: $type');

      final notificationData = {
        'type': type,
        'title': title,
        'description': description ?? '',
        'instructorId': instructorId,
        'instructorName': instructorName,
        'itemId': itemId,
        'targetType': 'all',
        'targetUsers': [],
        'targetSections': [],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'metadata': metadata ?? {},
        'readBy': [],
      };

      await _firestore.collection('notifications').add(notificationData);

      dev.log('✅ Broadcast notification created successfully');
      return true;
    } catch (e) {
      dev.log('❌ Error creating broadcast notification: $e');
      return false;
    }
  }

  // ============================================
  // READ NOTIFICATIONS
  // ============================================

  /// Get notifications for a specific student
  /// Filters based on their enrolled section and user ID
  static Future<List<Map<String, dynamic>>> getStudentNotifications({
    int? limit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log('❌ User not authenticated');
        return [];
      }

      // Get student's enrolled section
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        dev.log('❌ User document not found');
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userSection = userData['selectedSectionCode']?.toString() ?? '';
      final userId = user.uid;

      dev.log('📬 Fetching notifications for user: $userId');
      dev.log('📬 User section: $userSection');

      // Build the query
      Query query = _firestore
          .collection('notifications')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final notifications = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final targetType = data['targetType']?.toString() ?? '';

        // Filter based on target type
        bool shouldInclude = false;

        if (targetType == 'all') {
          // Broadcast: show to everyone
          shouldInclude = true;
        } else if (targetType == 'section') {
          // Section-based: check if user's section is in targetSections
          final targetSections = List<String>.from(
            data['targetSections'] ?? [],
          );
          shouldInclude = targetSections.contains(userSection);
        } else if (targetType == 'individual') {
          // Individual: check if user's ID is in targetUsers
          final targetUsers = List<String>.from(data['targetUsers'] ?? []);
          shouldInclude = targetUsers.contains(userId);
        }

        if (shouldInclude) {
          notifications.add({'id': doc.id, ...data});
        }
      }

      dev.log('✅ Found ${notifications.length} notifications for user');
      return notifications;
    } catch (e) {
      dev.log('❌ Error getting student notifications: $e');
      return [];
    }
  }

  /// Get notifications for a specific instructor
  /// Shows all notifications created by that instructor
  static Future<List<Map<String, dynamic>>> getInstructorNotifications({
    String? instructorId,
    int? limit,
  }) async {
    try {
      final currentInstructorId = instructorId ?? _auth.currentUser?.uid;
      if (currentInstructorId == null) {
        dev.log('❌ Instructor ID not provided');
        return [];
      }

      dev.log('📬 Fetching notifications for instructor: $currentInstructorId');

      // Build the query
      Query query = _firestore
          .collection('notifications')
          .where('instructorId', isEqualTo: currentInstructorId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final notifications = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        notifications.add({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      dev.log('✅ Found ${notifications.length} notifications for instructor');
      return notifications;
    } catch (e) {
      dev.log('❌ Error getting instructor notifications: $e');
      return [];
    }
  }

  // ============================================
  // MARK AS READ
  // ============================================

  /// Mark a notification as read by a specific user
  static Future<bool> markAsRead({
    required String notificationId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) {
        dev.log('❌ User ID not provided');
        return false;
      }

      dev.log(
        '📖 Marking notification as read: $notificationId by user: $currentUserId',
      );

      // Get current notification data
      final notificationDoc =
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .get();

      if (!notificationDoc.exists) {
        dev.log('❌ Notification not found');
        return false;
      }

      final data = notificationDoc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);

      // Add user to readBy if not already present
      if (!readBy.contains(currentUserId)) {
        readBy.add(currentUserId);
        await _firestore.collection('notifications').doc(notificationId).update(
          {'readBy': readBy},
        );
      }

      dev.log('✅ Notification marked as read');
      return true;
    } catch (e) {
      dev.log('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Check if a notification has been read by a specific user
  static Future<bool> isNotificationRead({
    required String notificationId,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final notificationDoc =
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .get();

      if (!notificationDoc.exists) return false;

      final data = notificationDoc.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);

      return readBy.contains(currentUserId);
    } catch (e) {
      dev.log('❌ Error checking if notification is read: $e');
      return false;
    }
  }

  // ============================================
  // DELETE NOTIFICATIONS
  // ============================================

  /// Delete a notification (soft delete by setting status to inactive)
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      dev.log('🗑️ Deleting notification: $notificationId');

      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'inactive',
      });

      dev.log('✅ Notification deleted successfully');
      return true;
    } catch (e) {
      dev.log('❌ Error deleting notification: $e');
      return false;
    }
  }

  // ============================================
  // REAL-TIME STREAMS
  // ============================================

  /// Get real-time stream of notifications for students
  static Stream<List<Map<String, dynamic>>> getStudentNotificationsStream({
    int? limit,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log('❌ User not authenticated');
        return Stream.value([]);
      }

      // For streaming, we need to filter on the client side after fetching
      return _firestore
          .collection('notifications')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            // Get user's section
            final userDoc =
                await _firestore.collection('users').doc(user.uid).get();
            final userData = userDoc.data() ?? {};
            final userSection =
                userData['selectedSectionCode']?.toString() ?? '';
            final userId = user.uid;

            final notifications = <Map<String, dynamic>>[];

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final targetType = data['targetType']?.toString() ?? '';

              bool shouldInclude = false;

              if (targetType == 'all') {
                shouldInclude = true;
              } else if (targetType == 'section') {
                final targetSections = List<String>.from(
                  data['targetSections'] ?? [],
                );
                shouldInclude = targetSections.contains(userSection);
              } else if (targetType == 'individual') {
                final targetUsers = List<String>.from(
                  data['targetUsers'] ?? [],
                );
                shouldInclude = targetUsers.contains(userId);
              }

              if (shouldInclude) {
                notifications.add({'id': doc.id, ...data});
              }
            }

            return notifications;
          });
    } catch (e) {
      dev.log('❌ Error creating notifications stream: $e');
      return Stream.value([]);
    }
  }

  /// Get unread count for current user
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getStudentNotifications();
      final user = _auth.currentUser;
      if (user == null) return 0;

      int unreadCount = 0;

      for (var notification in notifications) {
        final readBy = List<String>.from(notification['readBy'] ?? []);
        if (!readBy.contains(user.uid)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      dev.log('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get notification heading based on type
  static String _getNotificationHeading(String type, String instructorName) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return 'New Assignment from $instructorName';
      case 'activity':
        return 'New Activity from $instructorName';
      case 'quiz':
        return 'New Quiz from $instructorName';
      case 'pit':
        return 'New PIT from $instructorName';
      case 'material':
        return 'New Material from $instructorName';
      case 'announcement':
        return 'New Announcement from $instructorName';
      case 'graded':
        return 'Your work has been graded';
      default:
        return 'New Notification from $instructorName';
    }
  }
}
