class CloudinaryConfig {
  // Cloudinary credentials
  static const String cloudName = 'dddnu6i5q';
  static const String apiKey = '333337596671818';
  static const String apiSecret = 'UJKccyN0O_VjmG9QrEvsU_f9lxA';

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
