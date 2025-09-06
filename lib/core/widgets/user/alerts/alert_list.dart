import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_section_header.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_empty_state.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AlertList extends StatelessWidget {
  final List<AlertData> alerts;
  final Function(AlertData)? onAlertTap;
  final Function(AlertData)? onMarkAsRead;

  const AlertList({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const AlertEmptyState();
    }

    // Group alerts by time periods
    final today = <AlertData>[];
    final thisWeek = <AlertData>[];
    final earlier = <AlertData>[];

    final now = DateTime.now();
    
    for (final alert in alerts) {
      final difference = now.difference(alert.timestamp).inDays;
      
      if (difference == 0) {
        today.add(alert);
      } else if (difference <= 7) {
        thisWeek.add(alert);
      } else {
        earlier.add(alert);
      }
    }

    return Container(
      margin: kMobileMarginCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today section
          if (today.isNotEmpty) ...[
            AlertSectionHeader(
              title: 'TODAY',
              margin: const EdgeInsets.only(bottom: kMobileSizedBoxLarge),
            ),
            ...today.map((alert) => AlertItem(
              alert: alert,
              onTap: () => onAlertTap?.call(alert),
              onMarkAsRead: () => onMarkAsRead?.call(alert),
            )),
          ],

          // This week section
          if (thisWeek.isNotEmpty) ...[
            AlertSectionHeader(title: 'THIS WEEK'),
            ...thisWeek.map((alert) => AlertItem(
              alert: alert,
              onTap: () => onAlertTap?.call(alert),
              onMarkAsRead: () => onMarkAsRead?.call(alert),
            )),
          ],

          // Earlier section
          if (earlier.isNotEmpty) ...[
            AlertSectionHeader(title: 'EARLIER'),
            ...earlier.map((alert) => AlertItem(
              alert: alert,
              onTap: () => onAlertTap?.call(alert),
              onMarkAsRead: () => onMarkAsRead?.call(alert),
            )),
          ],

          // Bottom padding
          const SizedBox(height: kMobileSizedBoxXLarge),
        ],
      ),
    );
  }
}
