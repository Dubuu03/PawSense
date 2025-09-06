import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AlertSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsets? margin;

  const AlertSectionHeader({
    super.key,
    required this.title,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(
        bottom: kMobileSizedBoxLarge,
        top: kMobileSizedBoxXLarge,
      ),
      child: Text(
        title,
        style: kMobileTextStyleTitle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
