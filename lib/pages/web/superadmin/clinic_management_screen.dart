import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';

class ClinicManagementScreen extends StatefulWidget {
  const ClinicManagementScreen({super.key});

  @override
  State<ClinicManagementScreen> createState() => _ClinicManagementScreenState();
}

class _ClinicManagementScreenState extends State<ClinicManagementScreen> {
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
              'Clinic Management',
              style: kTextStyleHeader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              'Manage clinic locations and services',
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
                      Icons.business,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: kSpacingMedium),
                    Text(
                      'Clinic Management',
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
