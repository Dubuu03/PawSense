import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;

  ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
  });
}

class ServicesGrid extends StatelessWidget {
  final List<ServiceItem> services;

  const ServicesGrid({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // keep horizontal and bottom spacing but reduce the top gap to bring the grid closer
      margin: const EdgeInsets.fromLTRB(kMobileMarginHorizontal, 0, kMobileMarginHorizontal, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: kMobileSizedBoxMedium),
            child: Text(
              'Services',
              style: kMobileTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: kMobileServicesGridDelegate,
            itemCount: services.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(services[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: service.onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: kMobilePaddingService,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: kMobileIconContainerSize,
                  height: kMobileIconContainerSize,
                  decoration: BoxDecoration(
                    color: service.backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: kMobileBorderRadiusIconPreset,
                  ),
                  child: Icon(
                    service.icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  service.title,
                  style: kMobileTextStyleServiceTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: kMobileSizedBoxSmall),
                
                Text(
                  service.subtitle,
                  style: kMobileTextStyleServiceSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
