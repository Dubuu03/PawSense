import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/skin_disease/category_chip.dart';

/// Category filters component with AI Detectable toggle
class DiseaseFilters extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final String? selectedDetectionMethod;
  final Function(String) onCategorySelected;
  final VoidCallback onDetectionMethodToggled;

  const DiseaseFilters({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDetectionMethod,
    required this.onCategorySelected,
    required this.onDetectionMethodToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Reorder categories: move "Other" to the end
    final reorderedCategories = _reorderCategories(categories);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Category chips in horizontal scroll (no scrollbar)
        if (reorderedCategories.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: reorderedCategories.length + 2, // +2 for "All" and "AI Detectable"
              itemBuilder: (context, index) {
                // First chip: "All"
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: 'All',
                      isSelected: selectedCategory == null,
                      onTap: () => onCategorySelected('All'),
                    ),
                  );
                }
                
                // Second chip: "AI Detectable"
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDetectionMethodToggled,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: selectedDetectionMethod == 'ai'
                                ? AppColors.primary
                                : AppColors.white,
                            border: Border.all(
                              color: selectedDetectionMethod == 'ai'
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '✨',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Detectable',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selectedDetectionMethod == 'ai'
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                
                // Category chips (start from index 2)
                final categoryIndex = index - 2;
                final category = reorderedCategories[categoryIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: category,
                    isSelected: selectedCategory == category,
                    onTap: () => onCategorySelected(category),
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
        
        // AI-DETECTABLE CONDITIONS description (moved below)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-DETECTABLE CONDITIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Conditions PawSense can help you analyze with the in-app scanner.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
  
  /// Reorder categories to move "Other" to the end
  List<String> _reorderCategories(List<String> cats) {
    final List<String> result = [];
    String? otherCategory;
    
    for (var cat in cats) {
      if (cat.toLowerCase() == 'other') {
        otherCategory = cat;
      } else {
        result.add(cat);
      }
    }
    
    // Add "Other" at the end if it exists
    if (otherCategory != null) {
      result.add(otherCategory);
    }
    
    return result;
  }
}
