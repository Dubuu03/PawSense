import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';


class PatientRecordsHeader extends StatelessWidget {
  final VoidCallback? onAddPatient;

  const PatientRecordsHeader({
    super.key,
    this.onAddPatient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Records',
                style: kTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comprehensive pet medical records and health tracking',
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onAddPatient,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}