import 'package:flutter/material.dart';
import '../../../core/models/system/legal_document_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants_mobile.dart';
import 'auth/legal_document_modal.dart';

/// Legal Documents Page for Mobile
///
/// Displays a list of legal documents that users can view
class LegalDocumentsPage extends StatelessWidget {
  const LegalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Legal Documents',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(kMobilePaddingMedium),
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(kMobilePaddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(kMobilePaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: kMobileCardShadowSmall,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: kMobileSizedBoxMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Information',
                        style: kMobileTextStyleTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kMobileSizedBoxSmall),
                      Text(
                        'View our policies and agreements',
                        style: kMobileTextStyleSubtitle.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: kMobileSizedBoxLarge),
          
          // Terms and Conditions
          _buildDocumentCard(
            context,
            title: 'Terms and Conditions',
            description: 'Review our terms of service and usage policies',
            icon: Icons.pets_rounded,
            color: AppColors.primary,
            documentType: DocumentType.termsAndConditions,
          ),
          
          SizedBox(height: kMobileSizedBoxMedium),
          
          // Privacy Policy
          _buildDocumentCard(
            context,
            title: 'Privacy Policy',
            description: 'Learn how we protect and use your data',
            icon: Icons.privacy_tip_outlined,
            color: AppColors.info,
            documentType: DocumentType.privacyPolicy,
          ),
          
          SizedBox(height: kMobileSizedBoxMedium),
          
          // User Agreement
          _buildDocumentCard(
            context,
            title: 'User Agreement',
            description: 'Understand your rights and responsibilities',
            icon: Icons.assignment_outlined,
            color: AppColors.success,
            documentType: DocumentType.userAgreement,
          ),
          
          SizedBox(height: kMobileSizedBoxLarge),
          
          // Footer info
          Container(
            padding: EdgeInsets.all(kMobilePaddingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: kMobileSizedBoxSmall),
                Expanded(
                  child: Text(
                    'These documents are periodically updated. Last check: Today',
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required DocumentType documentType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => LegalDocumentModal(
                documentType: documentType,
                requireAcceptance: false,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(kMobilePaddingMedium),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                
                SizedBox(width: kMobileSizedBoxMedium),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: kMobileTextStyleTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: kMobileSizedBoxSmall),
                      Text(
                        description,
                        style: kMobileTextStyleSubtitle.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
