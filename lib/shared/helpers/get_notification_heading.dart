String getNotificationHeading(String type, String instructorName) {
  switch (type.toLowerCase()) {
    case 'assignment':
      return 'New Assignment from $instructorName';
    case 'activity':
      return 'New Activity from $instructorName';
    case 'quiz':
      return 'New Quiz from $instructorName';
    case 'pit':
      return 'New PIT from $instructorName';
    case 'material':
      return 'New Material from $instructorName';
    case 'announcement':
      return 'New Announcement from $instructorName';
    case 'graded':
      return 'Your work has been graded';
    case 'enrollment_approved':
      return 'Enrollment Approved';
    case 'enrollment_rejected':
      return 'Enrollment Rejected';
    default:
      return 'New Notification from $instructorName';
  }
}
