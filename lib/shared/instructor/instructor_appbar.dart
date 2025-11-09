import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/in_app_notification_service.dart';

class InstructorAppBar extends StatefulWidget {
  final String instructorName;
  final String instructorRole;
  final String? profileImageUrl;

  const InstructorAppBar({
    super.key,
    required this.instructorName,
    this.instructorRole = 'Instructor',
    this.profileImageUrl,
  });

  @override
  State<InstructorAppBar> createState() => _InstructorAppBarState();
}

class _InstructorAppBarState extends State<InstructorAppBar> {
  bool _isNotificationHovered = false;
  bool _showNotificationDropdown = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _notificationBellKey = GlobalKey();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final notifications =
          await InAppNotificationService.getNotificationsForInstructor();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoadingNotifications = false;
        });
      }
    }
  }

  void _toggleNotificationDropdown() {
    if (_showNotificationDropdown) {
      _removeOverlay();
    } else {
      // Always refresh notifications when opening dropdown
      _loadNotifications();
      _showOverlay();
    }
  }

  bool get _hasUnreadNotifications {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    return _notifications.any((notification) {
      final readBy = List<String>.from(notification['readBy'] ?? []);
      return !readBy.contains(userId);
    });
  }

  int get _unreadCount {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;
    return _notifications.where((notification) {
      final readBy = List<String>.from(notification['readBy'] ?? []);
      return !readBy.contains(userId);
    }).length;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showNotificationDropdown = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showNotificationDropdown = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox =
        _notificationBellKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    return OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final padding = mediaQuery.padding;

        // Calculate responsive width
        // Desktop: max 380px, Tablet: 90% of screen, Mobile: 95% of screen
        double dropdownWidth;
        if (screenWidth > 768) {
          dropdownWidth = 380;
        } else if (screenWidth > 480) {
          dropdownWidth = screenWidth * 0.9;
        } else {
          dropdownWidth = screenWidth * 0.95;
        }

        // Calculate position - ensure it doesn't go off screen
        double leftPosition = offset.dx;
        double topPosition = offset.dy + size.height + 8;

        // Adjust if dropdown would go off right edge
        if (leftPosition + dropdownWidth > screenWidth - 16) {
          leftPosition = screenWidth - dropdownWidth - 16;
        }

        // Ensure minimum left margin
        if (leftPosition < 16) {
          leftPosition = 16;
        }

        // Calculate max height - ensure it doesn't go off bottom
        final availableHeight =
            screenHeight - topPosition - padding.bottom - 16;
        // Ensure minimum height of 200px, max of 500px
        final maxDropdownHeight =
            availableHeight < 200
                ? 200.0
                : (availableHeight > 500 ? 500.0 : availableHeight);

        return Stack(
          children: [
            // Full screen transparent overlay to close on outside tap
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Dropdown content positioned below the bell icon
            Positioned(
              left: leftPosition,
              top: topPosition,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside dropdown
                child: _buildNotificationDropdownContent(
                  width: dropdownWidth,
                  maxHeight: maxDropdownHeight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _closeNotificationDropdown() {
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // Notification Bell Icon (left side)
          _buildNotificationBell(),
          const Spacer(),
          // Instructor avatar and name
          Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.instructorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.instructorRole,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build notification bell icon with badge indicator
  Widget _buildNotificationBell() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isNotificationHovered = true),
      onExit: (_) => setState(() => _isNotificationHovered = false),
      child: GestureDetector(
        onTap: _toggleNotificationDropdown,
        child: Container(
          key: _notificationBellKey,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _showNotificationDropdown
                    ? const Color(0xFF34A853).withOpacity(0.15)
                    : _isNotificationHovered
                    ? const Color(0xFF34A853).withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                _showNotificationDropdown
                    ? Icons.notifications
                    : Icons.notifications_outlined,
                color:
                    _showNotificationDropdown || _isNotificationHovered
                        ? const Color(0xFF34A853)
                        : Colors.black87,
                size: 24,
              ),
              // Badge indicator (UI only for now)
              if (_hasUnreadNotifications && !_showNotificationDropdown)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        _unreadCount > 9
                            ? const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            )
                            : const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      shape:
                          _unreadCount > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                      borderRadius:
                          _unreadCount > 9 ? BorderRadius.circular(10) : null,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build notification dropdown panel content
  Widget _buildNotificationDropdownContent({
    required double width,
    required double maxHeight,
  }) {
    final unreadCount = _unreadCount;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: width > 480 ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _closeNotificationDropdown,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Notification List or Empty State
            if (_isLoadingNotifications)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF34A853),
                    ),
                  ),
                ),
              )
            else if (_notifications.isEmpty)
              _buildEmptyState()
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(_notifications[index]);
                  },
                ),
              ),
            // Footer - View All button
            if (_notifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Navigation will be added later
                      _closeNotificationDropdown();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View All Notifications',
                      style: TextStyle(
                        color: const Color(0xFF34A853),
                        fontWeight: FontWeight.w600,
                        fontSize: width > 480 ? 14 : 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final readBy = List<String>.from(notification['readBy'] ?? []);
    final isRead = userId != null && readBy.contains(userId);
    final type =
        notification['activityType']?.toString() ??
        notification['type']?.toString() ??
        'activity';
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);
    final createdAt = notification['createdAt'];
    final timeAgo = _formatTimeAgo(createdAt);

    return InkWell(
      onTap: () async {
        // Mark as read when tapped
        final notificationId = notification['id'];
        if (notificationId != null) {
          await InAppNotificationService.markAsRead(
            notificationId: notificationId,
          );
          // Refresh notifications
          _loadNotifications();
        }
        // Navigation will be added later
        // _closeNotificationDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F9FF),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 10, color: Colors.black38),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF34A853),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build empty state for notifications
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      constraints: const BoxConstraints(minHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Format timestamp to time ago string
  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      DateTime? dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return const Color(0xFF2886D7);
      case 'activity':
        return const Color(0xFF43A047);
      case 'quiz':
        return const Color(0xFF8B5CF6);
      case 'pit':
        return const Color(0xFFFF9800);
      case 'material':
        return const Color(0xFF34A853);
      default:
        return const Color(0xFF34A853);
    }
  }

  /// Get notification icon based on type
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'activity':
        return Icons.assignment_turned_in;
      case 'quiz':
        return Icons.quiz;
      case 'pit':
        return Icons.school;
      case 'material':
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  /// Build profile avatar with image or initials
  Widget _buildProfileAvatar() {
    // Get initials from name
    String getInitials(String name) {
      if (name.isEmpty) return '';
      final parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    final initials = getInitials(widget.instructorName);
    final hasImage =
        widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 22,
      backgroundColor: hasImage ? Colors.transparent : Colors.blue.shade700,
      backgroundImage: hasImage ? NetworkImage(widget.profileImageUrl!) : null,
      child:
          !hasImage
              ? Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
              : null,
    );
  }
}
