// Constants file for instructor navigation
// This file centralizes all navigation-related constants and makes it easier
// to maintain and update the instructor sidebar

// Enum for navigation items to ensure type safety
enum InstructorNavigationItem {
  dashboard,
  create,
  classManagement,
  messages,
  announcements,
  plantedTrees,
  reports,
  profile,
}

// Helper class to convert between the old index-based system and new enum-based system
class InstructorNavigationHelper {
  // Convert old index to new enum (for backward compatibility)
  static InstructorNavigationItem indexToEnum(int index) {
    switch (index) {
      case 0:
        return InstructorNavigationItem.dashboard;
      case 1:
        return InstructorNavigationItem.create;
      case 2:
        return InstructorNavigationItem.classManagement;
      case 3:
        return InstructorNavigationItem.messages;
      case 4:
        return InstructorNavigationItem.announcements;
      case 5:
        return InstructorNavigationItem.plantedTrees;
      case 6:
        return InstructorNavigationItem.reports;
      case -1:
        return InstructorNavigationItem.profile;
      default:
        return InstructorNavigationItem.dashboard;
    }
  }

  // Convert enum to index (for backward compatibility)
  static int enumToIndex(InstructorNavigationItem item) {
    switch (item) {
      case InstructorNavigationItem.dashboard:
        return 0;
      case InstructorNavigationItem.create:
        return 1;
      case InstructorNavigationItem.classManagement:
        return 2;
      case InstructorNavigationItem.messages:
        return 3;
      case InstructorNavigationItem.announcements:
        return 4;
      case InstructorNavigationItem.plantedTrees:
        return 5;
      case InstructorNavigationItem.reports:
        return 6;
      case InstructorNavigationItem.profile:
        return -1;
    }
  }

  // Get the route for a navigation item
  static String getRoute(InstructorNavigationItem item) {
    switch (item) {
      case InstructorNavigationItem.dashboard:
        return '/instructor-dashboard';
      case InstructorNavigationItem.create:
        return '/instructor-create';
      case InstructorNavigationItem.classManagement:
        return '/instructor-class';
      case InstructorNavigationItem.messages:
        return '/instructor-message-list';
      case InstructorNavigationItem.announcements:
        return '/instructor-announcement';
      case InstructorNavigationItem.plantedTrees:
        return '/instructor-planted-trees';
      case InstructorNavigationItem.reports:
        return '/instructor-report';
      case InstructorNavigationItem.profile:
        return '/instructor-profile';
    }
  }
}
