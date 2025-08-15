import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class CertificationCard extends StatelessWidget {
  final String title;
  final String organization;
  final String issueDate;
  final String? expiryDate;
  final VoidCallback? onDownload;

  const CertificationCard({
    Key? key,
    required this.title,
    required this.organization,
    required this.issueDate,
    this.expiryDate,
    this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  organization,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Issued: $issueDate',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (expiryDate != null) ...[
                      SizedBox(width: 16),
                      Text(
                        'Expires: $expiryDate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
