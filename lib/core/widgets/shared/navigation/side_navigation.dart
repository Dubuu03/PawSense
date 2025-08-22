import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'nav_item.dart';

class SideNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userRole; // Add user role parameter

  // Default fake contact details (can be replaced later with dynamic values)
  final String emergencyPhone;
  final String emergencyEmail;

  const SideNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userRole = 'admin', // Default to admin role
    this.emergencyPhone = '+63 912 345 6789',
    this.emergencyEmail = 'support@clinicdemo.com',
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
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.pets, color: AppColors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'PawSense',
            style: TextStyle(
              fontSize: kFontSizeRegular,
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
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          if (emergencyPhone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  emergencyPhone,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          if (emergencyEmail.isNotEmpty) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  emergencyEmail,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
