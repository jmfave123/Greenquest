import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnlineStatusService {
  static final OnlineStatusService _instance = OnlineStatusService._internal();
  factory OnlineStatusService() => _instance;
  OnlineStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Timer? _lastSeenTimer;

  /// Initialize online status tracking
  void initialize() {
    _setOnlineStatus(true);

    // Set up periodic last seen updates
    _startLastSeenTimer();

    // Set up app lifecycle listener
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// Start periodic timer to update last seen
  void _startLastSeenTimer() {
    _lastSeenTimer?.cancel();
    _lastSeenTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isOnline) {
        updateLastSeen();
      }
    });
  }

  /// Set user's online status
  Future<void> _setOnlineStatus(bool online) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _isOnline = online;

      // Try to update in users collection first (with timeout)
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
              'isOnline': online,
              'lastSeen': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 2));
        return; // Success, exit early
      } catch (e) {
        print('Failed to update users collection: $e');
      }

      // If user doesn't exist in users collection, try instructors collection
      try {
        await _firestore
            .collection('instructors')
            .doc(user.uid)
            .update({
              'isOnline': online,
              'lastSeen': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 2));
        return; // Success, exit early
      } catch (e2) {
        print('Failed to update instructors collection: $e2');
      }

      // If not in instructors, try admins collection
      try {
        await _firestore
            .collection('admins')
            .doc(user.uid)
            .update({
              'isOnline': online,
              'lastSeen': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 2));
        return; // Success, exit early
      } catch (e3) {
        print('Failed to update admins collection: $e3');
      }

      // If user doesn't exist in any collection, create a basic entry in users
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
              'isOnline': online,
              'lastSeen': FieldValue.serverTimestamp(),
              'email': user.email,
              'displayName': user.displayName ?? 'User',
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 2));
      } catch (e4) {
        print('Failed to create user entry: $e4');
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Set user as online
  Future<void> setOnline() async {
    await _setOnlineStatus(true);
    _startLastSeenTimer();
  }

  /// Set user as offline
  Future<void> setOffline() async {
    _lastSeenTimer?.cancel();
    try {
      await _setOnlineStatus(false).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('OnlineStatusService.setOffline() timed out');
        },
      );
    } catch (e) {
      print('Error in setOffline: $e');
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Try to update in users collection first
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If user doesn't exist in users collection, try instructors collection
        try {
          await _firestore.collection('instructors').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } catch (e2) {
          // If not in instructors, try admins collection
          try {
            await _firestore.collection('admins').doc(user.uid).update({
              'lastSeen': FieldValue.serverTimestamp(),
            });
          } catch (e3) {
            // If user doesn't exist in any collection, create a basic entry in users
            await _firestore.collection('users').doc(user.uid).set({
              'lastSeen': FieldValue.serverTimestamp(),
              'email': user.email,
              'displayName': user.displayName ?? 'User',
            }, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }

  /// Cleanup when service is disposed
  void dispose() {
    _lastSeenTimer?.cancel();
    setOffline();
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final OnlineStatusService _service;

  _AppLifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _service.setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _service.setOffline();
        break;
      case AppLifecycleState.hidden:
        // Keep online when app is hidden but still running
        break;
    }
  }
}
