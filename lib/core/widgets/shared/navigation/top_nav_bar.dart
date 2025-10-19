import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../services/admin/admin_notification_service.dart';
import '../../../models/admin/admin_notification_model.dart';
import '../../admin/notifications/admin_notification_dropdown.dart';
import 'profile_popup_modal.dart';
import '../../../../pages/web/admin/appointment_screen.dart'; // Import for global key

class TopNavBar extends StatefulWidget {
  final String clinicTitle;
  final String userInitials;
  final String userName;
  final String userRole;
  final String? userRoleDisplay; // Display name for the role
  final VoidCallback? onProfileTap; // callback when clicking name + avatar
  final VoidCallback? onSignOut; // callback for sign out

  const TopNavBar({
    super.key,
    required this.clinicTitle,
    this.userInitials = 'SJ',
    this.userName = 'Dr. Sarah Johnson',
    this.userRole = 'Veterinarian',
    this.userRoleDisplay,
    this.onProfileTap,
    this.onSignOut,
  });

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  final GlobalKey _profileButtonKey = GlobalKey();
  final GlobalKey _notificationButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _notificationOverlay;
  bool _isMenuOpen = false;
  bool _isNotificationOpen = false;
  final AdminNotificationService _notificationService = AdminNotificationService();

  @override
  void initState() {
    super.initState();
    // Initialize notification service if user is admin or super admin
    if (widget.userRole.toLowerCase() == 'admin' || 
        widget.userRole.toLowerCase() == 'super_admin' ||
        widget.userRole.toLowerCase() == 'super admin') {
      _notificationService.initialize();
    }
  }

  @override
  void dispose() {
    // Clean up overlay without setState during disposal
    _overlayEntry?.remove();
    _notificationOverlay?.remove();
    _overlayEntry = null;
    _notificationOverlay = null;
    _isMenuOpen = false;
    _isNotificationOpen = false;
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox renderBox = _profileButtonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeMenu,
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top: offset.dy + size.height + 8,
                right: MediaQuery.of(context).size.width - offset.dx - size.width,
                child: Material(
                  color: Colors.transparent,
                  child: ProfilePopupModal(
                    userInitials: widget.userInitials,
                    userName: widget.userName,
                    userRole: widget.userRole,
                    onViewProfile: () {
                      _closeMenu();
                      widget.onProfileTap?.call();
                    },
                    onSettings: () {
                      _closeMenu();
                      // Navigate to settings will be handled by the modal
                    },
                    onToggleDarkMode: () {
                      _closeMenu();
                      // Toggle dark mode will be handled by the modal
                    },
                    onHelpSupport: () {
                      _closeMenu();
                      // Navigate to help & support will be handled by the modal
                    },
                    onSignOut: () {
                      // Clean up overlay immediately without setState
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      _isMenuOpen = false;
                      widget.onSignOut?.call();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    if (mounted && _isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  void _toggleNotificationDropdown() {
    if (_isNotificationOpen) {
      _closeNotificationDropdown();
    } else {
      _openNotificationDropdown();
    }
  }

  void _openNotificationDropdown() {
    final RenderBox renderBox = _notificationButtonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _notificationOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeNotificationDropdown,
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top: offset.dy + size.height + 8,
                right: MediaQuery.of(context).size.width - offset.dx - size.width,
                child: Material(
                  color: Colors.transparent,
                  child: StreamBuilder<List<AdminNotificationModel>>(
                    stream: _notificationService.notificationsStream,
                    initialData: _notificationService.notifications, // Use current cached notifications
                    builder: (context, snapshot) {
                      print('🔄 TopNavBar StreamBuilder: hasData=${snapshot.hasData}, data length=${snapshot.data?.length ?? 0}');
                      final notifications = snapshot.data ?? [];
                      print('   Passing ${notifications.length} notifications to dropdown');
                      return AdminNotificationDropdown(
                        notifications: notifications,
                        onMarkAllRead: () {
                          _notificationService.markAllAsRead();
                        },
                        onNotificationTap: (notification) {
                          print('🔔 NOTIFICATION TAP DEBUG:');
                          print('   Title: ${notification.title}');
                          print('   Type: ${notification.type}');
                          print('   ActionURL: ${notification.actionUrl}');
                          print('   RelatedID: ${notification.relatedId}');
                          
                          _closeNotificationDropdown();
                          if (!notification.isRead) {
                            _notificationService.markAsRead(notification.id);
                          }
                          
                          // Handle appointment notifications specially
                          if (notification.type == AdminNotificationType.appointment && notification.relatedId != null) {
                            final appointmentId = notification.relatedId!;
                            
                            // Get current location from GoRouter instead of GoRouterState
                            final router = GoRouter.of(context);
                            final currentLocation = router.routeInformationProvider.value.uri.toString();
                            
                            print('   Current location: $currentLocation');
                            print('   Appointment ID: $appointmentId');
                            
                            // Check if we're already on the appointments page
                            if (currentLocation.contains('/admin/appointments')) {
                              print('✅ Already on appointments page - opening modal directly');
                              // We're already on appointments page, call the method directly using global key
                              appointmentScreenKey.currentState?.openAppointmentById(appointmentId);
                            } else {
                              print('🚀 Navigating to appointments page with appointmentId');
                              // Navigate to appointments page with the appointment ID
                              context.go('/admin/appointments?appointmentId=$appointmentId');
                            }
                            return;
                          }
                          
                          // For non-appointment notifications, use standard navigation
                          if (notification.actionUrl != null) {
                            print('🚀 Navigating to: ${notification.actionUrl}');
                            context.go(notification.actionUrl!);
                          } else {
                            print('⚠️ No actionUrl found in notification');
                          }
                        },
                        onNotificationDismiss: (notification) {
                          _notificationService.deleteNotification(notification.id);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_notificationOverlay!);
    setState(() {
      _isNotificationOpen = true;
    });
  }

  void _closeNotificationDropdown() {
    if (_notificationOverlay != null) {
      _notificationOverlay?.remove();
      _notificationOverlay = null;
    }
    if (mounted && _isNotificationOpen) {
      setState(() {
        _isNotificationOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine clinic title based on user role
    String displayTitle;
    if (widget.userRole.toLowerCase() == 'super_admin' || widget.userRole.toLowerCase() == 'super admin') {
      displayTitle = 'Super Administrator';
    } else {
      displayTitle = widget.clinicTitle;
    }

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          left: BorderSide(color: AppColors.border, width: 2),
          bottom: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: Row(
        children: [
          // Left: Clinic title
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),

          // Notification button (only for admin users)
          if (widget.userRole.toLowerCase() == 'admin' || 
              widget.userRole.toLowerCase() == 'super_admin' ||
              widget.userRole.toLowerCase() == 'super admin')
            _buildNotificationButton(),
          const SizedBox(width: 24),

          // User info group (clickable) - using custom overlay approach
          GestureDetector(
            key: _profileButtonKey,
            onTap: _toggleMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: kFontSizeRegular-2,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.userRoleDisplay ?? widget.userRole,
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.userInitials,
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<List<AdminNotificationModel>>(
      stream: _notificationService.notificationsStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        
        return GestureDetector(
          key: _notificationButtonKey,
          onTap: _toggleNotificationDropdown,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isNotificationOpen ? AppColors.primary.withValues(alpha: 0.1) : AppColors.border,
              borderRadius: BorderRadius.circular(20),
              border: _isNotificationOpen ? Border.all(color: AppColors.primary) : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: _isNotificationOpen ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}