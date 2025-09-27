import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/tab_toggle.dart';
import 'package:pawsense/core/widgets/user/home/ai_history_list.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_list.dart';

class HistorySection extends StatefulWidget {
  final List<AIHistoryData> aiHistory;
  final List<AppointmentHistoryData> appointmentHistory;
  final bool isHistoryLoading;
  final VoidCallback? onViewAllPressed;

  const HistorySection({
    super.key,
    required this.aiHistory,
    required this.appointmentHistory,
    this.isHistoryLoading = false,
    this.onViewAllPressed,
  });

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI and appointment records',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (widget.onViewAllPressed != null)
                TextButton(
                  onPressed: widget.onViewAllPressed,
                  style: TextButton.styleFrom(
                    padding: kMobileButtonPadding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: kMobileTextStyleViewAll.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: kMobileSizedBoxXLarge),

          // Tab Toggle
          TabToggle(
            selectedIndex: _selectedTabIndex,
            onTabChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            tabs: const ['AI History', 'Appointment History'],
          ),

          const SizedBox(height: kMobileSizedBoxXLarge),

          // Content based on selected tab
          if (_selectedTabIndex == 0) ...[
            widget.isHistoryLoading 
                ? _buildLoadingState()
                : AIHistoryList(aiHistory: widget.aiHistory),
          ] else ...[
            AppointmentHistoryList(appointmentHistory: widget.appointmentHistory),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading assessment history...',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
