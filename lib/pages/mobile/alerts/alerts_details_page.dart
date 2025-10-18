import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';
import 'package:pawsense/core/services/notifications/notification_service.dart';

class AlertDetailsPage extends StatefulWidget {
  final String notificationId;
  
  const AlertDetailsPage({
    super.key,
    required this.notificationId,
  });

  @override
  State<AlertDetailsPage> createState() => _AlertDetailsPageState();
}

class _AlertDetailsPageState extends State<AlertDetailsPage> {
  NotificationModel? _notification;
  bool _loading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationDetails();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadNotificationDetails() async {
    if (!_mounted) return;
    
    try {
      final notification = await NotificationService.getNotificationById(widget.notificationId);
      
      if (!_mounted) return; // Check again after async operation
      
      if (notification != null && !notification.isRead) {
        // Mark as read when viewing details - don't wait for this
        NotificationService.markNotificationAsRead(widget.notificationId).catchError((e) {
          print('Warning: Failed to mark notification as read: $e');
        });
      }
      
      if (_mounted) {
        setState(() {
          _notification = notification;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading notification details: $e');
      if (_mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _notification == null 
          ? _buildNotFoundMessage()
          : _buildNotificationDetails(),
    );
  }

  Widget _buildNotFoundMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Notification not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This alert may have been deleted or expired.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDetails() {
    final notification = _notification!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border(
                left: BorderSide(
                  color: _getNotificationColor(notification.category),
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.category),
                        color: _getNotificationColor(notification.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(notification.category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getCategoryDisplayName(notification.category),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getNotificationColor(notification.category),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message Content Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Metadata Card (if available)
          if (notification.metadata != null && notification.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            // Combined Cancellation Status + Reason Card (for cancelled appointments)
            if (notification.metadata!['cancelReason'] != null && 
                notification.metadata!['cancelReason'].toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Cancelled Status Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.cancel_outlined,
                              color: AppColors.error,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Cancelled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'This appointment was cancelled',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cancellation Reason Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Cancellation Reason',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notification.metadata!['cancelReason'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Regular Metadata Card (excluding cancelReason as it's shown separately)
            if (_buildMetadataRows(notification.metadata!).isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildMetadataRows(notification.metadata!),
                  ],
                ),
              ),
            ],
          ],

          // Action Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_hasActionUrl(notification)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAction(notification),
                      icon: Icon(_getActionIcon(notification.category)),
                      label: Text(_getActionText(notification.category)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getNotificationColor(notification.category),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/alerts'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Alerts',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataRows(Map<String, dynamic> metadata) {
    // Exclude cancelReason from metadata rows as it's shown separately
    final filteredMetadata = Map<String, dynamic>.from(metadata)
      ..remove('cancelReason');
    
    if (filteredMetadata.isEmpty) {
      return [];
    }
    
    return filteredMetadata.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '${_formatMetadataKey(entry.key)}:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  bool _hasActionUrl(NotificationModel notification) {
    return notification.metadata?['actionUrl'] != null;
  }

  void _handleAction(NotificationModel notification) {
    final actionUrl = notification.metadata?['actionUrl'] as String?;
    if (actionUrl != null) {
      context.go(actionUrl);
    }
  }

  String _getActionText(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return 'View Appointments';
      case NotificationCategory.message:
        return 'View Messages';
      case NotificationCategory.task:
        return 'View Tasks';
      case NotificationCategory.system:
        return 'Go to Settings';
    }
  }

  IconData _getActionIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return Icons.calendar_today;
      case NotificationCategory.message:
        return Icons.message_outlined;
      case NotificationCategory.task:
        return Icons.assignment_outlined;
      case NotificationCategory.system:
        return Icons.settings_outlined;
    }
  }

  Color _getNotificationColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return AppColors.success;
      case NotificationCategory.message:
        return AppColors.info;
      case NotificationCategory.task:
        return AppColors.warning;
      case NotificationCategory.system:
        return AppColors.primary;
    }
  }

  IconData _getNotificationIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return Icons.event_note;
      case NotificationCategory.message:
        return Icons.message;
      case NotificationCategory.task:
        return Icons.assignment;
      case NotificationCategory.system:
        return Icons.system_update;
    }
  }

  String _getCategoryDisplayName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return 'Appointment';
      case NotificationCategory.message:
        return 'Message';
      case NotificationCategory.task:
        return 'Task';
      case NotificationCategory.system:
        return 'System';
    }
  }
}