# File Submission System - Implementation Guide

## Overview

This document describes the comprehensive file submission system implemented for the GreenQuest Flutter application. The system allows students to upload various file types (PDF, DOC, images, etc.) to Cloudinary and submit them for assignments and activities. Instructors can then view, download, and grade these submissions.

## Features Implemented

### Student Side (Mobile App)

1. **File Picker Screen** (`lib/user/submit/file_picker_screen.dart`)
   - Modern, intuitive UI for file selection
   - Support for multiple file types (PDF, DOC, DOCX, images, etc.)
   - File size validation (5MB limit)
   - Real-time upload progress
   - File preview with appropriate icons and colors
   - Automatic submission to instructor's section

2. **Enhanced Assignment/Activity Detail Screens**
   - Updated to use the new file submission system
   - Shows submitted files with proper icons and metadata
   - Links to file URLs for viewing/downloading
   - Submission status tracking

3. **File Upload Service** (`lib/shared/services/file_upload_service.dart`)
   - Handles multiple file types
   - Cloudinary integration for secure file storage
   - File validation and error handling
   - Progress tracking for uploads

### Instructor Side (Web Interface)

1. **Submissions Controller** (`lib/instructor/submissions/submissions_controller.dart`)
   - Load submissions by assignment, activity, or instructor
   - Filter submissions by status (All, Submitted, Graded, Late)
   - Grade submissions with scores and feedback
   - Real-time statistics tracking

2. **Enhanced Submission Detail Screen**
   - View all submitted files with proper file type icons
   - Download/view file links
   - Grading interface with score and feedback
   - Integration with Firestore for persistent grading

## Technical Architecture

### File Upload Flow

1. **Student selects files** → File Picker Screen opens
2. **Files are validated** → Size and type checks
3. **Files upload to Cloudinary** → Secure cloud storage
4. **Submission record created** → Firestore database
5. **Instructor receives notification** → Real-time updates

### Data Structure

#### Submission Document (Firestore)
```javascript
{
  "assignmentId": "string",        // or "activityId"
  "studentId": "string",
  "studentName": "string",
  "studentEmail": "string",
  "studentIdNumber": "string",
  "instructorId": "string",
  "instructorName": "string",
  "sectionId": "string",
  "sectionName": "string",
  "files": [
    {
      "name": "document.pdf",
      "url": "https://cloudinary.com/...",
      "publicId": "greenquest/submissions/...",
      "size": 1024000,
      "type": "pdf",
      "resourceType": "raw",
      "uploadedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "submittedAt": "timestamp",
  "status": "submitted|graded",
  "grade": 85,
  "feedback": "Good work!",
  "gradedAt": "timestamp",
  "gradedBy": "instructorId"
}
```

### File Types Supported

- **Documents**: PDF, DOC, DOCX, TXT
- **Spreadsheets**: XLS, XLSX
- **Presentations**: PPT, PPTX
- **Images**: JPG, JPEG, PNG, GIF, WEBP
- **Archives**: ZIP, RAR, 7Z
- **Videos**: MP4, AVI, MOV
- **Audio**: MP3, WAV, FLAC

## Key Components

### 1. FileSubmissionController
**Location**: `lib/shared/controllers/file_submission_controller.dart`

**Responsibilities**:
- File selection and validation
- Upload progress tracking
- Submission to Firestore
- Error handling

**Key Methods**:
- `pickFiles()` - Opens file picker
- `uploadFiles()` - Uploads to Cloudinary
- `submitAssignment()` - Creates submission record
- `getAssignmentSubmission()` - Checks existing submissions

### 2. FileUploadService
**Location**: `lib/shared/services/file_upload_service.dart`

**Responsibilities**:
- Cloudinary integration
- File type detection
- Progress callbacks
- Error handling

**Key Methods**:
- `pickFiles()` - Platform file picker
- `uploadFile()` - Single file upload
- `uploadMultipleFiles()` - Batch upload
- `getFileIcon()` - UI helpers

### 3. SubmissionsController
**Location**: `lib/instructor/submissions/submissions_controller.dart`

