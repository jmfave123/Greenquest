import 'dart:convert';
import 'package:http/http.dart' as http;

/// SMS Chef API Client for sending and verifying OTP
///
/// API Documentation: https://www.cloud.smschef.com/api/send/otp
///
/// TODO: Replace the placeholder values below with your actual credentials:
/// - SMS_CHEF_API_SECRET: From SMS Chef Dashboard → Tools → API Keys
/// - SMS_CHEF_DEVICE_ID: From SMS Chef Dashboard → Your Devices
class SmsChefClient {
  // Hardcoded SMS Chef credentials
  // TODO: Replace with your actual credentials
  static const String SMS_CHEF_API_SECRET =
      'fa116d0ca1855d511a0b7911a8f74f901510673d';
  static const String SMS_CHEF_DEVICE_ID = '013ed9ec7b99365f';

  // API Configuration
  static const String baseUrl = 'https://www.cloud.smschef.com/api';
  static const String sendOtpEndpoint = '$baseUrl/send/otp';
  static const String verifyOtpEndpoint = '$baseUrl/get/otp';

  // SMS Configuration
  static const String messageTemplate = 'Your OTP for GreenQuest is {{otp}}';
  static const String countryCode = '+63'; // Philippines
  static const int simSlot = 2;
  static const int otpExpirationSeconds = 300; // 5 minutes
  static const int resendCooldownSeconds = 60; // 1 minute

  // Track last OTP send time for cooldown
  DateTime? _lastOtpSentTime;

  /// Format phone number to E.164 format
  /// Accepts: 09123456789, 9123456789, +639123456789
  /// Returns: +639123456789
  String formatPhoneNumber(String phone) {
    // Remove all spaces, dashes, and other characters
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If already in E.164 format
    if (phone.startsWith('+63')) {
      return phone;
    }

    // If starts with 0, remove it (e.g., 09123456789 -> 9123456789)
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    // If doesn't start with 63, add country code
    if (!phone.startsWith('63')) {
      phone = '63$phone';
    }

    // Add + prefix
    return '+$phone';
  }

  /// Validate phone number format (Philippines)
  /// Accepts E.164 format: +639123456789
  bool isValidPhoneNumber(String phone) {
    final formatted = formatPhoneNumber(phone);
    // Philippines mobile numbers: +63 followed by 9 or 10 digits
    final pattern = RegExp(r'^\+63[9]\d{9}$');
    return pattern.hasMatch(formatted);
  }

  /// Check if resend is allowed (cooldown check)
  bool canResendOtp() {
    if (_lastOtpSentTime == null) return true;

    final timeSinceLastSend = DateTime.now().difference(_lastOtpSentTime!);
    return timeSinceLastSend.inSeconds >= resendCooldownSeconds;
  }

