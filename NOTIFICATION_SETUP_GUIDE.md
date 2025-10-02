# Push Notification Setup Guide for GreenQuest

## Overview
This guide explains how to set up and use push notifications in the GreenQuest mobile app to notify students when instructors post new announcements.

## Features Implemented

### ✅ **Notification Service**
- **File**: `lib/shared/services/notification_service.dart`
- **Features**:
  - Firebase Cloud Messaging (FCM) integration
  - Local notifications for foreground messages
  - Permission handling for Android 13+
  - FCM token management and storage
  - Background message handling
  - Notification tap handling

### ✅ **Announcement Notifications**
- **Integration**: Updated `AnnouncementScreenController` to send notifications
- **Trigger**: When instructor posts new announcement
- **Recipients**: All students who have selected that instructor
- **Content**: Title, instructor name, and announcement details

### ✅ **Test Widget**
- **File**: `lib/shared/widgets/notification_test_widget.dart`
- **Features**:
  - Test local notifications
  - Test announcement notifications
  - Clear all notifications
  - Display FCM token for debugging

## Setup Instructions

### 1. **Dependencies Added**
```yaml
dependencies:
  firebase_messaging: ^16.0.1
  flutter_local_notifications: ^17.2.3
  permission_handler: ^11.3.1
```

### 2. **Android Configuration**
**File**: `android/app/src/main/AndroidManifest.xml`
- Added notification permissions
- Added Firebase Cloud Messaging service
- Added POST_NOTIFICATIONS permission for Android 13+

### 3. **App Initialization**
**File**: `lib/main.dart`
- Notification service initialized on app startup
- Only for mobile platforms (not web)

## How It Works

### **1. User Registration**
When a user logs in:
1. Notification service requests permissions
2. FCM token is generated
3. Token is saved to user document in Firestore
4. User is ready to receive notifications

### **2. Instructor Posts Announcement**
When instructor creates announcement:
1. Announcement is saved to Firestore
2. System finds all students of that instructor
3. Notifications are sent to all students' FCM tokens
4. Students receive push notifications on their devices

### **3. Student Receives Notification**
When student receives notification:
1. **Foreground**: Local notification is shown
2. **Background**: System notification appears
3. **Tapped**: App opens to announcement details

## Database Structure

### **User Document**
```
users/{userId} → {
  fcmToken: "fcm_token_string",
  lastTokenUpdate: Timestamp,
  selectedInstructorId: "instructor_id",
  selectedInstructorName: "instructor_name"
}
```

### **Notification Flow**
```
Instructor posts → Find students → Send to FCM tokens → Students receive
```

## Testing

### **1. Manual Testing**
Use the notification test widget in the instructor announcement screen:
- **Test Local**: Shows local notification
- **Test Announcement**: Simulates announcement notification
- **Clear All**: Removes all notifications
- **Show Token**: Displays FCM token for debugging

### **2. Real Testing**
1. Login as instructor
2. Go to Announcements
3. Create new announcement
4. Check student devices for notifications

## Backend Integration (Future)

### **Current Implementation**
- Notifications are triggered from the mobile app
- FCM tokens are stored in Firestore
- Basic notification sending is implemented

### **Production Backend Needed**
For production use, you'll need:
1. **Backend Server**: To send FCM messages
2. **Firebase Admin SDK**: On server for FCM
3. **Cloud Functions**: For automated notifications

### **Example Backend Code**
```javascript
// Firebase Cloud Function
exports.sendAnnouncementNotification = functions.firestore
  .document('instructors/{instructorId}/announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const announcement = snap.data();
    const instructorId = context.params.instructorId;
    
    // Get all students of this instructor
    const students = await admin.firestore()
      .collection('users')
      .where('selectedInstructorId', '==', instructorId)
      .get();
    
    // Send notifications to all students
    const tokens = students.docs.map(doc => doc.data().fcmToken);
    
    await admin.messaging().sendMulticast({
      tokens: tokens,
      notification: {
        title: `New Announcement from ${announcement.instructorName}`,
        body: announcement.title,
      },
      data: {
        type: 'announcement',
        instructorId: instructorId,
        announcementId: context.params.announcementId,
      }
    });
  });
```

## Troubleshooting

### **Common Issues**

1. **No Notifications Received**
   - Check if FCM token is generated
   - Verify permissions are granted
   - Check if user has selected an instructor
   - Verify instructor posted announcement

2. **Permission Denied**
   - Android 13+: POST_NOTIFICATIONS permission required
   - Check device notification settings
   - Reinstall app if needed

3. **FCM Token Issues**
   - Token changes on app reinstall
   - Token expires and needs refresh
   - Check Firebase project configuration

### **Debug Information**
The test widget shows:
- FCM token for debugging
- Current notification status
- Permission status

## Security Considerations

1. **FCM Token Storage**: Tokens are stored in user documents
2. **Permission Handling**: Proper permission requests
3. **Background Processing**: Secure background message handling
4. **Data Validation**: Validate notification data

## Future Enhancements

1. **Rich Notifications**: Add images and actions
2. **Scheduled Notifications**: Send at specific times
3. **Notification Categories**: Different types of notifications
4. **User Preferences**: Allow users to disable notifications
5. **Analytics**: Track notification delivery and engagement

## Production Checklist

- [ ] Set up Firebase Cloud Functions for backend
- [ ] Configure Firebase Admin SDK
- [ ] Test on real devices
- [ ] Set up notification analytics
- [ ] Configure notification channels
- [ ] Test background/foreground scenarios
- [ ] Verify token refresh handling
- [ ] Test notification tap handling

## Support

For issues with notifications:
1. Check Firebase Console for delivery status
2. Verify FCM token in user document
3. Test with notification test widget
4. Check device notification settings
5. Review Firebase logs for errors

The notification system is now ready for testing and can be enhanced with a proper backend for production use.
