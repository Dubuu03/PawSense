import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: kTextStyleHeader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              'Configure system-wide settings and preferences',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: kSpacingLarge),
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: kSpacingMedium),
                    Text(
                      'System Settings',
                      style: kTextStyleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: kSpacingSmall),
                    Text(
                      'This feature is coming soon',
                      style: kTextStyleRegular.copyWith(
                        color: AppColors.textSecondary,
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
