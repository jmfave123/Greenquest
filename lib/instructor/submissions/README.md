# Student Submissions Module

This module provides functionality for instructors to view and grade student submissions for activities and assignments.

## Features

### Student Submissions Screen (`student_submissions_screen.dart`)
- **Overview**: Lists all student submissions for a specific activity/assignment
- **Statistics**: Shows total submissions, graded count, pending count, and late submissions
- **Filtering**: Filter submissions by status (All, Submitted, Graded, Late)
- **Student Information**: Displays student name, ID, submission time, and file count
- **Status Indicators**: Visual status badges with colors and icons
- **Navigation**: Click on any submission to view detailed information

### Submission Detail Screen (`submission_detail_screen.dart`)
- **Student Information**: Complete student profile with avatar and details
- **File Management**: View, preview, and download submitted files
- **File Type Support**: Different icons and colors for various file types (PDF, DOCX, Excel, ZIP, Python, etc.)
- **Grading Panel**: 
  - Score input with validation
  - Comments section for feedback
  - Save grade functionality
  - Mark as done option
  - Return to student feature
- **Real-time Updates**: Visual feedback for grading status

## Navigation Flow

1. **From Class Detail Screen**:
   - Click on any activity/assignment in the Stream tab
   - Or use the "View Submissions" option in the Created Items tab menu

2. **From Submissions List**:
   - Click on any student submission card
   - Navigate to detailed submission view

3. **From Submission Detail**:
   - Grade the submission
   - Add comments
   - Mark as done
   - Return to submissions list

## UI Components

### Status Indicators
- **Submitted**: Blue with upload icon
- **Graded**: Green with check circle icon  
- **Late**: Orange with schedule icon

### File Type Support
- **PDF**: Red with PDF icon
- **DOCX/DOC**: Blue with document icon
- **Excel**: Green with table icon
- **ZIP**: Orange with archive icon
- **Python**: Yellow with code icon

### Statistics Cards
- Total submissions count
- Graded submissions count
- Pending submissions count
- Late submissions count

## Sample Data Structure

The screens use sample data that includes:
- Student information (name, ID, avatar)
- Submission details (time, status, files)
- File information (name, type, size)
- Grading data (score, comments, status)

## Future Enhancements

- Real backend integration
- File preview functionality
- Bulk grading operations
- Grade analytics and statistics
- Email notifications for students
- Plagiarism detection integration
