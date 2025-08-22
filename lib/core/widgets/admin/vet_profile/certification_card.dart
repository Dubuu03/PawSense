import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class CertificationCard extends StatelessWidget {
  final String title;
  final String organization;
  final String issueDate;
  final String? expiryDate;
  final VoidCallback? onDownload;

  const CertificationCard({
    super.key,
    required this.title,
    required this.organization,
    required this.issueDate,
    this.expiryDate,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  organization,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: kFontSizeRegular - 2, // 14px
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    Text(
                      'Issued: $issueDate',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: kFontSizeSmall,
                      ),
                    ),
                    if (expiryDate != null) ...[
                      SizedBox(width: kSpacingMedium),
                      Text(
                        'Expires: $expiryDate',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: kFontSizeSmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: Icon(Icons.file_download_outlined),
              onPressed: onDownload,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}
