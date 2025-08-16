import 'package:flutter/material.dart';
import 'package:pawsense/pages/web/admin/appointment_screen.dart';
import 'package:pawsense/pages/web/admin/clinic_schedule_screen.dart';
import 'package:pawsense/pages/web/admin/patient_record_screen.dart';
import 'package:pawsense/pages/web/admin/settings_screen.dart';
import 'package:pawsense/pages/web/admin/support_screen.dart';
import 'package:pawsense/pages/web/admin/vet_profile_screen.dart';
import 'package:pawsense/pages/web/superadmin/admin_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/clinic_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_analytics_screen.dart';
import 'package:pawsense/pages/web/superadmin/user_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_settings_screen.dart';
import '../../core/widgets/shared/navigation/side_navigation.dart';
import '../../core/widgets/shared/navigation/top_nav_bar.dart';
import '../../core/utils/app_colors.dart';
import 'admin/dashboard_screen.dart';
import 'admin/notifications_screen.dart';

class AdminMain extends StatefulWidget {
  final int initialIndex;
  final String userRole; // Add user role parameter
  
  const AdminMain({
    super.key, 
    this.initialIndex = 0,
    this.userRole = 'admin', // Default to admin role
  });
  
  @override
  _AdminMainState createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  late int _selectedIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializePages();
  }

  void _initializePages() {
    if (widget.userRole == 'super_admin') {
      _pages = [
        DashboardScreen(), // Dashboard (shared)
        const AdminManagementScreen(), // Admin Management
        const ClinicManagementScreen(), // Clinic Management
        const SystemAnalyticsScreen(), // System Analytics
        const UserManagementScreen(), // User Management
        NotificationsScreen(), // Notifications (shared)
        SupportCenterScreen(), // Support (shared)
        const SystemSettingsScreen(), // System Settings
      ];
    } else {
      // Default admin pages
      _pages = [
        DashboardScreen(),
        AppointmentManagementScreen(),
        PatientRecordsScreen(),
        ClinicScheduleScreen(),
        VetProfileScreen(),
        NotificationsScreen(),
        SupportCenterScreen(),
        SettingsScreen()
      ];
    }
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < _pages.length)
        ? _selectedIndex
        : 0;

    if (safeIndex != _selectedIndex) {
      debugPrint("⚠ Invalid selectedIndex $_selectedIndex — defaulting to 0");
    }

    return Scaffold(
      body: Row(
        children: [
          SideNavigation(
            selectedIndex: _selectedIndex,
            onItemSelected: _onNavItemSelected,
            userRole: widget.userRole, // Pass user role to navigation
          ),
          Expanded(
            child: Column(
              children: [
                TopNavBar(),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: _pages[safeIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
