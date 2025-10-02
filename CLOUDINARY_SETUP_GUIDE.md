# Cloudinary Image Upload Setup Guide

This guide will help you set up Cloudinary image upload functionality in your GreenQuest Flutter app.

## Prerequisites

1. A Cloudinary account (sign up at [cloudinary.com](https://cloudinary.com))
2. Flutter development environment set up
3. Your Cloudinary credentials (Cloud Name, API Key, API Secret)

## Step 1: Get Your Cloudinary Credentials

1. Log in to your [Cloudinary Console](https://cloudinary.com/console)
2. Go to the **Dashboard** section
3. Copy the following values:
   - **Cloud Name** (e.g., `your-cloud-name`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz1234567890`)

## Step 2: Configure Your Credentials

1. Open `lib/shared/config/cloudinary_config.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class CloudinaryConfig {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'your_actual_cloud_name';
  static const String apiKey = 'your_actual_api_key';
  static const String apiSecret = 'your_actual_api_secret';
  
  // ... rest of the configuration
}
```

## Step 3: Install Dependencies

The required dependencies are already added to your `pubspec.yaml`:

```yaml
dependencies:
  cloudinary_flutter: ^1.0.6
  image_picker: ^1.0.4
  http: ^1.1.0
  crypto: ^3.0.3
```

Run `flutter pub get` to install them.

## Step 4: Using the Image Upload Widgets

### Basic Usage

```dart
import 'package:get/get.dart';
import '../shared/widgets/image_upload_widget.dart';
import '../shared/controllers/image_upload_controller.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageUploadWidget(
        title: 'Upload Profile Picture',
        subtitle: 'Choose an image from your gallery or take a new photo',
        folder: 'profiles',
        onImageUploaded: (imageUrl) {
          // Handle successful upload
          print('Image uploaded: $imageUrl');
        },
        onError: (error) {
          // Handle upload error
          print('Upload error: $error');
        },
      ),
    );
  }
}
```

### Compact Widget for Smaller Spaces

```dart
CompactImageUploadWidget(
  folder: 'thumbnails',
  onImageUploaded: (imageUrl) {
    // Handle successful upload
  },
  onError: (error) {
    // Handle upload error
  },
)
```

### Using the Controller Directly

```dart
import 'package:get/get.dart';
import '../shared/controllers/image_upload_controller.dart';

class YourController extends GetxController {
  final ImageUploadController imageController = Get.put(ImageUploadController());

  Future<void> uploadProfilePicture() async {
    // Pick image from gallery
    await imageController.pickImageFromGallery();
    
    // Upload selected image
    await imageController.uploadSelectedImage(
      folder: 'profiles',
      tags: {
        'type': 'profile',
        'user_id': 'user123',
      },
    );
    
    // Get the uploaded URL
    final imageUrl = imageController.uploadedImageUrl;
    if (imageUrl != null) {
      print('Uploaded image URL: $imageUrl');
    }
  }
}
```

## Step 5: Test the Implementation

1. Navigate to `/image-upload-example` in your app
2. Try uploading an image using both gallery and camera options
3. Check the console for upload logs
4. Verify the image appears in your Cloudinary dashboard

## Available Widgets and Components

### 1. ImageUploadWidget
- Full-featured upload widget with preview
- Shows upload progress
- Handles errors gracefully
- Customizable title and subtitle

### 2. CompactImageUploadWidget
- Smaller version for limited space
- Bottom sheet with upload options
- Minimal UI footprint

### 3. CloudinaryService
- Direct API access for advanced usage
- Supports file upload, bytes upload, and URL upload
- Image transformation and deletion
- Signature generation for secure uploads

### 4. ImageUploadController
- GetX controller for state management
- Handles image picking and uploading
- Progress tracking and error handling
- Reactive UI updates

## Configuration Options

### CloudinaryConfig Class

```dart
class CloudinaryConfig {
  static const String cloudName = 'your_cloud_name';
  static const String apiKey = 'your_api_key';
  static const String apiSecret = 'your_api_secret';
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
    'jpg', 'jpeg', 'png', 'gif', 'webp'
  ];
  
  // Maximum file size (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
}
```

## Security Best Practices

1. **Never expose your API Secret in client-side code**
   - The current implementation uses direct API calls with signature generation
   - For production apps, consider using unsigned uploads with upload presets
   - Or implement a backend service to handle uploads

2. **Use Upload Presets (Recommended for Production)**
   - Create unsigned upload presets in your Cloudinary console
   - Modify the service to use unsigned uploads
   - This eliminates the need for API secrets in the client

3. **Set up proper folder structure**
   - Use organized folder names (e.g., 'profiles', 'thumbnails', 'documents')
   - Implement proper access controls

## Troubleshooting

### Common Issues

1. **"Cloudinary not configured" Error**
   - Make sure you've updated the credentials in `cloudinary_config.dart`
   - Verify the credentials are correct in your Cloudinary console

2. **Upload Fails with 401 Error**
   - Check your API key and secret
   - Ensure the timestamp and signature are generated correctly

3. **Image Not Appearing**
   - Check your internet connection
   - Verify the image format is supported
   - Check file size limits

4. **Permission Denied**
   - Ensure your Cloudinary account has upload permissions
   - Check if your account has reached upload limits

### Debug Mode

Enable debug logging by checking the console output. The service logs all operations with ✅ for success and ❌ for errors.

## Example Integration in Your App

Here's how you might integrate this into a user profile screen:

```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Column(
        children: [
          // Profile picture upload
          ImageUploadWidget(
            title: 'Profile Picture',
            subtitle: 'Upload your profile picture',
            folder: 'profiles',
            width: 200,
            height: 200,
            onImageUploaded: (imageUrl) {
              // Save to user profile
              _saveProfilePicture(imageUrl);
            },
          ),
          
          // Other profile fields...
        ],
      ),
    );
  }
  
  void _saveProfilePicture(String imageUrl) {
    // Save to Firestore or your preferred storage
    // Update user profile with new image URL
  }
}
```

## Next Steps

1. Customize the upload widgets to match your app's design
2. Implement proper error handling and user feedback
3. Add image compression and optimization
4. Consider implementing progress indicators for large files
5. Set up proper folder organization in your Cloudinary account

## Support

For issues specific to this implementation, check the console logs and ensure your Cloudinary credentials are correct.

For Cloudinary-specific issues, refer to the [Cloudinary Documentation](https://cloudinary.com/documentation).
