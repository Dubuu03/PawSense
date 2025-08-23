import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final bool? isActive; // New field for suspension status
  final String? suspensionReason; // New field for suspension reason
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const UserCard({
    Key? key,
    required this.user,
    this.isActive,
    this.suspensionReason,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: kTextStyleRegular.copyWith(
                  color: _getRoleColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: kSpacingMedium),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDisplayName(),
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: kSpacingSmall),
                Text(
                  user.email,
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    _buildRoleChip(),
                    SizedBox(width: kSpacingSmall),
                    Text(
                      'Joined: ${_formatDate(user.createdAt)}',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(),
              SizedBox(height: kSpacingMedium),
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final userIsActive = _isActive();
    final isVerified = true; // You can add verification logic here based on your data
    
    // Determine status based on active state and verification
    String statusText;
    IconData statusIcon;
    Color statusColor;
    Color bgColor;
    
    if (!userIsActive) {
      statusText = 'Suspended';
      statusIcon = Icons.block;
      statusColor = AppColors.error;
      bgColor = AppColors.statusOpenBg;
    } else if (isVerified) {
      statusText = 'Verified';
      statusIcon = Icons.verified;
      statusColor = AppColors.success;
      bgColor = AppColors.statusResolvedBg;
    } else {
      statusText = 'Pending';
      statusIcon = Icons.pending;
      statusColor = AppColors.warning;
      bgColor = AppColors.statusInProgressBg;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingSmall + 2, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: kTextStyleSmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final userIsActive = _isActive();
    final isVerified = true; // You can add verification logic here
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View/Info Icon
        Container(
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.visibility_outlined, size: 18),
            color: AppColors.info,
            tooltip: 'View Details',
            padding: EdgeInsets.all(6),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
        SizedBox(width: kSpacingSmall),
        
        // Status Action Icon (Suspend/Activate or Approve/Reject)
        if (!userIsActive) ...[
          // Activate button for suspended users
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () => onStatusToggle(true),
              icon: Icon(Icons.check_circle, size: 18),
              color: AppColors.success,
              tooltip: 'Activate User',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ] else if (!isVerified) ...[
          // Approve button for pending users
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () => onStatusToggle(true),
              icon: Icon(Icons.check, size: 18),
              color: AppColors.success,
              tooltip: 'Approve User',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          SizedBox(width: kSpacingSmall),
          // Reject button for pending users  
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () => onStatusToggle(false),
              icon: Icon(Icons.close, size: 18),
              color: AppColors.error,
              tooltip: 'Reject User',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ] else ...[
          // Suspend button for active verified users
          Container(
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () => onStatusToggle(false),
              icon: Icon(Icons.block, size: 18),
              color: AppColors.warning,
              tooltip: 'Suspend User',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
        
        if (userIsActive || !isVerified) ...[
          SizedBox(width: kSpacingSmall),
          // Delete Icon
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 18),
              color: AppColors.error,
              tooltip: 'Delete User',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoleChip() {
    final roleColor = _getRoleColor();
    final roleBackgroundColor = _getRoleBackgroundColor();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
      decoration: BoxDecoration(
        color: roleBackgroundColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Text(
        _formatRoleName(user.role),
        style: kTextStyleSmall.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      default:
        return role.toUpperCase();
    }
  }

  String _getDisplayName() {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
    }
    return user.username;
  }

  String _getInitials() {
    final displayName = _getDisplayName();
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  Color _getRoleColor() {
    switch (user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdmin;
      case 'admin':
        return AppColors.roleAdmin;
      case 'user':
        return AppColors.roleUser;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _getRoleBackgroundColor() {
    switch (user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdminBg;
      case 'admin':
        return AppColors.roleAdminBg;
      case 'user':
        return AppColors.roleUserBg;
      default:
        return AppColors.border;
    }
  }

  bool _isActive() {
    // Use the provided isActive status, default to true if not provided
    return isActive ?? true;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
