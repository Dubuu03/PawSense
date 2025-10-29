import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

/// Reusable widget for displaying recommended clinics
/// 
/// Shows a list of clinics that specialize in treating specific conditions
/// Can be used in assessment results or disease detail pages
class RecommendedClinicsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendedClinics;
  final String? detectedDisease;
  final VoidCallback? onViewAllClinics;
  final Function(String clinicId, String clinicName)? onClinicTap;
  final bool showMatchType;
  
  const RecommendedClinicsWidget({
    super.key,
    required this.recommendedClinics,
    this.detectedDisease,
    this.onViewAllClinics,
    this.onClinicTap,
    this.showMatchType = true,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendedClinics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.recommend,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Clinics',
                      style: kMobileTextStyleTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (detectedDisease != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Specializing in $detectedDisease',
                        style: kMobileTextStyleLegend.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Clinic cards
          ...recommendedClinics.take(3).map((clinic) {
            return _buildClinicCard(context, clinic);
          }).toList(),
          
          // View all button if there are more clinics
          if (recommendedClinics.length > 3 || onViewAllClinics != null) ...[
            const SizedBox(height: kSpacingSmall),
            TextButton.icon(
              onPressed: onViewAllClinics ?? () {
                context.push('/clinics');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(
                recommendedClinics.length > 3
                    ? 'View ${recommendedClinics.length - 3} more clinics'
                    : 'View all clinics',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    final clinicId = clinic['id'] ?? clinic['clinicId'] ?? '';
    final clinicName = clinic['name'] ?? 'Unknown Clinic';
    final address = clinic['address'] ?? '';
    final phone = clinic['phone'] ?? '';
    final logoUrl = clinic['logoUrl'];
    final matchType = clinic['matchType'] ?? '';
    final matchedDiseases = clinic['matchedDiseases'] as List<String>?;

    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingSmall),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onClinicTap != null) {
              onClinicTap!(clinicId, clinicName);
            } else {
              // Default: navigate to clinic details
              context.push('/clinic/$clinicId');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingMedium),
            child: Row(
              children: [
                // Clinic logo/avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: logoUrl != null && logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: logoUrl == null || logoUrl.isEmpty
                      ? Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: kSpacingMedium),
                
                // Clinic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Match type badge
                      if (showMatchType && matchType.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMatchTypeColor(matchType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getMatchTypeColor(matchType).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            matchType,
                            style: kMobileTextStyleLegend.copyWith(
                              color: _getMatchTypeColor(matchType),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      
                      // Matched diseases (for multiple disease matches)
                      if (matchedDiseases != null && matchedDiseases.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Treats ${matchedDiseases.length} detected conditions',
                          style: kMobileTextStyleLegend.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      // Address
                      if (address.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Phone
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: kMobileTextStyleLegend.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow icon
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

  Color _getMatchTypeColor(String matchType) {
    switch (matchType) {
      case 'Exact Specialty Match':
        return AppColors.success;
      case 'Primary Specialty':
        return AppColors.primary;
      case 'Related Specialty':
        return AppColors.info;
      case 'General Practice':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }
}
