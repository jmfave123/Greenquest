import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudinary configuration for image uploads
/// Credentials are stored in .env file (never commit secrets to version control)
class CloudinaryConfig {
  // Cloudinary credentials from environment variables
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';

  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Default upload folder for your app
  static const String defaultFolder = 'greenquest';

  // Image transformation settings
  static const Map<String, dynamic> defaultTransformations = {
    'width': 800,
    'height': 600,
    'crop': 'scale',
    'quality': 'auto',
    'format': 'auto',
  };

  // Allowed image formats
  static const List<String> allowedFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  // Maximum file size in bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Validates that Cloudinary credentials are properly configured
  /// Throws an exception if credentials are missing or invalid
  static void validateConfiguration() {
    if (cloudName.isEmpty) {
      throw Exception(
        'CLOUDINARY_CLOUD_NAME is not configured. '
        'Please add it to your .env file.',
      );
    }
    if (apiKey.isEmpty) {
      throw Exception(
        'CLOUDINARY_API_KEY is not configured. '
        'Please add it to your .env file.',
      );
    }
    if (apiSecret.isEmpty) {
      throw Exception(
        'CLOUDINARY_API_SECRET is not configured. '
        'Please add it to your .env file.',
      );
    }
  }

  /// Check if config is properly set up (returns boolean instead of throwing)
  static bool get isConfigured {
    return cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }
}
