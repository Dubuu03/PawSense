import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class CertificationPreviewModal extends StatelessWidget {
  final String title;
  final String organization;
  final String issueDate;
  final String? expiryDate;
  final String? documentUrl;
  final VoidCallback? onDownload;

  const CertificationPreviewModal({
    super.key,
    required this.title,
    required this.organization,
    required this.issueDate,
    this.expiryDate,
    this.documentUrl,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kBorderRadius),
                  topRight: Radius.circular(kBorderRadius),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: kFontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          organization,
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDownload != null)
                    ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: Icon(Icons.file_download_outlined, size: 16),
                      label: Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingMedium,
                          vertical: kSpacingSmall,
                        ),
                      ),
                    ),
                  SizedBox(width: kSpacingSmall),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Certificate Info
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Issue Date',
                      issueDate,
                      Icons.calendar_today,
                    ),
                  ),
                  SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: _buildInfoCard(
                      'Expiry Date',
                      expiryDate ?? 'No Expiry',
                      Icons.event_available,
                    ),
                  ),
                ],
              ),
            ),

            // Document Preview Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(kSpacingLarge),
                child: documentUrl != null
                    ? _buildDocumentPreview()
                    : _buildNoDocumentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          SizedBox(width: kSpacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: kFontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final isImage = documentUrl!.toLowerCase().contains('.jpg') ||
                   documentUrl!.toLowerCase().contains('.jpeg') ||
                   documentUrl!.toLowerCase().contains('.png');

    if (isImage) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Image.network(
            documentUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorView('Failed to load image preview');
            },
          ),
        ),
      );
    } else {
      // For PDF or other document types
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: kSpacingMedium),
              Text(
                'PDF Document',
                style: TextStyle(
                  fontSize: kFontSizeLarge,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: kSpacingSmall),
              Text(
                'Click download to view the full document',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: kSpacingLarge),
              if (onDownload != null)
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: Icon(Icons.file_download_outlined),
                  label: Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge,
                      vertical: kSpacingMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNoDocumentView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: kSpacingMedium),
            Text(
              'No Document Available',
              style: TextStyle(
                fontSize: kFontSizeLarge,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              'This certification does not have an associated document',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: kSpacingMedium),
            Text(
              'Preview Error',
              style: TextStyle(
                fontSize: kFontSizeLarge,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}