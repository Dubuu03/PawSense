import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

enum AIDetectionType {
  mange,
  ringworm,
  pyoderma,
  hotSpot,
  fleaAllergy,
}

class AIHistoryData {
  final String id; // Added ID field for navigation
  final String title;
  final String subtitle;
  final AIDetectionType type;
  final DateTime timestamp;
  final double? confidence;
  final String? imageUrl; // Added image URL for displaying assessment images

  AIHistoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.confidence,
    this.imageUrl,
  });
}

class AIHistoryList extends StatefulWidget {
  final List<AIHistoryData> aiHistory;

  const AIHistoryList({
    super.key,
    required this.aiHistory,
  });

  @override
  State<AIHistoryList> createState() => _AIHistoryListState();
}

class _AIHistoryListState extends State<AIHistoryList> {
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 10;
  int _currentPage = 1;
  List<AIHistoryData> _displayedItems = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AIHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset and reload when data changes
    if (oldWidget.aiHistory != widget.aiHistory) {
      _currentPage = 1;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    setState(() {
      _displayedItems = widget.aiHistory.take(_itemsPerPage).toList();
    });
  }

  void _loadMore() {
    if (_isLoadingMore || _displayedItems.length >= widget.aiHistory.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for smooth UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final nextPage = _currentPage + 1;
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.aiHistory.length);
        
        setState(() {
          _displayedItems.addAll(widget.aiHistory.sublist(startIndex, endIndex));
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiHistory.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _displayedItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == _displayedItems.length) {
          return _buildLoadingIndicator();
        }

        final item = _displayedItems[index];
        return AIHistoryItem(
          data: item,
          onTap: () {
            context.push('/ai-history/${item.id}');
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kMobilePaddingMedium),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: kMobilePaddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'No AI detections yet',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AIHistoryItem extends StatelessWidget {
  final AIHistoryData data;
  final VoidCallback? onTap;

  const AIHistoryItem({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: kMobileBorderRadiusSmallPreset,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Detection icon/avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.healing,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Assessment image with performance optimizations
                if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        // Add caching and performance optimizations
                        cacheWidth: 150, // Optimize memory usage
                        cacheHeight: 150,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.border,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.border,
                            child: Icon(
                              Icons.pets,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
