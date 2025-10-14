import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_detail_modal.dart';

enum AppointmentStatus {
  confirmed,
  pending,
  completed,
  cancelled,
}

class AppointmentHistoryData {
  final String id; // Added ID field for navigation
  final String title;
  final String subtitle;
  final AppointmentStatus status;
  final DateTime timestamp;
  final String? clinicName;

  AppointmentHistoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.timestamp,
    this.clinicName,
  });
}

class AppointmentHistoryList extends StatefulWidget {
  final List<AppointmentHistoryData> appointmentHistory;
  final VoidCallback? onAppointmentUpdated;

  const AppointmentHistoryList({
    super.key,
    required this.appointmentHistory,
    this.onAppointmentUpdated,
  });

  @override
  State<AppointmentHistoryList> createState() => _AppointmentHistoryListState();
}

class _AppointmentHistoryListState extends State<AppointmentHistoryList> {
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 10;
  int _currentPage = 1;
  List<AppointmentHistoryData> _displayedItems = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppointmentHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset and reload when data changes
    if (oldWidget.appointmentHistory != widget.appointmentHistory) {
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
    // Sort appointments by date (most recent first)
    final sortedAppointments = List<AppointmentHistoryData>.from(widget.appointmentHistory);
    sortedAppointments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _displayedItems = sortedAppointments.take(_itemsPerPage).toList();
    });
  }

  void _loadMore() {
    if (_isLoadingMore || _displayedItems.length >= widget.appointmentHistory.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for smooth UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Sort appointments by date (most recent first)
        final sortedAppointments = List<AppointmentHistoryData>.from(widget.appointmentHistory);
        sortedAppointments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final nextPage = _currentPage + 1;
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, sortedAppointments.length);
        
        setState(() {
          _displayedItems.addAll(sortedAppointments.sublist(startIndex, endIndex));
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
    if (widget.appointmentHistory.isEmpty) {
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
        return AppointmentHistoryItem(
          data: item,
          onTap: () {
            _showAppointmentDetails(context, item.id);
          },
          onDetailsPressed: () {
            _showAppointmentDetails(context, item.id);
          },
          onAppointmentUpdated: widget.onAppointmentUpdated,
        );
      },
    );
  }

  void _showAppointmentDetails(BuildContext context, String appointmentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppointmentHistoryDetailModal(
          appointmentId: appointmentId,
          onAppointmentUpdated: widget.onAppointmentUpdated,
        ),
      ),
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
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: kMobilePaddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'No appointments yet',
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

class AppointmentHistoryItem extends StatelessWidget {
  final AppointmentHistoryData data;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsPressed;
  final VoidCallback? onAppointmentUpdated;

  const AppointmentHistoryItem({
    super.key,
    required this.data,
    this.onTap,
    this.onDetailsPressed,
    this.onAppointmentUpdated,
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
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
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
                
                // Details button
                if (onDetailsPressed != null)
                  TextButton(
                    onPressed: onDetailsPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (data.status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.info;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (data.status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
