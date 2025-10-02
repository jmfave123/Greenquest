# Class Management System

This directory contains the class management functionality for instructors using GetX state management and Firestore backend.

## Files

- `class_screen_controller.dart` - GetX controller handling all class-related business logic
- `class_screen.dart` - UI screen for displaying and managing classes
- `class_detail_screen.dart` - Detailed view of individual classes

## Features

### Class Creation
- Form-based class creation with validation
- Fields: Section, Course, Room, Day, Start Time, End Time
- Real-time form validation with error messages
- Loading states during creation

### Data Management
- Firestore integration for persistent storage
- Real-time data synchronization
- Automatic loading of classes on screen initialization
- Optimistic UI updates

### UI/UX
- Responsive grid layout for class cards
- Modal dialog for class creation
- Loading indicators and success/error messages
- Consistent design with existing app theme

## Firestore Collection Structure

### Collection: `instructors`
```json
{
  "instructor_001": {
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

**Note**: Classes are stored as an array within each instructor's document, making it easier to manage instructor-specific data and reducing the number of Firestore reads.

## Usage

1. **Initialize Controller**: The controller is automatically initialized when the ClassScreen is built
2. **Load Classes**: Classes are automatically loaded from Firestore on initialization
3. **Create Class**: Click "Create Class" button to open the form dialog
4. **Form Validation**: All fields are validated before submission
5. **Save to Firestore**: Valid forms are saved to Firestore and immediately displayed

## Controller Methods

- `loadClasses()` - Load classes from Firestore
- `openCreateClassDialog()` - Show creation form
- `closeCreateClassDialog()` - Hide form and clear fields
- `createClass()` - Validate and save new class
- `selectStartTime()` / `selectEndTime()` - Time picker methods
- `setSelectedDay()` - Set selected day of week

## Error Handling

- Form validation with specific error messages
- Firestore operation error handling
- User-friendly error notifications via GetX snackbars
- Loading states to prevent multiple submissions
