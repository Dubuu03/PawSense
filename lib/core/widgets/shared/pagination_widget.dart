import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final Function(int) onPageChanged;
  final bool isLoading;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox();

    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Showing ${_getStartItem()}-${_getEndItem()} of $totalItems items',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: (currentPage > 1 && !isLoading) ? () => onPageChanged(currentPage - 1) : null,
                icon: Icon(Icons.chevron_left, size: kIconSizeMedium),
                color: (currentPage > 1 && !isLoading) ? AppColors.primary : AppColors.textTertiary,
              ),
              ...List.generate(
                _getVisiblePages().length,
                (index) {
                  final page = _getVisiblePages()[index];
                  if (page == -1) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSpacingSmall),
                      child: Text(
                        '...',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: !isLoading ? () => onPageChanged(page) : null,
                      style: TextButton.styleFrom(
                        backgroundColor: page == currentPage 
                            ? AppColors.primary 
                            : Colors.transparent,
                        foregroundColor: page == currentPage 
                            ? AppColors.white 
                            : AppColors.primary,
                        minimumSize: Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        ),
                      ),
                      child: Text(
                        page.toString(),
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: (currentPage < totalPages && !isLoading) ? () => onPageChanged(currentPage + 1) : null,
                icon: Icon(Icons.chevron_right, size: kIconSizeMedium),
                color: currentPage < totalPages ? AppColors.primary : AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getStartItem() {
    const itemsPerPage = 5; // Fixed at 5 items per page
    return ((currentPage - 1) * itemsPerPage) + 1;
  }

  int _getEndItem() {
    const itemsPerPage = 5; // Fixed at 5 items per page
    final endItem = currentPage * itemsPerPage;
    return endItem > totalItems ? totalItems : endItem;
  }

  List<int> _getVisiblePages() {
    const delta = 2;
    List<int> pages = [];
    
    if (totalPages <= 7) {
      // Show all pages if total is small
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Always show first page
      pages.add(1);
      
      // Add ellipsis if needed
      if (currentPage - delta > 2) {
        pages.add(-1);
      }
      
      // Add pages around current page
      final start = (currentPage - delta) > 1 ? (currentPage - delta) : 2;
      final end = (currentPage + delta) < totalPages ? (currentPage + delta) : totalPages - 1;
      
      for (int i = start; i <= end; i++) {
        pages.add(i);
      }
      
      // Add ellipsis if needed
      if (currentPage + delta < totalPages - 1) {
        pages.add(-1);
      }
      
      // Always show last page
      if (totalPages > 1) {
        pages.add(totalPages);
      }
    }
    
    return pages;
  }
}
