import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'nav_item.dart';

class SideNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  // Default fake contact details (can be replaced later with dynamic values)
  final String emergencyPhone;
  final String emergencyEmail;

  const SideNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.emergencyPhone = '+63 912 345 6789',
    this.emergencyEmail = 'support@clinicdemo.com',
  }) : super(key: key);

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
    final items = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.calendar_today, 'title': 'Appointment\nManagement'},
      {'icon': Icons.folder_open, 'title': 'Patient Records'},
      {'icon': Icons.schedule, 'title': 'Clinic Schedule'},
      {'icon': Icons.person_outline, 'title': 'Vet Profile & Services'},
      {'icon': Icons.notifications_outlined, 'title': 'Notifications'},
      {'icon': Icons.help_outline, 'title': 'Support'},
      {'icon': Icons.settings_outlined, 'title': 'Settings'},
    ];

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return NavItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
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
