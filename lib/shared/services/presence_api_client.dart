import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PresenceApiClient {
  static String get _baseUrl {
    if (kDebugMode) {
      return dotenv.env['VERCEL_BASE_URL_LOCAL'] ?? 'http://localhost:3000';
    }
    return dotenv.env['VERCEL_BASE_URL'] ??
        'https://greenquest-seven.vercel.app';
  }

  static void _log(Object? message) {
    if (kDebugMode) {
      debugPrint('$message');
    }
  }

  static Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sendHeartbeat() async {
    return _sendAction('heartbeat');
  }

  static Future<bool> sendOffline() async {
    return _sendAction('offline');
  }

  static Future<bool> _sendAction(String action) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null || idToken.isEmpty) {
        _log('Presence API skipped: user is not authenticated');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/presence'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'action': action}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return true;
      }

      _log('Presence API failed (${response.statusCode}): ${response.body}');
      return false;
    } on TimeoutException {
      _log('Presence API timeout for action: $action');
      return false;
    } catch (e) {
      _log('Presence API exception for action $action: $e');
      return false;
    }
  }
}
