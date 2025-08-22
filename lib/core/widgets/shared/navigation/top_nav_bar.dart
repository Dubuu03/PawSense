import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'profile_popup_modal.dart';

class TopNavBar extends StatefulWidget {
  final String clinicTitle;
  final String userInitials;
  final String userName;
  final String userRole;
  final bool hasNotifications;
  final VoidCallback? onProfileTap; // callback when clicking name + avatar
  final VoidCallback? onSignOut; // callback for sign out

  const TopNavBar({
    super.key,
    this.clinicTitle = 'Veterinary Clinic Dashboard',
    this.userInitials = 'SJ',
    this.userName = 'Dr. Sarah Johnson',
    this.userRole = 'Veterinarian',
    this.hasNotifications = true,
    this.onProfileTap,
    this.onSignOut,
  });

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  final GlobalKey _profileButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  @override
  void dispose() {
    _closeMenu();
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
                      _closeMenu();
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
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Left: Clinic title
          Text(
            widget.clinicTitle,
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),

          // Notification button
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
                        widget.userRole,
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          if (widget.hasNotifications)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}