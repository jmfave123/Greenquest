# Announcement System

## Firestore Collection Structure

```
instructors/
  └── {instructorId}/
      └── announcements/
          └── {announcementId}/
              ├── title: string
              ├── content: string
              ├── pinned: boolean
              ├── urgent: boolean
              ├── views: number
              ├── createdAt: timestamp
              ├── instructorId: string
              └── instructorName: string
```

## Features

- ✅ Create new announcements with title, content, pin status, and urgent flag
- ✅ View all announcements in chronological order (newest first)
- ✅ Pin/unpin announcements to the top
- ✅ Mark announcements as urgent
- ✅ Track view counts
- ✅ Delete announcements
- ✅ Reactive UI via GetX (if integrated)
- ✅ Loading states and error handling
- ✅ Basic form validation

## Usage

1. The `AnnouncementScreenController` manages all announcement operations.
2. The controller loads announcements on init.
3. UI can bind to controller observables (`showCreate`, `announcements`, `isLoading`).
4. Validation ensures title and content are provided.
5. Loading states prevent multiple submissions.

## Security Rules (example)

Ensure your Firestore rules allow instructors to manage their own announcements, while students can read.

```javascript
match /instructors/{instructorId}/announcements/{announcementId} {
  allow read: if request.auth != null; // Students can read
  allow create, update, delete: if request.auth != null && request.auth.uid == instructorId; // Only owner writes
}
```
