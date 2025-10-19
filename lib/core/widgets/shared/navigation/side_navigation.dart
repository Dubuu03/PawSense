import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'nav_item.dart';

class SideNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userRole; // Add user role parameter

  // Admin contact details
  final String? adminName;
  final String? adminEmail;
  final String? adminPhone;

  const SideNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userRole = 'admin', // Default to admin role
    this.adminName,
    this.adminEmail,
    this.adminPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(2, 0), // Shadow to the right
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.2)),
          SizedBox(height: 24),
          _buildNavItems(),
          Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.2)),
          _buildEmergencyContact(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: EdgeInsets.fromLTRB(32, 24, 24, 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/img/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'PawSense',
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    // Get role-based routes from router configuration
    final routes = AppRouter.getRoutesForRole(userRole);

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return NavItem(
            icon: route.icon,
            title: route.title,
            isActive: selectedIndex == index,
            onTap: () => onItemSelected(index),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyContact() {
    // Show different content based on role
    if (userRole == 'super_admin') {
      return _buildSuperAdminInfo();
    } else {
      return _buildAdminContactInfo();
    }
  }

  Widget _buildSuperAdminInfo() {
    return Container(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Information',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Super Administrator',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.security, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Full System Access',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactInfo() {
    return Container(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Contact',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          if (adminName != null && adminName!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.person, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adminName!,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (adminPhone != null && adminPhone!.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adminPhone!,
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (adminEmail != null && adminEmail!.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email, size: 15, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adminEmail!,
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
