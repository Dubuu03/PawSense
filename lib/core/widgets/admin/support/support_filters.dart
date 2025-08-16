import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../shared/search_field.dart';

class SupportFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedStatus;
  final String selectedCategory;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(String) onCategoryChanged;

  const SupportFilters({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSearchField(),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildStatusDropdown(),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildCategoryDropdown(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SearchField(
      hintText: 'Search tickets...',
      onChanged: onSearchChanged,
    );
  }

  Widget _buildStatusDropdown() {
    final statuses = ['All Status', 'Open', 'In Progress', 'Resolved'];
    
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          items: statuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onStatusChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = [
      'All Categories',
      'Appointment',
      'Technical',
      'General',
      'Billing',
      'Emergency Care',
      'Technology',
      'Preventive Care'
    ];
    
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
        ),
      ),
    );
  }
}