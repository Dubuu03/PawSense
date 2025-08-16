import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/settings/settings_header.dart';
import '../../core/widgets/settings/settings_navigation.dart';
import '../../core/widgets/settings/account_settings.dart';
import '../../core/widgets/settings/clinic_settings.dart';
import '../../core/widgets/settings/notification_settings.dart';
import '../../core/widgets/settings/security_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = 'account';

  Widget _buildCurrentSettings() {
    switch (_selectedSection) {
      case 'account':
        return AccountSettings();
      case 'clinic':
        return ClinicSettings();
      case 'notifications':
        return NotificationSettings();
      case 'security':
        return SecuritySettings();
      default:
        return AccountSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          children: [
            // Header
            SettingsHeader(),
            SizedBox(height: kSpacingLarge),
            
            // Main Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Navigation Sidebar
                    SettingsNavigation(
                      selectedSection: _selectedSection,
                      onSectionChanged: (section) {
                        setState(() {
                          _selectedSection = section;
                        });
                      },
                    ),
                    
                    // Vertical Divider
                    Container(
                      width: 1,
                      color: AppColors.border,
                    ),
                    
                    // Settings Content
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(kSpacingLarge * 1.5),
                        child: _buildCurrentSettings(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}