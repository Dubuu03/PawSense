import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
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

  bool get _hasActiveFilters {
    return widget.detectionFilter != null ||
        widget.speciesFilter.isNotEmpty ||
        widget.severityFilter != null ||
        widget.categoriesFilter.isNotEmpty ||
        widget.contagiousFilter != null ||
        widget.searchQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar and Sort/Export
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 16),
              _buildSortDropdown(),
              const SizedBox(width: 12),
              _buildExportButton(),
            ],
          ),

          const SizedBox(height: 16),

          // Detection Filter
          _buildFilterSection(
            'Detection Method',
            _buildDetectionFilter(),
          ),

          const SizedBox(height: 12),

          // Species Filter
          _buildFilterSection(
            'Species',
            _buildSpeciesFilter(),
          ),

          const SizedBox(height: 12),

          // Severity Filter
          _buildFilterSection(
            'Severity',
            _buildSeverityFilter(),
          ),

          const SizedBox(height: 12),

          // Categories Filter
          _buildFilterSection(
            'Categories',
            _buildCategoriesFilter(),
          ),

          const SizedBox(height: 12),

          // Contagious Filter
          _buildFilterSection(
            'Contagious',
            _buildContagiousFilter(),
          ),

          const SizedBox(height: 16),

          // Clear Filters Button
          if (_hasActiveFilters) _buildClearFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, symptoms, causes...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
        suffixIcon: widget.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                onPressed: () {
                  _searchController.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: widget.sortBy,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
        items: const [
          DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
          DropdownMenuItem(value: 'name_desc', child: Text('Name Z-A')),
          DropdownMenuItem(value: 'date_added', child: Text('Recently Added')),
          DropdownMenuItem(value: 'date_updated', child: Text('Recently Updated')),
          DropdownMenuItem(value: 'most_viewed', child: Text('Most Viewed')),
          DropdownMenuItem(value: 'severity', child: Text('Severity')),
        ],
        onChanged: (value) {
          if (value != null) widget.onSortChanged(value);
        },
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: widget.onExportCSV,
      icon: const Icon(Icons.file_download_outlined, size: 18),
      label: const Text('Export CSV'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDetectionFilter() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip(
          label: '✨ AI-Detectable',
          isSelected: widget.detectionFilter == 'ai',
          onTap: () {
            widget.onDetectionChanged(
              widget.detectionFilter == 'ai' ? null : 'ai',
            );
          },
        ),
        _buildFilterChip(
          label: 'ℹ️ Info Only',
          isSelected: widget.detectionFilter == 'info',
          onTap: () {
            widget.onDetectionChanged(
              widget.detectionFilter == 'info' ? null : 'info',
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpeciesFilter() {
    return Wrap(
      spacing: 8,
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

  Widget _buildSeverityFilter() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip(
          label: 'Mild',
          isSelected: widget.severityFilter == 'mild',
          color: const Color(0xFF10B981),
          onTap: () {
            widget.onSeverityChanged(
              widget.severityFilter == 'mild' ? null : 'mild',
            );
          },
        ),
        _buildFilterChip(
          label: 'Moderate',
          isSelected: widget.severityFilter == 'moderate',
          color: const Color(0xFFFF9500),
          onTap: () {
            widget.onSeverityChanged(
              widget.severityFilter == 'moderate' ? null : 'moderate',
            );
          },
        ),
        _buildFilterChip(
          label: 'Severe',
          isSelected: widget.severityFilter == 'severe',
          color: const Color(0xFFEF4444),
          onTap: () {
            widget.onSeverityChanged(
              widget.severityFilter == 'severe' ? null : 'severe',
            );
          },
        ),
        _buildFilterChip(
          label: 'Varies',
          isSelected: widget.severityFilter == 'varies',
          color: Colors.grey.shade600,
          onTap: () {
            widget.onSeverityChanged(
              widget.severityFilter == 'varies' ? null : 'varies',
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    final categories = [
      'Allergic',
      'Bacterial',
      'Fungal',
      'Parasitic',
      'Hormonal',
      'Other',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
      spacing: 8,
      children: [
        _buildFilterChip(
          label: '⚠️ Contagious Only',
          isSelected: widget.contagiousFilter == true,
          color: const Color(0xFFEF4444),
          onTap: () {
            widget.onContagiousChanged(
              widget.contagiousFilter == true ? null : true,
            );
          },
        ),
        _buildFilterChip(
          label: '✓ Non-Contagious Only',
          isSelected: widget.contagiousFilter == false,
          color: const Color(0xFF10B981),
          onTap: () {
            widget.onContagiousChanged(
              widget.contagiousFilter == false ? null : false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? chipColor : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onClearFilters,
        icon: const Icon(Icons.clear_all, size: 18),
        label: const Text('Clear All Filters'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
