class CloudinaryConfig {
  // Cloudinary credentials
  static const String cloudName = 'dddnu6i5q';
  static const String apiKey = 'b4b8fd4bdf5e0c8dcd995779ef241b';
  static const String apiSecret = 'e6j1Ke-3pxu2FuFcIr7AEAQDZnM';

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

  // Check if config is properly set up
  static bool get isConfigured {
    return cloudName != 'your_cloud_name_here' &&
        apiKey != 'your_api_key_here' &&
        apiSecret != 'your_api_secret_here' &&
        cloudName.isNotEmpty &&
        apiKey.isNotEmpty &&
        apiSecret.isNotEmpty;
  }
}
