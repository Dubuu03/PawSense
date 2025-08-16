import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../../utils/constants.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final int duration;      // keep as int
  final String price;      // keep as String from your data
  final String category;
  final bool isActive;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    required this.category,
    this.isActive = true,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // let height follow content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + category chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: kTextStyleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      onChanged: onToggle != null ? (_) => onToggle!() : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: onEdit,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit Service',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 20),
                      onPressed: onDelete,
                      color: Colors.red[400],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Service',
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: kTextStyleSmall.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Duration + Price row
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$duration min',
                    style: kTextStyleSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Icon(Icons.payments_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    price,
                    style: kTextStyleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
