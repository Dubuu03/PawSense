import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/system/system_settings_model.dart';
import '../../../core/widgets/shared/page_header.dart';
import '../../../core/widgets/system_settings/settings_tab_bar.dart';
import '../../../core/widgets/system_settings/profile_tab.dart';
import '../../../core/widgets/system_settings/security_tab.dart';
import '../../../core/widgets/system_settings/notifications_tab.dart';
import '../../../core/widgets/system_settings/system_tab.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  int _currentTabIndex = 0;
  late SystemSettingsModel _settings;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    _settings = SystemSettingsModel(
      defaultTimeZone: 'UTC-5 (Eastern)',
      dateFormat: 'MM/DD/YYYY',
      sessionTimeout: Duration(hours: 8),
      twoFactorAuthEnabled: true,
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@pawsense.com',
      phoneNumber: '+1 (555) 123-4567',
      role: 'Super Admin',
      systemHealth: SystemHealthModel(
        systemUptime: 99.9,
        systemUptimeLabel: 'Last 30 days',
        databaseHealth: 'Optimal',
        databaseStatus: 'All connections stable',
        storageUsage: 67.3,
        storageDetails: '2.1TB of 3TB used',
        activeSessions: 1247,
        activeSessionsLabel: 'Current concurrent users',
      ),
      recentSecurityEvents: [
        SecurityEventModel(
          title: 'Successful admin login',
          description: 'IP: 192.168.1.100',
          timestamp: DateTime.now().subtract(Duration(minutes: 2)),
          type: SecurityEventType.success,
        ),
        SecurityEventModel(
          title: 'Password policy updated',
          description: 'Minimum length increased to 12',
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
          type: SecurityEventType.info,
        ),
        SecurityEventModel(
          title: 'Failed login attempt blocked',
          description: 'IP: 203.45.67.89 (5 attempts)',
          timestamp: DateTime.now().subtract(Duration(hours: 3)),
          type: SecurityEventType.warning,
        ),
        SecurityEventModel(
          title: 'Two-factor authentication enabled',
          description: 'For user: admin@pawsense.com',
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          type: SecurityEventType.success,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header using consistent PageHeader widget
          Container(
            color: AppColors.background,
            padding: EdgeInsets.only(top: kSpacingLarge, bottom: kSpacingSmall),
            child: PageHeader(
              title: 'System Settings',
              subtitle: 'Manage your profile, security settings, and system configuration',
            ),
          ),
          
          // Card Container with Tab Bar and Content
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: EdgeInsets.all(kSpacingLarge),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: kShadowBlurRadius,
                      offset: kShadowOffset,
                      spreadRadius: kShadowSpreadRadius,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab Bar inside the card
                    SettingsTabBar(
                      currentIndex: _currentTabIndex,
                      onTabChanged: (index) => setState(() => _currentTabIndex = index),
                    ),
                    
                    // Tab Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(kSpacingLarge),
                        child: _buildTabContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return ProfileTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        );
      case 1:
        return SecurityTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        );
      case 2:
        return NotificationsTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        );
      case 3:
        return SystemTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        );
      default:
        return ProfileTab(
          settings: _settings,
          onSettingsChanged: _updateSettings,
        );
    }
  }

  void _updateSettings(SystemSettingsModel newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }
}
