import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../shared/search_field.dart';

class PatientFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedType;
  final String selectedStatus;
  final List<String> types;
  final List<String> statuses;
  final Function(String) onTypeChanged;
  final Function(String) onStatusChanged;
  final Function(String) onSearchChanged;

  const PatientFilterBar({
    super.key,
    required this.searchController,
    required this.selectedType,
    required this.selectedStatus,
    required this.types,
    required this.statuses,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: SearchField(
              hintText: 'Search patients...',
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          
          // Type Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedType,
              onChanged: (value) => onTypeChanged(value ?? selectedType),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          
          // Status Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              onChanged: (value) => onStatusChanged(value ?? selectedStatus),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}