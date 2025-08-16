import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

enum PatientStatus { treatment, healthy }

class StatusChip extends StatelessWidget {
  final PatientStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  Color get backgroundColor {
    switch (status) {
      case PatientStatus.treatment:
        return AppColors.warning.withOpacity(0.1);
      case PatientStatus.healthy:
        return AppColors.success.withOpacity(0.1);
    }
  }

  Color get textColor {
    switch (status) {
      case PatientStatus.treatment:
        return AppColors.warning;
      case PatientStatus.healthy:
        return AppColors.success;
    }
  }

  String get label {
    switch (status) {
      case PatientStatus.treatment:
        return 'Treatment';
      case PatientStatus.healthy:
        return 'Healthy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: kFontSizeSmall,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}