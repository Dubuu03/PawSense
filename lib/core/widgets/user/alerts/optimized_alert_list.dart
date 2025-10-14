import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_section_header.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_empty_state.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class OptimizedAlertList extends StatefulWidget {
  final List<AlertData> alerts;
  final Function(AlertData)? onAlertTap;
  final Function(AlertData)? onMarkAsRead;
  final Function(AlertData)? onDelete;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;

  const OptimizedAlertList({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.onMarkAsRead,
    this.onDelete,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
  });

  @override
  State<OptimizedAlertList> createState() => _OptimizedAlertListState();
}

class _OptimizedAlertListState extends State<OptimizedAlertList> {
  final ScrollController _scrollController = ScrollController();
  List<AlertListItem> _listItems = [];
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _buildListItems();
  }
  
  @override
  void didUpdateWidget(OptimizedAlertList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alerts != widget.alerts) {
      _buildListItems();
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from bottom
      if (widget.hasMore && !widget.isLoadingMore && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }
  
  void _buildListItems() {
    if (widget.alerts.isEmpty) {
      _listItems = [];
      return;
    }
    
    // Group alerts by time periods for better organization
    final today = <AlertData>[];
    final thisWeek = <AlertData>[];
    final earlier = <AlertData>[];
    
    final now = DateTime.now();
    
    for (final alert in widget.alerts) {
      final difference = now.difference(alert.timestamp).inDays;
      
      if (difference == 0) {
        today.add(alert);
      } else if (difference <= 7) {
        thisWeek.add(alert);
      } else {
        earlier.add(alert);
      }
    }
    
    _listItems = [];
    
    // Add today section
    if (today.isNotEmpty) {
      _listItems.add(AlertListItem.header('TODAY'));
      for (final alert in today) {
        _listItems.add(AlertListItem.alert(alert));
      }
    }
    
    // Add this week section
    if (thisWeek.isNotEmpty) {
      _listItems.add(AlertListItem.header('THIS WEEK'));
      for (final alert in thisWeek) {
        _listItems.add(AlertListItem.alert(alert));
      }
    }
    
    // Add earlier section
    if (earlier.isNotEmpty) {
      _listItems.add(AlertListItem.header('EARLIER'));
      for (final alert in earlier) {
        _listItems.add(AlertListItem.alert(alert));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.alerts.isEmpty) {
      return _buildLoadingState();
    }
    
    if (widget.alerts.isEmpty && !widget.isLoading) {
      return const AlertEmptyState();
    }

    return Container(
      margin: kMobileMarginCard,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _listItems.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end if there's more data
          if (index == _listItems.length) {
            return _buildLoadMoreIndicator();
          }
          
          final item = _listItems[index];
          
          if (item.isHeader) {
            return AlertSectionHeader(
              title: item.title!,
              margin: EdgeInsets.only(
                bottom: kMobileSizedBoxLarge,
                top: index == 0 ? 0 : kMobileSizedBoxXLarge,
              ),
            );
          } else {
            return AlertItem(
              alert: item.alert!,
              onTap: () => widget.onAlertTap?.call(item.alert!),
              onMarkAsRead: () => widget.onMarkAsRead?.call(item.alert!),
              onDelete: item.alert!.type == AlertType.message 
                  ? () => widget.onDelete?.call(item.alert!)
                  : null,
            );
          }
        },
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      margin: kMobileMarginCard,
      child: Column(
        children: [
          // Skeleton loading items
          for (int i = 0; i < 3; i++) ...[
            _buildSkeletonItem(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSkeletonItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle skeleton
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Time skeleton
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadMoreIndicator() {
    if (widget.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }
    
    // Show "Load More" button if not automatically loading
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: widget.onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Load More'),
        ),
      ),
    );
  }
}

/// Helper class to represent list items (headers and alerts)
class AlertListItem {
  final bool isHeader;
  final String? title;
  final AlertData? alert;
  
  AlertListItem._(this.isHeader, this.title, this.alert);
  
  factory AlertListItem.header(String title) {
    return AlertListItem._(true, title, null);
  }
  
  factory AlertListItem.alert(AlertData alert) {
    return AlertListItem._(false, null, alert);
  }
}