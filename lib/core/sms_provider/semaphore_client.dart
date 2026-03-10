import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Semaphore OTP client.
///
/// All SMS sending and OTP verification is handled server-side through
/// Vercel serverless functions — the Semaphore API key never touches the client.
///
/// Flow:
///   sendOtp()   → POST /api/send-otp   (server generates OTP, calls Semaphore, stores hash in Firestore)
///   verifyOtp() → POST /api/verify-otp (server compares hash, sets isPhoneVerified: true)
class SemaphoreClient {
  static String get _baseUrl {
    if (kDebugMode) {
      return dotenv.env['VERCEL_BASE_URL_LOCAL'] ?? 'http://localhost:3000';
    }
    return dotenv.env['VERCEL_BASE_URL'] ??
        'https://greenquest-seven.vercel.app';
  }

  /// Format phone number to E.164 format for display purposes.
  /// Accepts: 09123456789, 9123456789, +639123456789
  String formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+63')) return phone;
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (!phone.startsWith('63')) phone = '63$phone';
    return '+$phone';
  }

  /// Validate phone number format (Philippines mobile numbers only).
  bool isValidPhoneNumber(String phone) {
    final formatted = formatPhoneNumber(phone);
    return RegExp(r'^\+63[9]\d{9}$').hasMatch(formatted);
  }

  /// Get a fresh Firebase ID token to authenticate server requests.
  Future<String?> _getIdToken() async {
    try {
      // forceRefresh: true ensures token is valid even after long idle
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      return null;
    }
  }

  /// Request an OTP to be sent to the instructor's registered phone number.
  ///
  /// The server fetches the phone number from Firestore using the auth token,
  /// generates the OTP, and sends the SMS via Semaphore.
  ///
  /// Returns:
  ///   { 'success': true }  on success
  ///   { 'success': false, 'error': String }  on failure
  Future<Map<String, dynamic>> sendOtp() async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {
          'success': false,
          'error': 'User not authenticated. Please login again.',
        };
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/send-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully.',
        };
      }

      return {
        'success': false,
        'error': data['error'] ?? 'Failed to send OTP. Please try again.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please check your connection.',
      };
    } catch (e) {
      return {'success': false, 'error': _getFriendlyError(e.toString())};
    }
  }

  /// Verify the 6-digit OTP code entered by the instructor.
  ///
  /// The server compares the submitted code against the stored hash in Firestore.
  /// On success, the server sets isPhoneVerified: true — the client does not write
  /// to Firestore directly.
  ///
  /// Returns:
  ///   { 'success': true }  on success
  ///   { 'success': false, 'error': String }  on failure
  Future<Map<String, dynamic>> verifyOtp(String code) async {
    if (code.isEmpty || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return {'success': false, 'error': 'Please enter a valid 6-digit code.'};
    }

    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        return {
          'success': false,
          'error': 'User not authenticated. Please login again.',
        };
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      }

      return {
        'success': false,
        'error': data['error'] ?? 'Invalid OTP. Please try again.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please check your connection.',
      };
    } catch (e) {
      return {'success': false, 'error': _getFriendlyError(e.toString())};
    }
  }

  String _getFriendlyError(String error) {
    if (error.contains('SocketException') ||
        error.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error.contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    return 'An error occurred. Please try again.';
  }
}
