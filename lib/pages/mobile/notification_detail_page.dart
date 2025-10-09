import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';
import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/utils/notification_helper.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/pages/mobile/messaging/conversation_page.dart';

class NotificationDetailPage extends StatefulWidget {
  final String notificationId;
  final AlertData? alertData; // Optional alert data passed from alerts page

  const NotificationDetailPage({
    super.key,
    required this.notificationId,
    this.alertData,
  });

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  NotificationModel? _notification;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotification();
  }

  Future<void> _loadNotification() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // If alertData was passed, convert it to NotificationModel
      if (widget.alertData != null) {
        final notification = NotificationHelper.toNotificationModel(widget.alertData!);
        
        // Mark as read
        if (!notification.isRead) {
          await NotificationService.markAsRead(widget.notificationId);
        }
        
        if (mounted) {
          setState(() {
            _notification = notification;
            _isLoading = false;
          });
        }
        return;
      }

      // Otherwise, try to fetch from database
      final notification = await NotificationService.getNotificationById(widget.notificationId);
      
      if (notification == null) {
        setState(() {
          _error = 'Notification not found';
          _isLoading = false;
        });
        return;
      }

      // Mark as read
      if (!notification.isRead) {
        await NotificationService.markAsRead(widget.notificationId);
      }

      if (mounted) {
        setState(() {
          _notification = notification;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load notification';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notification',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error loading notification',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_notification == null) return const SizedBox.shrink();

    final notification = _notification!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          _buildHeaderCard(notification),
          
          const SizedBox(height: 12),
          
          // Details Section
          if (notification.category == NotificationCategory.appointment)
            _buildAppointmentDetails(notification),
          
          // Next Steps Section
          if (notification.category == NotificationCategory.appointment &&
              notification.metadata != null)
            _buildNextStepsSection(notification),
          
          // Action Buttons
          _buildActionButtons(notification),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getCategoryColor(notification.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(notification.category),
                  color: _getCategoryColor(notification.category),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(notification.priority),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getPriorityText(notification.priority),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityTextColor(notification.priority),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails(NotificationModel notification) {
    final metadata = notification.metadata ?? {};
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Clinic
          if (metadata['clinicName'] != null)
            _buildDetailRow(
              icon: Icons.local_hospital,
              iconColor: AppColors.primary,
              label: 'Clinic:',
              value: metadata['clinicName'] as String,
            ),
          
          // Date & Time
          if (metadata['appointmentDate'] != null)
            _buildDetailRow(
              icon: Icons.access_time,
              iconColor: AppColors.warning,
              label: 'When:',
              value: _formatAppointmentDateTime(
                metadata['appointmentDate'] as String,
                metadata['appointmentTime'] as String?,
              ),
            ),
          
          // Pet
          if (metadata['petName'] != null)
            _buildDetailRow(
              icon: Icons.pets,
              iconColor: AppColors.success,
              label: 'Pet:',
              value: metadata['petName'] as String,
            ),
          
          // Status
          if (metadata['status'] != null)
            _buildDetailRow(
              icon: Icons.info_outline,
              iconColor: _getStatusColor(metadata['status'] as String),
              label: 'Status:',
              value: _formatStatus(metadata['status'] as String),
              isLast: true, // Made this the last item
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsSection(NotificationModel notification) {
    final status = notification.metadata?['status'] as String?;
    
    List<String> steps = [];
    
    if (status == 'pending') {
      steps = [
        'Wait for clinic confirmation (usually within 24 hours)',
        'You\'ll receive a notification once confirmed',
        'Prepare your pet\'s medical history if available',
      ];
    } else if (status == 'confirmed') {
      final daysUntil = notification.metadata?['daysUntil'] as int?;
      
      if (daysUntil != null && daysUntil <= 7) {
        steps = [
          'Bring recent photos or AI scan results for better assessment',
          'Arrive 10 minutes early to complete any paperwork',
          'Prepare your pet\'s medical history if available',
          'Note any recent behavioral or health changes',
        ];
      }
    } else if (status == 'rescheduled') {
      steps = [
        'Check the new appointment date and time above',
        'Add to your calendar to avoid missing it',
        'Contact clinic if the new time doesn\'t work',
      ];
    }
    
    if (steps.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < steps.length - 1 ? 12 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary action button
          if (notification.actionUrl != null && notification.actionLabel != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to action URL
                  context.push(notification.actionUrl!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  notification.actionLabel!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Secondary action - Contact clinic (for appointments)
          if (notification.category == NotificationCategory.appointment &&
              notification.metadata?['clinicName'] != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () async {
                  // Navigate to messaging with specific clinic
                  final clinicId = notification.metadata?['clinicId'] as String?;
                  final clinicName = notification.metadata?['clinicName'] as String?;
                  
                  if (clinicId != null && clinicName != null) {
                    try {
                      // Create or get conversation with the clinic
                      final conversationId = await MessagingService.createOrGetConversation(clinicId, clinicName);
                      
                      if (conversationId != null) {
                        // Get the conversation object and navigate to it
                        final conversations = await MessagingService.getUserConversations().first;
                        final conversation = conversations.firstWhere(
                          (conv) => conv.id == conversationId,
                          orElse: () => throw Exception('Conversation not found'),
                        );
                        
                        // Navigate to the specific conversation
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConversationPage(conversation: conversation),
                          ),
                        );
                      } else {
                        // Fallback to general messaging page
                        context.push('/messaging');
                      }
                    } catch (e) {
                      print('Error opening conversation: $e');
                      // Fallback to general messaging page
                      context.push('/messaging');
                    }
                  } else {
                    // Fallback to general messaging page if no clinic info
                    context.push('/messaging');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Message clinic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category) {
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

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.appointment:
        return Icons.event_available;
      case NotificationCategory.message:
        return Icons.message;
      case NotificationCategory.task:
        return Icons.assignment;
      case NotificationCategory.system:
        return Icons.system_update;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return AppColors.success.withOpacity(0.1);
      case NotificationPriority.medium:
        return AppColors.warning.withOpacity(0.1);
      case NotificationPriority.high:
        return Colors.orange.withOpacity(0.1);
      case NotificationPriority.urgent:
        return AppColors.error.withOpacity(0.1);
    }
  }

  Color _getPriorityTextColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return AppColors.success;
      case NotificationPriority.medium:
        return AppColors.warning;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return AppColors.error;
    }
  }

  String _getPriorityText(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Reminder';
      case NotificationPriority.high:
        return 'Important';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      case 'rescheduled':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
    }
  }

  String _formatAppointmentDateTime(String dateString, String? time) {
    try {
      final date = DateTime.parse(dateString);
      final weekday = _getWeekday(date.weekday);
      final month = _getMonth(date.month);
      final formattedDate = '$weekday, $month ${date.day}, ${date.year}';
      
      if (time != null && time.isNotEmpty) {
        return '$formattedDate at $time';
      }
      return formattedDate;
    } catch (e) {
      return dateString + (time != null ? ' at $time' : '');
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
