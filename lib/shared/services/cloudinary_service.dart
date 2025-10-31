import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadResponse {
  final String publicId;
  final String secureUrl;
  final String url;
  final int bytes;
  final String format;
  final int width;
  final int height;

  CloudinaryUploadResponse({
    required this.publicId,
    required this.secureUrl,
    required this.url,
    required this.bytes,
    required this.format,
    required this.width,
    required this.height,
  });

  factory CloudinaryUploadResponse.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResponse(
      publicId: json['public_id'] ?? '',
      secureUrl: json['secure_url'] ?? '',
      url: json['url'] ?? '',
      bytes: json['bytes'] ?? 0,
      format: json['format'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String? _cloudName;
  String? _apiKey;
  String? _apiSecret;

  // Initialize Cloudinary with your credentials
  void initialize({
    required String cloudName,
    required String apiKey,
    required String apiSecret,
  }) {
    _cloudName = cloudName;
    _apiKey = apiKey;
    _apiSecret = apiSecret;

    log('✅ Cloudinary service initialized successfully');
  }

  // Upload image file to Cloudinary using direct API call
  Future<CloudinaryUploadResponse> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    try {
      if (_cloudName == null || _apiKey == null) {
        throw Exception('Cloudinary not initialized. Call initialize() first.');
      }

      // Use upload preset for easier client-side uploads
      final params = <String, String>{
        'upload_preset':
            'GreenQuest', // Use the preset from your Cloudinary dashboard
      };

      if (folder != null) {
        params['folder'] = folder;
      }
      if (publicId != null) {
        params['public_id'] = publicId;
      }
      if (tags != null) {
        params['tags'] = tags.values.join(',');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add parameters
      request.fields.addAll(params);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final uploadResponse = CloudinaryUploadResponse.fromJson(jsonResponse);
        log('✅ Image uploaded successfully: ${uploadResponse.secureUrl}');
        return uploadResponse;
      } else {
        log('❌ Upload failed: ${response.statusCode} - $responseBody');
        throw Exception(
          'Upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
      rethrow;
    }
  }

  // Upload image from bytes
  Future<CloudinaryUploadResponse> uploadImageFromBytes({
    required List<int> imageBytes,
    required String fileName,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    try {
      if (_cloudName == null || _apiKey == null) {
        throw Exception('Cloudinary not initialized. Call initialize() first.');
      }

      // Use upload preset for easier client-side uploads
      final params = <String, String>{
        'upload_preset':
            'GreenQuest', // Use the preset from your Cloudinary dashboard
      };

      if (folder != null) {
        params['folder'] = folder;
      }
      if (publicId != null) {
        params['public_id'] = publicId;
      }
      if (tags != null) {
        params['tags'] = tags.values.join(',');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add parameters
      request.fields.addAll(params);

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final uploadResponse = CloudinaryUploadResponse.fromJson(jsonResponse);
        log('✅ Image uploaded successfully: ${uploadResponse.secureUrl}');
        return uploadResponse;
      } else {
        log('❌ Upload failed: ${response.statusCode} - $responseBody');
        throw Exception(
          'Upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      log('❌ Error uploading image from bytes: $e');
      rethrow;
    }
  }

  // Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        throw Exception('Cloudinary not initialized. Call initialize() first.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = <String, String>{
        'timestamp': timestamp.toString(),
        'api_key': _apiKey!,
        'public_id': publicId,
      };

      // Generate signature
      final signature = _generateSignature(params);
      params['signature'] = signature;

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: params,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['result'] as String?;
        log('✅ Image deleted successfully: $publicId');
        return result == 'ok';
      } else {
        log('❌ Delete failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('❌ Error deleting image: $e');
      return false;
    }
  }

  // Generate transformation URL
  String getTransformedUrl({
    required String publicId,
    int? width,
    int? height,
    String? crop,
    String? quality,
    String? format,
  }) {
    if (_cloudName == null) {
      throw Exception('Cloudinary not initialized. Call initialize() first.');
    }

    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop != null) transformations.add('c_$crop');
    if (quality != null) transformations.add('q_$quality');
    if (format != null) transformations.add('f_$format');

    final transformString =
        transformations.isNotEmpty ? '/${transformations.join(',')}' : '';

    return 'https://res.cloudinary.com/$_cloudName/image/upload$transformString/$publicId';
  }

  // Get image info
  Future<Map<String, dynamic>?> getImageInfo(String publicId) async {
    try {
      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        throw Exception('Cloudinary not initialized. Call initialize() first.');
      }

      final url =
          'https://api.cloudinary.com/v1_1/$_cloudName/resources/image/upload/$publicId';
      final authString = base64Encode(utf8.encode('$_apiKey:$_apiSecret'));

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $authString',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('❌ Error getting image info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Error getting image info: $e');
      return null;
    }
  }

  // Generate signature for API authentication
  String _generateSignature(Map<String, String> params) {
    // Sort parameters by key
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Create signature with API secret
    final signatureString = '$paramString$_apiSecret';

    // Generate SHA-1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);

    // Debug logging (uncomment if needed for troubleshooting)
    // log('🔐 Signature generation debug:');
    // log('🔐 Params: $params');
    // log('🔐 Sorted keys: $sortedKeys');
    // log('🔐 Param string: $paramString');
    // log('🔐 Signature string: $signatureString');
    // log('🔐 Generated signature: ${digest.toString()}');

    return digest.toString();
  }

  // Upload raw file (non-image) to Cloudinary
  Future<CloudinaryUploadResponse> uploadRawFile({
    required List<int> fileBytes,
    required String fileName,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    try {
      if (_cloudName == null || _apiKey == null) {
        throw Exception('Cloudinary not initialized. Call initialize() first.');
      }

      // Use upload preset for easier client-side uploads
      final params = <String, String>{
        'upload_preset':
            'GreenQuest', // Use the preset from your Cloudinary dashboard
      };

      if (folder != null) {
        params['folder'] = folder;
      }
      if (publicId != null) {
        params['public_id'] = publicId;
      }
      if (tags != null) {
        params['tags'] = tags.values.join(',');
      }

      // Create multipart request for raw upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/raw/upload'),
      );

      // Add parameters
      request.fields.addAll(params);

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final uploadResponse = CloudinaryUploadResponse.fromJson(jsonResponse);
        log('✅ Raw file uploaded successfully: ${uploadResponse.secureUrl}');
        return uploadResponse;
      } else {
        log('❌ Raw upload failed: ${response.statusCode} - $responseBody');
        throw Exception(
          'Raw upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      log('❌ Error uploading raw file: $e');
      rethrow;
    }
  }

  // Check if service is initialized
  bool get isInitialized =>
      _cloudName != null && _apiKey != null && _apiSecret != null;

  // Get current cloud name
  String? get cloudName => _cloudName;
}
