import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/text_utils.dart';

/// Reusable widget for displaying recommended clinics
/// 
/// Shows a list of clinics that have experience treating specific conditions
/// Based on validated appointment history for accurate recommendations
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
          // Enhanced Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Clinics',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (detectedDisease != null)
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Based on treatment history for ${TextUtils.capitalizeWords(detectedDisease!)}',
                                style: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Clinic cards with improved spacing
          ...recommendedClinics.take(3).map((clinic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildClinicCard(context, clinic),
            );
          }).toList(),
          
          // Enhanced View all button
          if (recommendedClinics.length > 3 || onViewAllClinics != null) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: onViewAllClinics ?? () {
                  context.push('/clinics');
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(
                  recommendedClinics.length > 3
                      ? 'View ${recommendedClinics.length - 3} more clinics'
                      : 'View all clinics',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
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
    final totalCases = clinic['totalCases'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Circular Clinic logo/avatar with shadow
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            color: AppColors.white,
                            child: ClipOval(
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultLogo();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : _buildDefaultLogo(),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Clinic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinic name
                      Text(
                        TextUtils.capitalizeWords(clinicName),
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Experience and match type badges
                      if (showMatchType && matchType.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Experience level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getMatchTypeColor(matchType),
                                    _getMatchTypeColor(matchType).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getMatchTypeColor(matchType).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 11,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    matchType,
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Treatment stats badge
                            if (totalCases > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.info.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in,
                                      size: 11,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalCases ${totalCases == 1 ? 'case' : 'cases'}',
                                      style: kMobileTextStyleLegend.copyWith(
                                        color: AppColors.info,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Multiple conditions badge
                      if (matchedDiseases != null && matchedDiseases.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.done_all,
                                size: 11,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Treats ${matchedDiseases.length} conditions',
                                style: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      // Contact info with better styling
                      if (address.isNotEmpty || phone.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Address
                              if (address.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: kMobileTextStyleLegend.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              // Phone
                              if (phone.isNotEmpty) ...[
                                if (address.isNotEmpty) const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 13,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone,
                                      style: kMobileTextStyleLegend.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Enhanced arrow icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Default logo widget for clinics without logo
  Widget _buildDefaultLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  Color _getMatchTypeColor(String matchType) {
    switch (matchType) {
      case 'Highly Experienced':
        return AppColors.success;
      case 'Experienced':
        return AppColors.primary;
      case 'Has Experience':
        return AppColors.info;
      case 'Similar Cases':
        return AppColors.warning;
      case 'Related Cases':
        return AppColors.textSecondary;
      // Legacy support for old specialty-based types
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
