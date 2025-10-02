# Login System

## Overview
This module handles user login using Firebase Auth and role routing via Firestore. The logic is implemented in `LoginScreenController`.

## Flow
1. Validate email/password locally.
2. Sign in with Firebase Auth (`signInWithEmailAndPassword`).
3. Require verified email. If not verified, show action to resend.
4. Determine role by querying Firestore:
   - `instructors` where `email` == input
   - `admins` where `email` == input
5. Navigate based on role:
   - Admin → `/admin-dashboard`
   - Instructor → `/instructor-dashboard`

## Controller
File: `lib/shared/login_screen_controller.dart`
- `emailController`, `passwordController`: Text controllers
- `isLoading`, `errorMessage`, `isFormValid`: reactive state
- `login()`: main login flow
- `resendVerificationEmail()`: sends Firebase verification email
- `clearForm()`, `clearError()`: utilities
- Helpers: `createTestAdmin()`, `createTestInstructor()`, `testLogin()`

## Firestore Structure (expected)
```
admins/{adminId}
  name: string
  email: string
  isActive: bool
  isVerified: bool
  createdAt: timestamp
  updatedAt: timestamp

instructors/{instructorId}
  name: string
  email: string
  phone: string
  isActive: bool
  isVerified: bool
  createdAt: timestamp
  updatedAt: timestamp
```

## Routes
- Admin success: `/admin-dashboard`
- Instructor success: `/instructor-dashboard`

Ensure these routes are registered in your app router.

## UI Integration
- Bind `TextEditingController`s to the email/password fields
- Disable the login button when `isLoading` or `!isFormValid`
- Display `errorMessage` when present

## Security Rules (example)
```javascript
match /admins/{adminId} {
  allow read, write: if request.auth != null && request.auth.token.email == resource.data.email;
}
match /instructors/{instructorId} {
  allow read, write: if request.auth != null && request.auth.token.email == resource.data.email;
}
```

Adjust rules per your app’s requirements.
