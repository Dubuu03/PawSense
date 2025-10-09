// widgets/appointment_table_header.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/sort_order.dart';

class AppointmentTableHeader extends StatelessWidget {
  final SortOrder dateSortOrder;
  final VoidCallback? onDateSortChanged;

  const AppointmentTableHeader({
    super.key,
    required this.dateSortOrder,
    this.onDateSortChanged,
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
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onDateSortChanged,
              child: MouseRegion(
                cursor: onDateSortChanged != null 
                    ? SystemMouseCursors.click 
                    : SystemMouseCursors.basic,
                child: Row(
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: kFontSizeSmall,
                      ),
                    ),
                    if (onDateSortChanged != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        dateSortOrder == SortOrder.ascending
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
          const Expanded(
            flex: 1,
            child: Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Pet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
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
          Expanded(
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
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
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