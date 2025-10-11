// widgets/appointment_table_header.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/sort_order.dart';

class AppointmentTableHeader extends StatelessWidget {
  final SortOrder bookedAtSortOrder;
  final VoidCallback? onBookedAtSortChanged;

  const AppointmentTableHeader({
    super.key,
    required this.bookedAtSortOrder,
    this.onBookedAtSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Booked At - Sortable
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onBookedAtSortChanged,
              child: MouseRegion(
                cursor: onBookedAtSortChanged != null 
                    ? SystemMouseCursors.click 
                    : SystemMouseCursors.basic,
                child: Row(
                  children: [
                    Text(
                      'Booked At',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: kFontSizeSmall,
                      ),
                    ),
                    if (onBookedAtSortChanged != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        bookedAtSortOrder == SortOrder.ascending
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Pet
          const Expanded(
            flex: 2,
            child: Text(
              'Pet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          
          // Owner
          const Expanded(
            flex: 2,
            child: Text(
              'Owner',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          
          // Date & Time
          const Expanded(
            flex: 2,
            child: Text(
              'Date & Time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          
          // Disease/Reason
          const Expanded(
            flex: 2,
            child: Text(
              'Disease/Reason',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          
          // Status
          const Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          
          // Actions
          const Expanded(
            flex: 2,
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}