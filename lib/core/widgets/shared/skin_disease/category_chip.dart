import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Chip widget for displaying and filtering categories
/// 
/// Used in the skin disease library filter section
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.white,
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary 
                  : AppColors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon based on category
                Text(
                  _getCategoryIcon(label),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                // Label
                Text(
                  _formatLabel(label),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? AppColors.white 
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'parasitic':
        return '🦠';
      case 'allergic':
        return '🌼';
      case 'bacterial':
        return '🧫';
      case 'fungal':
        return '🍄';
      case 'viral':
        return '🦠';
      case 'autoimmune':
        return '🔬';
      case 'hormonal':
        return '⚗️';
      default:
        return '📋';
    }
  }

  String _formatLabel(String label) {
    // Capitalize first letter
    return label.isEmpty 
        ? label 
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }
}
