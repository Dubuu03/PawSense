import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class CertificationCard extends StatelessWidget {
  final String title;
  final String organization;
  final String issueDate;
  final String? expiryDate;
  final String? documentUrl;
  final String? documentFileId;
  final VoidCallback? onDownload;
  final VoidCallback? onPreview;
  final VoidCallback? onDelete;

  const CertificationCard({
    super.key,
    required this.title,
    required this.organization,
    required this.issueDate,
    this.expiryDate,
    this.documentUrl,
    this.documentFileId,
    this.onDownload,
    this.onPreview,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDocument = documentUrl != null || documentFileId != null;
    
    return InkWell(
      onTap: hasDocument && onPreview != null ? onPreview : null,
      borderRadius: BorderRadius.circular(12),
      hoverColor: hasDocument ? AppColors.primary.withOpacity(0.02) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: kSpacingMedium),
        padding: EdgeInsets.all(kSpacingMedium + 4), // 20px
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDocument ? AppColors.primary.withOpacity(0.15) : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      organization,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildDateBadge(
                          'Issued: $issueDate',
                          AppColors.primary,
                          Icons.calendar_today,
                        ),
                        if (expiryDate != null)
                          _buildDateBadge(
                            'Expires: $expiryDate',
                            AppColors.warning,
                            Icons.event_available,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              if (onDelete != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    color: AppColors.error,
                    tooltip: 'Delete Certificate',
                  ),
                ),
            ],
          ),
          

        ],
        ),
      ),
    );
  }

  Widget _buildDateBadge(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
