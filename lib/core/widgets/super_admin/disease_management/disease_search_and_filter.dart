import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/search_field.dart';

class DiseaseSearchAndFilter extends StatefulWidget {
  final String searchQuery;
  final String? detectionFilter;
  final List<String> speciesFilter;
  final String? severityFilter;
  final List<String> categoriesFilter;
  final bool? contagiousFilter;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String?) onDetectionChanged;
  final Function(List<String>) onSpeciesChanged;
  final Function(String?) onSeverityChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function(bool?) onContagiousChanged;
  final Function(String) onSortChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onExportCSV;

  const DiseaseSearchAndFilter({
    super.key,
    required this.searchQuery,
    required this.detectionFilter,
    required this.speciesFilter,
    required this.severityFilter,
    required this.categoriesFilter,
    required this.contagiousFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onDetectionChanged,
    required this.onSpeciesChanged,
    required this.onSeverityChanged,
    required this.onCategoriesChanged,
    required this.onContagiousChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onExportCSV,
  });

  @override
  State<DiseaseSearchAndFilter> createState() =>
      _DiseaseSearchAndFilterState();
}

class _DiseaseSearchAndFilterState extends State<DiseaseSearchAndFilter> {
  late TextEditingController _searchController;
  Timer? _debounce;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(value);
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (widget.detectionFilter != null) count++;
    if (widget.speciesFilter.isNotEmpty) count++;
    if (widget.severityFilter != null) count++;
    if (widget.categoriesFilter.isNotEmpty) count++;
    if (widget.contagiousFilter != null) count++;
    return count;
  }

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
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Row: Search + Dropdowns + Export
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: SearchField(
                  hintText: 'Search diseases by name, symptoms, or categories...',
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Detection Method Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Detection',
                  value: widget.detectionFilter ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Detection'},
                    {'value': 'ai', 'label': 'AI-Detectable'},
                    {'value': 'info', 'label': 'Info Only'},
                  ],
                  onChanged: (value) => widget.onDetectionChanged(value == 'all' ? null : value),
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Severity Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Severity',
                  value: widget.severityFilter ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Severity'},
                    {'value': 'mild', 'label': 'Mild'},
                    {'value': 'moderate', 'label': 'Moderate'},
                    {'value': 'severe', 'label': 'Severe'},
                    {'value': 'varies', 'label': 'Varies'},
                  ],
                  onChanged: (value) => widget.onSeverityChanged(value == 'all' ? null : value),
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Sort Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Sort',
                  value: widget.sortBy,
                  items: [
                    {'value': 'name_asc', 'label': 'A-Z'},
                    {'value': 'name_desc', 'label': 'Z-A'},
                    {'value': 'date_added', 'label': 'Newest'},
                    {'value': 'date_updated', 'label': 'Updated'},
                    {'value': 'most_viewed', 'label': 'Popular'},
                    {'value': 'severity', 'label': 'Severity'},
                  ],
                  onChanged: widget.onSortChanged,
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Advanced Filters Toggle
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  _showAdvancedFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: kIconSizeMedium,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Filters', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.w500)),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _showAdvancedFilters ? AppColors.primary : AppColors.textSecondary,
                  side: BorderSide(
                    color: _showAdvancedFilters ? AppColors.primary : AppColors.border,
                    width: _showAdvancedFilters ? 1.5 : 1,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: kSpacingLarge, vertical: kSpacingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Export Button
              ElevatedButton.icon(
                onPressed: widget.onExportCSV,
                icon: Icon(Icons.download_outlined, size: kIconSizeMedium),
                label: Text('Export', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.w500)),
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

          // Advanced Filters Panel
          if (_showAdvancedFilters) ...[
            SizedBox(height: kSpacingLarge),
            Divider(color: AppColors.border),
            SizedBox(height: kSpacingLarge),
            _buildAdvancedFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
        filled: true,
        fillColor: AppColors.white,
      ),
      style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value']!,
          child: Text(
            item['label']!,
            style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) => onChanged(val!),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Advanced Filters',
              style: kTextStyleRegular.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_activeFilterCount > 0)
              TextButton.icon(
                onPressed: widget.onClearFilters,
                icon: Icon(Icons.clear_all, size: kIconSizeSmall),
                label: Text('Clear All', style: kTextStyleSmall),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
                ),
              ),
          ],
        ),
        SizedBox(height: kSpacingMedium),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFilterGroup(
                'Species',
                _buildSpeciesFilter(),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildFilterGroup(
                'Contagious',
                _buildContagiousFilter(),
              ),
            ),
          ],
        ),
        SizedBox(height: kSpacingLarge),
        _buildFilterGroup(
          'Categories',
          _buildCategoriesFilter(),
        ),
      ],
    );
  }

  Widget _buildFilterGroup(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: kTextStyleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: kSpacingSmall),
        child,
      ],
    );
  }



  Widget _buildSpeciesFilter() {
    return Wrap(
      spacing: kSpacingSmall,
      runSpacing: kSpacingSmall,
      children: [
        _buildFilterChip(
          label: '🐱 Cats',
          isSelected: widget.speciesFilter.contains('cats'),
          onTap: () {
            final newList = List<String>.from(widget.speciesFilter);
            if (newList.contains('cats')) {
              newList.remove('cats');
            } else {
              newList.add('cats');
            }
            widget.onSpeciesChanged(newList);
          },
        ),
        _buildFilterChip(
          label: '🐶 Dogs',
          isSelected: widget.speciesFilter.contains('dogs'),
          onTap: () {
            final newList = List<String>.from(widget.speciesFilter);
            if (newList.contains('dogs')) {
              newList.remove('dogs');
            } else {
              newList.add('dogs');
            }
            widget.onSpeciesChanged(newList);
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    final categories = [
      'Parasitic',
      'Bacterial',
      'Fungal',
      'Allergic',
      'Autoimmune',
      'Other',
    ];

    return Wrap(
      spacing: kSpacingSmall,
      runSpacing: kSpacingSmall,
      children: categories.map((category) {
        final isSelected = widget.categoriesFilter.contains(category);
        return _buildFilterChip(
          label: category,
          isSelected: isSelected,
          onTap: () {
            final newList = List<String>.from(widget.categoriesFilter);
            if (isSelected) {
              newList.remove(category);
            } else {
              newList.add(category);
            }
            widget.onCategoriesChanged(newList);
          },
        );
      }).toList(),
    );
  }

  Widget _buildContagiousFilter() {
    return Wrap(
      spacing: kSpacingSmall,
      runSpacing: kSpacingSmall,
      children: [
        _buildFilterChip(
          label: '⚠️ Yes',
          isSelected: widget.contagiousFilter == true,
          onTap: () => widget.onContagiousChanged(
            widget.contagiousFilter == true ? null : true,
          ),
        ),
        _buildFilterChip(
          label: '✓ No',
          isSelected: widget.contagiousFilter == false,
          onTap: () => widget.onContagiousChanged(
            widget.contagiousFilter == false ? null : false,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: kSpacingSmall),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        ),
        child: Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
