import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../utils/app_colors.dart';
import 'view_toggle_buttons.dart';
import '../shared/search_field.dart';

class AppointmentFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  const AppointmentFilters({
    Key? key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Field
            Expanded(
              flex: 2,
              child: SearchField(
                hintText: 'Search appointments...',
                onChanged: onSearchChanged,
                fontSize: kFontSizeRegular - 2,
              ),
            ),
            const SizedBox(width: 12),

            // Status Filter Buttons
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ViewToggleButton(
                    text: 'All',
                    isSelected: selectedStatus == 'All Status',
                    onTap: () => onStatusChanged('All Status'),
                  ),
                  const SizedBox(width: 4),
                  ViewToggleButton(
                    text: 'Pending',
                    isSelected: selectedStatus == 'Pending',
                    onTap: () => onStatusChanged('Pending'),
                  ),
                  const SizedBox(width: 4),
                  ViewToggleButton(
                    text: 'Confirmed',
                    isSelected: selectedStatus == 'Confirmed',
                    onTap: () => onStatusChanged('Confirmed'),
                  ),
                  const SizedBox(width: 4),
                  ViewToggleButton(
                    text: 'Completed',
                    isSelected: selectedStatus == 'Completed',
                    onTap: () => onStatusChanged('Completed'),
                  ),
                  const SizedBox(width: 4),
                  ViewToggleButton(
                    text: 'Cancelled',
                    isSelected: selectedStatus == 'Cancelled',
                    onTap: () => onStatusChanged('Cancelled'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