  /// Get remaining cooldown seconds
  int getRemainingCooldownSeconds() {
    if (_lastOtpSentTime == null) return 0;

    final timeSinceLastSend = DateTime.now().difference(_lastOtpSentTime!);
    final remaining = resendCooldownSeconds - timeSinceLastSend.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Send OTP via SMS using SMS Chef API
  ///
  /// [phone] - Phone number (will be formatted to E.164)
  ///
  /// Returns a map with:
  /// - success: bool
  /// - message: String
  /// - data: Map containing phone, message, messageId, otp (on success)
  /// - error: String (on failure)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      // Validate credentials
      if (SMS_CHEF_API_SECRET == 'YOUR_SMS_CHEF_API_SECRET_HERE' ||
          SMS_CHEF_DEVICE_ID == 'YOUR_SMS_CHEF_DEVICE_ID_HERE') {
        return {
          'success': false,
          'error':
              'SMS Chef credentials not configured. Please set SMS_CHEF_API_SECRET and SMS_CHEF_DEVICE_ID.',
        };
      }

      // Check cooldown
      if (!canResendOtp()) {
        final remaining = getRemainingCooldownSeconds();
        return {
          'success': false,
          'error':
              'Please wait $remaining seconds before requesting another OTP.',
        };
      }

      // Format phone number
      final formattedPhone = formatPhoneNumber(phone);

      // Validate phone number
      if (!isValidPhoneNumber(formattedPhone)) {
        return {
          'success': false,
          'error':
              'Invalid phone number. Please enter a valid Philippines mobile number (e.g., 09123456789).',
        };
      }

      // Create multipart request using http package
      final uri = Uri.parse(sendOtpEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['secret'] = SMS_CHEF_API_SECRET;
      request.fields['type'] = 'sms';
      request.fields['message'] = messageTemplate;
      request.fields['phone'] = formattedPhone;
      request.fields['expire'] = otpExpirationSeconds.toString();
      request.fields['mode'] = 'devices';
      request.fields['device'] = SMS_CHEF_DEVICE_ID;
      request.fields['sim'] = simSlot.toString();

      // Set headers
      request.headers.addAll({'Accept': 'application/json'});

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      // Read response
      final response = await http.Response.fromStream(streamedResponse);

      // Update last sent time
      _lastOtpSentTime = DateTime.now();

      // Check response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 200) {
          return {
            'success': true,
            'message': data['message'] ?? 'OTP sent successfully!',
            'data': data['data'],
            'phone': formattedPhone,
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to send OTP. Please try again.',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to send OTP. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': _getUserFriendlyError(e.toString())};
    }
  }

  /// Verify OTP using SMS Chef API
  ///
  /// [otp] - OTP code provided by user
  ///
  /// Returns a map with:
  /// - success: bool
  /// - message: String
  /// - error: String (on failure)
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    try {
      // Validate credentials
      if (SMS_CHEF_API_SECRET == 'YOUR_SMS_CHEF_API_SECRET_HERE') {
        return {
          'success': false,
          'error': 'SMS Chef credentials not configured.',
        };
      }

      // Validate OTP format (should be numeric)
      if (otp.isEmpty || !RegExp(r'^\d+$').hasMatch(otp)) {
        return {
          'success': false,
          'error': 'Invalid OTP format. Please enter a valid OTP code.',
        };
      }

      // Build URL with query parameters manually to ensure HTTPS
      final uri = Uri.parse(
        verifyOtpEndpoint,
      ).replace(queryParameters: {'secret': SMS_CHEF_API_SECRET, 'otp': otp});

      // Create HTTP client with proper configuration
      final client = http.Client();

      try {
        // Send GET request with query parameters using http package
        final response = await client
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'GreenQuest/1.0',
              },
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Request timed out');
              },
            );

        // Check response
        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            if (data['status'] == 200) {
              return {
                'success': true,
                'message': data['message'] ?? 'OTP verified successfully!',
              };
            } else {
              return {
                'success': false,
                'error':
                    data['message'] ??
                    'Invalid OTP. Please check and try again.',
              };
            }
          } catch (e) {
            return {
              'success': false,
              'error': 'Invalid response from server. Please try again.',
            };
          }
        } else {
          return {
            'success': false,
            'error':
                'Failed to verify OTP. Status code: ${response.statusCode}',
          };
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Handle specific error types
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timed out')) {
        return {
          'success': false,
          'error':
              'Request timed out. Please check your connection and try again.',
        };
      }

      // Handle ClientException (network/CORS errors)
      if (e.toString().contains('ClientException') ||
          e.toString().contains('Failed to fetch')) {
        return {
          'success': false,
          'error':
              'Network error. Please check your internet connection. If the problem persists, the server may be temporarily unavailable.',
        };
      }

      return {'success': false, 'error': _getUserFriendlyError(e.toString())};
    }
  }

  /// Get user-friendly error message
  String _getUserFriendlyError(String error) {
    if (error.contains('SocketException') ||
        error.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error.contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (error.contains('FormatException')) {
      return 'Invalid response from server. Please try again later.';
    }
    return 'An error occurred. Please try again.';
  }
}
