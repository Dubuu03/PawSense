import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../containers/content_container.dart';
import 'service_card.dart';

class VetServicesSection extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final VoidCallback? onAddService;
  final Function(String)? onServiceToggle;
  final Function(String)? onServiceEdit;
  final Function(String)? onServiceDelete;

  const VetServicesSection({
    super.key,
    required this.services,
    this.onAddService,
    this.onServiceToggle,
    this.onServiceEdit,
    this.onServiceDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services Offered',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onAddService != null)
                ElevatedButton.icon(
                  onPressed: onAddService,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true, // ✅ prevents overflow
            physics:
                const NeverScrollableScrollPhysics(), // ✅ avoids scroll conflict
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceCard(
                title: service['title'],
                description: service['description'],
                duration: service['duration'],
                price: service['price'],
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
              );
            },
          ),
        ],
      ),
    );
  }
}