**Responsibilities**:
- Load submissions for instructors
- Filter and search functionality
- Grading workflow
- Statistics tracking

**Key Methods**:
- `loadAssignmentSubmissions()` - Load by assignment
- `loadInstructorSubmissions()` - Load by instructor/section
- `gradeSubmission()` - Save grades and feedback
- `filteredSubmissions` - Apply filters

## Usage Instructions

### For Students

1. **Navigate to Assignment/Activity**: Open any assignment or activity from your instructor
2. **Click "Add or Create"**: This opens the file picker screen
3. **Select Files**: Choose one or more files from your device
4. **Review Selection**: See file names, sizes, and types
5. **Submit**: Files are uploaded and submission is recorded
6. **View Status**: See submitted files and submission status

### For Instructors

1. **Access Submissions**: Navigate to class detail screen
2. **View Student Submissions**: Click on any assignment/activity to see submissions
3. **Review Files**: Click on student submissions to see uploaded files
4. **Grade Submission**: Enter score and feedback
5. **Save Grade**: Submission is marked as graded

## Configuration

### Cloudinary Setup
The system uses the existing Cloudinary configuration in:
- `lib/shared/config/cloudinary_config.dart`

### File Size Limits
- Maximum file size: 5MB (configurable in CloudinaryConfig)
- Multiple files allowed per submission

### Supported Platforms
- **Mobile**: Android/iOS (student app)
- **Web**: Desktop browsers (instructor interface)

## Security Features

1. **File Validation**: Size and type checking
2. **Secure Upload**: Cloudinary signed uploads
3. **Access Control**: Section-based submission visibility
4. **Authentication**: Firebase Auth integration

## Error Handling

1. **File Too Large**: Clear error message with size limit
2. **Upload Failed**: Retry mechanism and error reporting
3. **Network Issues**: Graceful degradation
4. **Invalid Files**: Type validation with user feedback

## Future Enhancements

1. **File Preview**: In-app document viewer
2. **Batch Grading**: Grade multiple submissions at once
3. **Plagiarism Detection**: Integration with plagiarism services
4. **Mobile Notifications**: Push notifications for new submissions
5. **Offline Support**: Queue uploads when offline

## Dependencies Added

```yaml
dependencies:
  file_picker: ^8.0.0+1  # File selection
  # Existing dependencies:
  cloudinary_flutter: ^1.0.6
  image_picker: ^1.0.4
  cloud_firestore: ^6.0.1
  firebase_auth: ^6.0.1
```

## Database Collections

### New Collections Created
- `assignment_submissions` - Assignment submission records
- `activity_submissions` - Activity submission records

### Existing Collections Used
- `users` - Student information and section assignments
- `instructors` - Instructor information
- `assignments` - Assignment metadata
- `activities` - Activity metadata

## Testing Checklist

- [ ] Student can select multiple files
- [ ] Files upload successfully to Cloudinary
- [ ] Submission appears in instructor interface
- [ ] Instructor can view and download files
- [ ] Grading workflow works correctly
- [ ] Section-based filtering works
- [ ] Error handling for large files
- [ ] Error handling for network issues
- [ ] Mobile UI is responsive
- [ ] Web UI displays files correctly

## Troubleshooting

### Common Issues

1. **Files not uploading**
   - Check internet connection
   - Verify Cloudinary credentials
   - Check file size limits

2. **Submissions not appearing**
   - Verify section assignments
   - Check Firestore security rules
   - Ensure proper instructor/student linking

3. **Grading not saving**
   - Check instructor permissions
   - Verify Firestore write permissions
   - Check network connectivity

### Debug Information

Enable debug logging by checking the console for:
- `📁 File picker...` - File selection events
- `📤 Uploading file...` - Upload progress
- `✅ File uploaded...` - Success messages
- `❌ Error...` - Error details

## Support

For technical support or questions about the file submission system:
1. Check the console logs for error details
2. Verify Cloudinary and Firebase configurations
3. Test with smaller files to isolate issues
4. Check network connectivity and permissions

---

**Last Updated**: January 2024
**Version**: 1.0.0
**Author**: GreenQuest Development Team
