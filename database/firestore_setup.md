# GreenQuest - Firestore Database Setup

This document provides the Firestore database structure for the GreenQuest Flutter application.

## 🔥 Firestore Collections Structure

### 1. Users Collection
```javascript
// Collection: users
{
  "userId": {
    "fullName": "John Doe",
    "phoneNumber": "+1234567890",
    "email": "john.doe@example.com",
    "idNumber": "2024-001234",
    "role": "user", // or "instructor", "admin"
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true,
    "isVerified": true,
    "profileImage": "https://example.com/profile.jpg",
    "points": 150,
    "level": 3,
    "badges": ["eco_warrior", "tree_planter"],
    "totalTreesPlanted": 5,
    "totalPointsEarned": 150
  }
}
```

### 2. Admins Collection
```javascript
// Collection: admins
{
  "adminId": {
    "name": "Admin User",
    "email": "admin@greenquest.com",
    "isActive": true,
    "isVerified": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "role": "admin",
    "permissions": ["user_management", "content_management", "analytics"]
  }
}
```

### 3. Instructors Collection
```javascript
// Collection: instructors
{
  "instructorId": {
    "name": "Instructor Name",
    "email": "instructor@university.edu",
    "phone": "+1234567890",
    "department": "NSTP Department",
    "isActive": true,
    "isVerified": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "classes": [
      {
        "id": "1704067200000",
        "section": "BSIT 1A",
        "course": "NSTP",
        "room": "MSC01",
        "day": "Monday",
        "startTime": "1:00 PM",
        "endTime": "2:30 PM",
        "instructorId": "instructor_001",
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "lastUpdated": "2024-01-01T00:00:00Z"
  }
}
```

