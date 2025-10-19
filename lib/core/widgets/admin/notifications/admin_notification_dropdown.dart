import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/admin/admin_notification_model.dart';
import 'package:pawsense/core/services/admin/admin_notification_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/time_formatter.dart';

class AdminNotificationDropdown extends StatefulWidget {
  final List<AdminNotificationModel> notifications;
  final VoidCallback? onMarkAllRead;
  final Function(AdminNotificationModel)? onNotificationTap;
  final Function(AdminNotificationModel)? onNotificationDismiss;

  const AdminNotificationDropdown({
    super.key,
    required this.notifications,
    this.onMarkAllRead,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  State<AdminNotificationDropdown> createState() => _AdminNotificationDropdownState();
}

class _AdminNotificationDropdownState extends State<AdminNotificationDropdown> {
  final ScrollController _scrollController = ScrollController();
  final AdminNotificationService _notificationService = AdminNotificationService();
  int _displayCount = 20; // Initial load
  Timer? _timeUpdateTimer;
  String _selectedFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Update time display every minute
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Check if scrolled to bottom (with 200px threshold)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Calculate total filtered notifications
      List<AdminNotificationModel> filteredNotifications;
      switch (_selectedFilter) {
        case 'unread':
          filteredNotifications = widget.notifications.where((n) => !n.isRead).toList();
          break;
        case 'read':
          filteredNotifications = widget.notifications.where((n) => n.isRead).toList();
          break;
        default:
          filteredNotifications = widget.notifications;
      }
      
      if (_displayCount < filteredNotifications.length) {
        setState(() {
          // Load 20 more notifications
          _displayCount = (_displayCount + 20).clamp(0, filteredNotifications.length);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 AdminNotificationDropdown building with ${widget.notifications.length} notifications');
    if (widget.notifications.isNotEmpty) {
      print('   First notification: "${widget.notifications.first.title}" (read: ${widget.notifications.first.isRead})');
    }
    
    // Filter notifications based on selected filter
    List<AdminNotificationModel> filteredNotifications;
    switch (_selectedFilter) {
      case 'unread':
        filteredNotifications = widget.notifications.where((n) => !n.isRead).toList();
        break;
      case 'read':
        filteredNotifications = widget.notifications.where((n) => n.isRead).toList();
        break;
      default:
        filteredNotifications = widget.notifications;
    }
    
    // Take only the number we want to display (for infinite scroll)
    final displayNotifications = filteredNotifications.take(_displayCount).toList();
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;
    
    print('   Displaying ${displayNotifications.length} notifications, ${unreadCount} unread');

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 600), // Increased for better scrolling
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(unreadCount),
          
          // Filter tabs
          _buildFilterTabs(),
          
          // Notifications list
          if (displayNotifications.isEmpty)
            _buildEmptyState()
          else
            _buildNotificationsList(displayNotifications, filteredNotifications.length),
        ],
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unreadCount > 0)
            GestureDetector(
              onTap: widget.onMarkAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: kFontSizeSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _buildFilterTab('All', 'all'),
          _buildFilterTab('Unread', 'unread'),
          _buildFilterTab('Read', 'read'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
            _displayCount = 20; // Reset display count when changing filter
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: kFontSizeSmall,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: kFontSizeRegular,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: kFontSizeSmall,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<AdminNotificationModel> displayNotifications, int totalFilteredCount) {
    return Flexible(
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: displayNotifications.length + (_displayCount < totalFilteredCount ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: AppColors.border,
        ),
        itemBuilder: (context, index) {
          // Show loading indicator at the end if there are more notifications
          if (index == displayNotifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          
          final notification = displayNotifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AdminNotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
        ),
      ),
      onDismissed: (direction) {
        widget.onNotificationDismiss?.call(notification);
      },
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
          // Call the tap handler
          widget.onNotificationTap?.call(notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              // Icon based on notification type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: _getNotificationColor(notification),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: kFontSizeRegular,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: kFontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getNotificationColor(notification),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimeAgo(notification.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    return TimeFormatter.getRelativeTime(timestamp);
  }

  Color _getNotificationColor(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.appointment:
        return AppColors.success;
      case AdminNotificationType.message:
        return AppColors.info;
      case AdminNotificationType.transaction:
        return AppColors.warning;
      case AdminNotificationType.emergency:
        return AppColors.error;
      case AdminNotificationType.system:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.appointment:
        return notification.priority == AdminNotificationPriority.urgent
            ? Icons.medical_services
            : Icons.event_note;
      case AdminNotificationType.message:
        return Icons.message;
      case AdminNotificationType.transaction:
        return Icons.receipt_long;
      case AdminNotificationType.emergency:
        return Icons.emergency;
      case AdminNotificationType.system:
        return Icons.info_outline;
    }
  }
}

/// A more detailed notification screen for viewing all notifications
class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final AdminNotificationService _notificationService = AdminNotificationService();
  AdminNotificationType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              _notificationService.markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),
          
          // Notifications list
          Expanded(
            child: StreamBuilder<List<AdminNotificationModel>>(
              stream: _notificationService.notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];
                final filteredNotifications = _selectedFilter == null
                    ? notifications
                    : notifications.where((n) => n.type == _selectedFilter).toList();

                if (filteredNotifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'label': 'All', 'type': null},
      {'label': 'Appointments', 'type': AdminNotificationType.appointment},
      {'label': 'Messages', 'type': AdminNotificationType.message},
      {'label': 'Emergency', 'type': AdminNotificationType.emergency},
    ];

    return Container(
      height: 50,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedFilter == tab['type'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilterChip(
              label: Text(tab['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? tab['type'] as AdminNotificationType? : null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotificationModel notification) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? AppColors.white : AppColors.primary.withValues(alpha: 0.02),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification),
            color: _getNotificationColor(notification),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notification.typeDisplayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getNotificationColor(notification),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
          
          if (notification.actionUrl != null) {
            context.go(notification.actionUrl!);
          }
        },
      ),
    );
  }

  Color _getNotificationColor(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.appointment:
        // Use different colors based on appointment status
        return _getAppointmentStatusColor(notification);
      case AdminNotificationType.message:
        return AppColors.info;
      case AdminNotificationType.transaction:
        return AppColors.warning;
      case AdminNotificationType.emergency:
        return AppColors.error;
      case AdminNotificationType.system:
        return AppColors.textSecondary;
    }
  }

  Color _getAppointmentStatusColor(AdminNotificationModel notification) {
    // Check metadata for appointment status
    final status = notification.metadata?['status'] as String?;
    final isAutoCancelled = notification.metadata?['isAutoCancelled'] == true;
    final isNoShow = notification.metadata?['isNoShow'] == true;
    print('🎨 Getting color for notification: ${notification.title}, status: $status, autoCancelled: $isAutoCancelled, noShow: $isNoShow, metadata: ${notification.metadata}');
    
    // Auto-cancelled appointments always show RED
    if (isAutoCancelled) {
      return AppColors.error; // RED for auto-cancelled
    }
    
    // No-show appointments always show ORANGE
    if (isNoShow) {
      return const Color(0xFFFF9800); // ORANGE for no-show
    }
    
    if (status != null) {
      switch (status.toLowerCase()) {
        case 'pending':
          return AppColors.warning; // Orange for pending appointments
        case 'confirmed':
          return AppColors.info; // Blue for confirmed appointments  
        case 'completed':
          return AppColors.success; // Green for completed appointments
        case 'cancelled':
        case 'rejected':
          return AppColors.error; // Red for cancelled/rejected appointments
        case 'rescheduled':
          return AppColors.warning; // Orange for rescheduled appointments
        case 'noshow':
          return const Color(0xFFFF9800); // Orange for no-show appointments
        default:
          return AppColors.success; // Default green for appointment notifications
      }
    }
    
    // Fallback to default appointment color if no status found
    return AppColors.success;
  }

  IconData _getNotificationIcon(AdminNotificationModel notification) {
    switch (notification.type) {
      case AdminNotificationType.appointment:
        return _getAppointmentStatusIcon(notification);
      case AdminNotificationType.message:
        return Icons.message;
      case AdminNotificationType.transaction:
        return Icons.receipt_long;
      case AdminNotificationType.emergency:
        return Icons.emergency;
      case AdminNotificationType.system:
        return Icons.info_outline;
    }
  }

  IconData _getAppointmentStatusIcon(AdminNotificationModel notification) {
    // Check for urgent priority first
    if (notification.priority == AdminNotificationPriority.urgent) {
      return Icons.medical_services;
    }
    
    // Check metadata for appointment status
    final status = notification.metadata?['status'] as String?;
    print('🎯 Getting icon for notification: ${notification.title}, status: $status');
    
    if (status != null) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Icons.schedule; // Clock icon for pending appointments
        case 'confirmed':
          return Icons.event_available; // Calendar check icon for confirmed
        case 'completed':
          return Icons.task_alt; // Checkmark icon for completed
        case 'cancelled':
        case 'rejected':
          return Icons.event_busy; // X calendar icon for cancelled/rejected
        case 'rescheduled':
          return Icons.update; // Update icon for rescheduled
        default:
          return Icons.event_note; // Default calendar note icon
      }
    }
    
    // Fallback to default appointment icon
    return Icons.event_note;
  }
}