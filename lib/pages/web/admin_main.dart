import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pawsense/pages/web/appointment_screen.dart';
import 'package:pawsense/pages/web/clinic_schedule_screen.dart';
import 'package:pawsense/pages/web/patient_record_screen.dart';
import 'package:pawsense/pages/web/settings_screen.dart';
import 'package:pawsense/pages/web/support_screen.dart';
import 'package:pawsense/pages/web/vet_profile_screen.dart';
import '../../core/widgets/navigation/side_navigation.dart';
import '../../core/widgets/navigation/top_nav_bar.dart';
import '../../core/utils/app_colors.dart';
import '../../pages/web/dashboard_screen.dart';
import '../../pages/web/notifications_screen.dart';

class AdminMain extends StatefulWidget {
  final int initialIndex;
  
  const AdminMain({Key? key, this.initialIndex = 0}) : super(key: key);
  
  @override
  _AdminMainState createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    DashboardScreen(),
    AppointmentManagementScreen(),
    PatientRecordsScreen(),
    ClinicScheduleScreen(),
    VetProfileScreen(),
    NotificationsScreen(),
    SupportCenterScreen(),
    SettingsScreen()
  ];

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
