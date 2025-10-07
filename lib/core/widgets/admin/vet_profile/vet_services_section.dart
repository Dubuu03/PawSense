import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../shared/content_container.dart';
import 'service_card.dart';

class VetServicesSection extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final VoidCallback? onAddService;
  final Function(String)? onServiceToggle;
  final Function(String)? onServiceEdit;
  final Function(String)? onServiceDelete;
  final bool isLoading;

  const VetServicesSection({
    super.key,
    required this.services,
    this.onAddService,
    this.onServiceToggle,
    this.onServiceEdit,
    this.onServiceDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services Offered',
                style: TextStyle(
                  fontSize: kFontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onAddService != null)
                ElevatedButton.icon(
                  onPressed: onAddService,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingMedium,
                      vertical: kSpacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: kSpacingLarge),

          // Two-column, auto-height layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Show loading indicator
              if (isLoading) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: kSpacingLarge * 2),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Show message if no services
              if (services.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: kSpacingLarge * 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: kIconSizeLarge,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: kSpacingMedium),
                      Text(
                        'No services available',
                        style: TextStyle(
                          fontSize: kFontSizeLarge,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        'Add your first service to get started',
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              const double spacing = kSpacingMedium;
              // Force two columns: each item takes half of the available width (minus spacing)
              final double itemWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: kSpacingMedium,
                children: services.map((service) {
                  return SizedBox(
                    width: itemWidth,
                    child: ServiceCard(
                      title: service['title'],
                      description: service['description'],
                      duration: service['duration'], // String format: "30 minutes"
                      price: service['price'],       // String format: "PHP 750.00"
                      category: service['category'],
                      isActive: service['isActive'] ?? true,
                      onToggle: onServiceToggle != null
                          ? () => onServiceToggle!(service['id'])
                          : null,
                      onEdit: onServiceEdit != null
                          ? () => onServiceEdit!(service['id'])
                          : null,
                      onDelete: onServiceDelete != null
                          ? () => onServiceDelete!(service['id'])
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
