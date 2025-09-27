import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/models/clinic/clinic_certification_model.dart';
import 'package:pawsense/core/models/clinic/clinic_license_model.dart';

class ClinicCredentials extends StatelessWidget {
  final ClinicDetails clinic;

  const ClinicCredentials({
    super.key,
    required this.clinic,
  });

  @override
  Widget build(BuildContext context) {
    final hasCertifications = clinic.certifications.isNotEmpty;
    final hasLicenses = clinic.licenses.isNotEmpty;

    if (!hasCertifications && !hasLicenses) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Credentials & Licenses',
                style: kMobileTextStyleTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          if (hasCertifications) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'Certifications (${clinic.certifications.length})',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            ...clinic.certifications.map((cert) => _buildCertificationItem(cert)),
          ],
          
          if (hasLicenses) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'Licenses (${clinic.licenses.length})',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            ...clinic.licenses.map((license) => _buildLicenseItem(license)),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationItem(ClinicCertification certification) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxSmall),
      padding: const EdgeInsets.all(kMobilePaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: kMobileBorderRadiusButtonPreset,
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 12,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: kMobileSizedBoxMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certification.name,
                  style: kMobileTextStyleServiceTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (certification.issuer.isNotEmpty) ...[
                  Text(
                    certification.issuer,
                    style: kMobileTextStyleServiceSubtitle.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (certification.status == CertificationStatus.approved)
            Icon(
              Icons.verified,
              size: 14,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(ClinicLicense license) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxSmall),
      padding: const EdgeInsets.all(kMobilePaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: kMobileBorderRadiusButtonPreset,
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.gavel,
              size: 12,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: kMobileSizedBoxMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'License',
                  style: kMobileTextStyleServiceTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (license.licenseId.isNotEmpty) ...[
                  Text(
                    'ID: ${license.licenseId}',
                    style: kMobileTextStyleServiceSubtitle.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (license.status == LicenseStatus.approved)
            Icon(
              Icons.verified,
              size: 14,
              color: AppColors.info,
            ),
        ],
      ),
    );
  }
}