### 4. Classes Collection (Alternative Structure)
```javascript
// Collection: classes (if using separate collection)
{
  "classId": {
    "section": "BSIT 1A",
    "course": "NSTP",
    "room": "MSC01",
    "day": "Monday",
    "startTime": "1:00 PM",
    "endTime": "2:30 PM",
    "instructorId": "instructor_001",
    "instructorName": "Instructor Name",
    "students": [
      {
        "userId": "user_001",
        "name": "Student Name",
        "email": "student@example.com",
        "status": "active", // or "inactive"
        "joinedAt": "2024-01-01T00:00:00Z"
      }
    ],
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### 5. Trees Collection
```javascript
// Collection: trees
{
  "treeId": {
    "userId": "user_001",
    "instructorId": "instructor_001",
    "classId": "class_001",
    "treeType": "Mango",
    "location": {
      "latitude": 8.4799,
      "longitude": 124.6439,
      "address": "Cagayan de Oro, Philippines"
    },
    "plantedDate": "2024-01-01T00:00:00Z",
    "status": "planted", // "planted", "growing", "mature"
    "pointsAwarded": 50,
    "images": [
      "https://example.com/tree1.jpg",
      "https://example.com/tree2.jpg"
    ],
    "notes": "Planted during NSTP activity",
    "verificationStatus": "verified", // "pending", "verified", "rejected"
    "verifiedBy": "instructor_001",
    "verifiedAt": "2024-01-01T00:00:00Z"
  }
}
```

### 6. Activities Collection
```javascript
// Collection: activities
{
  "activityId": {
    "title": "Tree Planting Activity",
    "description": "Community tree planting in Barangay Carmen",
    "instructorId": "instructor_001",
    "classId": "class_001",
    "date": "2024-01-15T08:00:00Z",
    "location": {
      "name": "Barangay Carmen",
      "latitude": 8.4799,
      "longitude": 124.6439,
      "address": "Cagayan de Oro, Philippines"
    },
    "maxParticipants": 30,
    "registeredParticipants": [
      {
        "userId": "user_001",
        "name": "Student Name",
        "registeredAt": "2024-01-10T00:00:00Z"
      }
    ],
    "status": "scheduled", // "scheduled", "ongoing", "completed", "cancelled"
    "pointsReward": 100,
    "requirements": ["Bring water", "Wear comfortable clothes"],
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### 7. Announcements Collection
```javascript
// Collection: announcements
{
  "announcementId": {
    "title": "Important Update",
    "content": "Next tree planting activity scheduled for next week",
    "instructorId": "instructor_001",
    "classId": "class_001",
    "priority": "high", // "low", "medium", "high"
    "targetAudience": "students", // "students", "all", "instructors"
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true,
    "expiresAt": "2024-02-01T00:00:00Z"
  }
}
```

### 8. Leaderboard Collection
```javascript
// Collection: leaderboard
{
  "userId": {
    "name": "John Doe",
    "email": "john.doe@example.com",
    "points": 150,
    "level": 3,
    "totalTreesPlanted": 5,
    "badges": ["eco_warrior", "tree_planter"],
    "rank": 1,
    "lastUpdated": "2024-01-01T00:00:00Z"
  }
}
```

## 🔧 Firebase Setup Instructions

### 1. Enable Authentication
```bash
# Enable Email/Password authentication in Firebase Console
# Go to Authentication > Sign-in method > Email/Password
```

### 2. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admins can read/write admin data
    match /admins/{adminId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Instructors can read/write instructor data
    match /instructors/{instructorId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'instructor';
    }
    
    // Students can read classes they're enrolled in
    match /classes/{classId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.students[].userId;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['instructor', 'admin'];
    }
    
    // Trees are readable by all authenticated users
    match /trees/{treeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Activities are readable by all authenticated users
    match /activities/{activityId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['instructor', 'admin'];
    }
    
    // Announcements are readable by all authenticated users
    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['instructor', 'admin'];
    }
    
    // Leaderboard is readable by all authenticated users
    match /leaderboard/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 3. Initialize Default Data

#### Create Admin User
```dart
// In your Firebase Console or through code
await FirebaseFirestore.instance.collection('admins').doc('admin_001').set({
  'name': 'System Admin',
  'email': 'admin@greenquest.com',
  'isActive': true,
  'isVerified': true,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'role': 'admin',
  'permissions': ['user_management', 'content_management', 'analytics']
});
```

#### Create Test Instructor
```dart
await FirebaseFirestore.instance.collection('instructors').doc('instructor_001').set({
  'name': 'Test Instructor',
  'email': 'instructor@university.edu',
  'phone': '+1234567890',
  'department': 'NSTP Department',
  'isActive': true,
  'isVerified': true,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'classes': [],
  'lastUpdated': FieldValue.serverTimestamp()
});
```

## 🚀 Getting Started

1. **Firebase Project Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Add your Flutter app to the project

2. **Download Configuration**
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Add these files to your project

3. **Install Dependencies**
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_auth: ^4.15.3
     cloud_firestore: ^4.13.6
   ```

4. **Initialize Firebase**
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(MyApp());
   }
   ```

## 📱 Default Test Accounts

### Admin Account
- **Email**: admin@greenquest.com
- **Password**: admin123
- **Role**: Admin

### Instructor Account
- **Email**: instructor@university.edu
- **Password**: instructor123
- **Role**: Instructor

### Student Account
- **Email**: student@example.com
- **Password**: student123
- **Role**: User

## 🔍 Testing the Setup

1. **Authentication Test**
   - Try logging in with test accounts
   - Verify role-based navigation works

2. **Data Creation Test**
   - Create a new class as instructor
   - Add students to the class
   - Create announcements

3. **Tree Planting Test**
   - Plant a tree as a student
   - Verify points are awarded
   - Check leaderboard updates

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied**
   - Check Firestore security rules
   - Verify user authentication status
   - Ensure proper role assignments

2. **Data Not Loading**
   - Check network connectivity
   - Verify Firestore indexes
   - Check for console errors

3. **Authentication Issues**
   - Verify Firebase configuration
   - Check email verification status
   - Ensure proper error handling

## 📊 Analytics and Monitoring

Enable Firebase Analytics and Crashlytics for monitoring:
```yaml
dependencies:
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9
```

This setup provides a complete foundation for your GreenQuest application with proper security, scalability, and real-time capabilities.
