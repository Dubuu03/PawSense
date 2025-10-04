import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  bool _twoFactorAuth = false;
  bool _allowMultipleSessions = true;
  bool _requirePasswordChange = false;
  bool _loginNotifications = true;
  
  String _sessionTimeout = '30 minutes';
  String _passwordExpiry = '90 days';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          // Two-Factor Authentication Warning
          Container(
            padding: EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add an extra layer of security to your account',
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _twoFactorAuth,
                  onChanged: (value) {
                    setState(() {
                      _twoFactorAuth = value;
                    });
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          // Session Settings
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Timeout (minutes)',
                      style: TextStyle(
                        fontSize: kFontSizeRegular,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _sessionTimeout,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: kSpacingMedium,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        '15 minutes',
                        '30 minutes',
                        '60 minutes',
                        '2 hours',
                        '4 hours',
                      ].map((timeout) {
                        return DropdownMenuItem(
                          value: timeout,
                          child: Text(timeout),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sessionTimeout = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Expiry (days)',
                      style: TextStyle(
                        fontSize: kFontSizeRegular,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _passwordExpiry,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: kSpacingMedium,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        '30 days',
                        '60 days',
                        '90 days',
                        '180 days',
                        'Never',
                      ].map((expiry) {
                        return DropdownMenuItem(
                          value: expiry,
                          child: Text(expiry),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _passwordExpiry = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingLarge),
          
          _buildSecurityToggle(
            title: 'Two Factor Auth',
            value: _twoFactorAuth,
            onChanged: (value) => setState(() => _twoFactorAuth = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildSecurityToggle(
            title: 'Allow Multiple Sessions',
            value: _allowMultipleSessions,
            onChanged: (value) => setState(() => _allowMultipleSessions = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildSecurityToggle(
            title: 'Require Password Change',
            value: _requirePasswordChange,
            onChanged: (value) => setState(() => _requirePasswordChange = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildSecurityToggle(
            title: 'Login Notifications',
            value: _loginNotifications,
            onChanged: (value) => setState(() => _loginNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: kFontSizeRegular,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
