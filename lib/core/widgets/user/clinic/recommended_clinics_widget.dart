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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Clinics',
                      style: kMobileTextStyleTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (detectedDisease != null)
                      Text(
                        'Based on treatment history for ${TextUtils.capitalizeWords(detectedDisease!)}',
                        style: kMobileTextStyleLegend.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendedClinics.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final clinic = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 8),
              child: _buildClinicCard(context, clinic),
            );
          }).toList(),
          if (recommendedClinics.length > 3 || onViewAllClinics != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewAllClinics ?? () {
                  context.push('/clinics');
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  recommendedClinics.length > 3
                      ? 'View ${recommendedClinics.length - 3} more clinics'
                      : 'View all clinics',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    final totalCases = clinic['totalCases'] as int? ?? 0;
    final averageRating = clinic['averageRating'] as double? ?? 0.0;
    final totalRatings = clinic['totalRatings'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
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
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: ClipOval(
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(3),
                            color: AppColors.white,
                            child: ClipOval(
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TextUtils.capitalizeWords(clinicName),
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (totalRatings > 0) ...[
                            Icon(
                              Icons.star,
                              size: 13,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: kMobileTextStyleLegend.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '($totalRatings)',
                              style: kMobileTextStyleLegend.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (totalCases > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 10,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$totalCases treated',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.info,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (address.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 12,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
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
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.55),
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
          size: 24,
        ),
      ),
    );
  }
}
