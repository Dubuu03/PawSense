import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';

class BreedSearchAndFilter extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final BreedSpecies selectedSpecies;
  final Function(BreedSpecies) onSpeciesChanged;
  final BreedStatus selectedStatus;
  final Function(BreedStatus) onStatusChanged;
  final BreedSortOption selectedSort;
  final Function(BreedSortOption) onSortChanged;
  final VoidCallback onExportCSV;

  const BreedSearchAndFilter({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.onExportCSV,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Search + Filters
          Row(
            children: [
              // Search bar
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search breeds...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kSpacingMedium,
                      vertical: kSpacingMedium,
                    ),
                  ),
                ),
              ),
              SizedBox(width: kSpacingMedium),
              
              // Species filter
              Expanded(
                child: _buildDropdown<BreedSpecies>(
                  value: selectedSpecies,
                  items: BreedSpecies.values,
                  onChanged: onSpeciesChanged,
                  getLabel: (species) => species.displayName,
                ),
              ),
              SizedBox(width: kSpacingMedium),
              
              // Status filter
              Expanded(
                child: _buildDropdown<BreedStatus>(
                  value: selectedStatus,
                  items: BreedStatus.values,
                  onChanged: onStatusChanged,
                  getLabel: (status) => status.displayName,
                ),
              ),
              SizedBox(width: kSpacingMedium),
              
              // Sort dropdown
              Expanded(
                child: _buildDropdown<BreedSortOption>(
                  value: selectedSort,
                  items: BreedSortOption.values,
                  onChanged: onSortChanged,
                  getLabel: (sort) => sort.displayName,
                ),
              ),
              SizedBox(width: kSpacingMedium),
              
              // Export Button
              ElevatedButton.icon(
                onPressed: onExportCSV,
                icon: Icon(Icons.download, size: 18),
                label: Text('Export', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: kSpacingLarge,
                    vertical: kSpacingMedium + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T) onChanged,
    required String Function(T) getLabel,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        color: AppColors.background,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
          onChanged: (T? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: items.map<DropdownMenuItem<T>>((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(getLabel(item)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
