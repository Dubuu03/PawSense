import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class SpecializationBadge extends StatelessWidget {
  final String title;
  final String level;
  final bool hasCertification;

  const SpecializationBadge({
    Key? key,
    required this.title,
    required this.level,
    this.hasCertification = false,
  }) : super(key: key);

  Color _getLevelColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'basic':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getLevelBackgroundColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return Colors.green.withOpacity(0.1);
      case 'intermediate':
        return Colors.orange.withOpacity(0.1);
      case 'basic':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // makes the badge expand horizontally
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // align text to the left
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelBackgroundColor(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: _getLevelColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hasCertification) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
