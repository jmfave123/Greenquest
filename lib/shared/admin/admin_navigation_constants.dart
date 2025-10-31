enum AdminNavigationItem {
  dashboard,
  manageInstructors,
  manageDepartments,
  manageClasses,
}

class AdminNavigationHelper {
  static String getRoute(AdminNavigationItem item) {
    switch (item) {
      case AdminNavigationItem.dashboard:
        return '/admin-dashboard';
      case AdminNavigationItem.manageInstructors:
        return '/admin-manage-instructors';
      case AdminNavigationItem.manageDepartments:
        return '/admin-manage-departments';
      case AdminNavigationItem.manageClasses:
        return '/admin-manage-classes';
    }
  }
}
