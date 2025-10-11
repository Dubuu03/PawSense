import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import 'view_toggle_buttons.dart';
import '../../shared/search_field.dart';

class AppointmentFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onExportData;

  const AppointmentFilters({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    this.startDate,
    this.endDate,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onExportData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            // First Row: Search, Status Filters, and Export Button
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: SearchField(
                    hintText: 'Search appointments...',
                    onChanged: onSearchChanged,
                    fontSize: kFontSizeRegular - 2,
                    initialValue: searchQuery,
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
                const SizedBox(width: 12),

                // Export Button
                ElevatedButton.icon(
                  onPressed: onExportData,
                  icon: Icon(Icons.download_outlined, size: kIconSizeMedium),
                  label: Text('Export', style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge, 
                      vertical: kSpacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Second Row: Date Filters
            Row(
              children: [
                // Start Date Picker
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        color: AppColors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                               size: kIconSizeSmall, 
                               color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startDate != null 
                                  ? 'From: ${_formatDate(startDate!)}'
                                  : 'Start Date',
                              style: kTextStyleRegular.copyWith(
                                color: startDate != null 
                                    ? AppColors.textPrimary 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (startDate != null)
                            GestureDetector(
                              onTap: () => onStartDateChanged(null),
                              child: Icon(Icons.clear, 
                                   size: kIconSizeSmall, 
                                   color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // End Date Picker
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        color: AppColors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, 
                               size: kIconSizeSmall, 
                               color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              endDate != null 
                                  ? 'To: ${_formatDate(endDate!)}'
                                  : 'End Date',
                              style: kTextStyleRegular.copyWith(
                                color: endDate != null 
                                    ? AppColors.textPrimary 
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (endDate != null)
                            GestureDetector(
                              onTap: () => onEndDateChanged(null),
                              child: Icon(Icons.clear, 
                                   size: kIconSizeSmall, 
                                   color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Clear Date Filters Button (fixed width to match export button)
                if (startDate != null || endDate != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120, // Fixed width to match export button
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onStartDateChanged(null);
                        onEndDateChanged(null);
                      },
                      icon: Icon(Icons.clear_all, size: kIconSizeMedium),
                      label: Text('Clear', style: kTextStyleRegular.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingLarge, 
                          vertical: kSpacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  // Spacer when no clear button to maintain alignment
                  const SizedBox(width: 132),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onStartDateChanged(picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onEndDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
