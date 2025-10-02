import 'dart:io';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../config/cloudinary_config.dart';

class ImageUploadController extends GetxController {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable variables
  final RxBool _isUploading = false.obs;
  final RxString _uploadProgress = '0%'.obs;
  final RxString _uploadedImageUrl = ''.obs;
  final RxString _uploadError = ''.obs;
  final Rx<File?> _selectedImage = Rx<File?>(null);

  // Getters
  bool get isUploading => _isUploading.value;
  String get uploadProgress => _uploadProgress.value;
  String get uploadedImageUrl => _uploadedImageUrl.value;
  String get uploadError => _uploadError.value;
  File? get selectedImage => _selectedImage.value;

  @override
  void onInit() {
    super.onInit();
    _initializeCloudinary();
  }

  // Initialize Cloudinary service
  void _initializeCloudinary() {
    if (CloudinaryConfig.cloudName.isNotEmpty &&
        CloudinaryConfig.apiKey.isNotEmpty) {
      _cloudinaryService.initialize(
        cloudName: CloudinaryConfig.cloudName,
        apiKey: CloudinaryConfig.apiKey,
        apiSecret: CloudinaryConfig.apiSecret,
      );
      log(
        '✅ Cloudinary initialized with cloud name: ${CloudinaryConfig.cloudName}',
      );
    } else {
      _uploadError.value =
          'Cloudinary not configured. Please check your credentials.';
    }
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      _uploadError.value = '';

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage.value = File(pickedFile.path);
        _uploadError.value = '';
      }
    } catch (e) {
      _uploadError.value = 'Error picking image: $e';
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      _uploadError.value = '';

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage.value = File(pickedFile.path);
        _uploadError.value = '';
      }
    } catch (e) {
      _uploadError.value = 'Error taking photo: $e';
    }
  }

  // Upload selected image
  Future<void> uploadSelectedImage({
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    if (_selectedImage.value == null) {
      _uploadError.value = 'No image selected';
      return;
    }

    await uploadImage(
      imageFile: _selectedImage.value!,
      folder: folder,
      publicId: publicId,
      tags: tags,
    );
  }

  // Upload image file
  Future<void> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    try {
      _isUploading.value = true;
      _uploadError.value = '';
      _uploadProgress.value = '0%';

      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > CloudinaryConfig.maxFileSize) {
        throw Exception(
          'File size exceeds maximum limit (${CloudinaryConfig.maxFileSize ~/ (1024 * 1024)}MB)',
        );
      }

      // Simulate progress updates
      _uploadProgress.value = '25%';
      await Future.delayed(const Duration(milliseconds: 100));

      _uploadProgress.value = '50%';
      await Future.delayed(const Duration(milliseconds: 100));

      // Upload to Cloudinary
      final response = await _cloudinaryService.uploadImage(
        imageFile: imageFile,
        folder: folder ?? CloudinaryConfig.defaultFolder,
        publicId: publicId,
        tags: tags,
      );

      _uploadProgress.value = '100%';
      _uploadedImageUrl.value = response.secureUrl;

      // Clear selected image after successful upload
      _selectedImage.value = null;

      Get.snackbar(
        'Success',
        'Image uploaded successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _uploadError.value = 'Upload failed: $e';
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isUploading.value = false;
    }
  }

  // Upload image from bytes
  Future<void> uploadImageFromBytes({
    required List<int> imageBytes,
    required String fileName,
    String? folder,
    String? publicId,
    Map<String, String>? tags,
  }) async {
    try {
      _isUploading.value = true;
      _uploadError.value = '';
      _uploadProgress.value = '0%';

      // Validate file size
      if (imageBytes.length > CloudinaryConfig.maxFileSize) {
        throw Exception(
          'File size exceeds maximum limit (${CloudinaryConfig.maxFileSize ~/ (1024 * 1024)}MB)',
        );
      }

      _uploadProgress.value = '50%';

      // Upload to Cloudinary
      final response = await _cloudinaryService.uploadImageFromBytes(
        imageBytes: imageBytes,
        fileName: fileName,
        folder: folder ?? CloudinaryConfig.defaultFolder,
        publicId: publicId,
        tags: tags,
      );

      _uploadProgress.value = '100%';
      _uploadedImageUrl.value = response.secureUrl;

      Get.snackbar(
        'Success',
        'Image uploaded successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      _uploadError.value = 'Upload failed: $e';
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isUploading.value = false;
    }
  }

  // Delete uploaded image
  Future<void> deleteUploadedImage(String publicId) async {
    try {
      final success = await _cloudinaryService.deleteImage(publicId);

      if (success) {
        _uploadedImageUrl.value = '';
        Get.snackbar(
          'Success',
          'Image deleted successfully!',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      _uploadError.value = 'Delete failed: $e';
      Get.snackbar(
        'Error',
        'Failed to delete image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  // Clear all data
  void clearAll() {
    _selectedImage.value = null;
    _uploadedImageUrl.value = '';
    _uploadError.value = '';
    _uploadProgress.value = '0%';
  }

  // Get transformed URL
  String getTransformedUrl({
    required String publicId,
    int? width,
    int? height,
    String? crop,
    String? quality,
    String? format,
  }) {
    return _cloudinaryService.getTransformedUrl(
      publicId: publicId,
      width: width,
      height: height,
      crop: crop,
      quality: quality,
      format: format,
    );
  }
}
