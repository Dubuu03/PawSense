import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_list.dart';
import 'package:pawsense/core/widgets/user/alerts/alerts_app_bar.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class AlertsWidget extends StatefulWidget {
  final List<AlertData> alerts;
  final Function(AlertData)? onAlertTap;
  final Function(AlertData)? onMarkAsRead;
  final VoidCallback? onRefresh;

  const AlertsWidget({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.onMarkAsRead,
    this.onRefresh,
  });

  @override
  State<AlertsWidget> createState() => _AlertsWidgetState();
}

class _AlertsWidgetState extends State<AlertsWidget> {
  @override
  Widget build(BuildContext context) {
    final unreadCount = widget.alerts.where((alert) => !alert.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AlertsAppBar(
        unreadCount: unreadCount,
        onNotificationPressed: () {
          // Handle notification button press if needed
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AlertList(
            alerts: widget.alerts,
            onAlertTap: widget.onAlertTap,
            onMarkAsRead: widget.onMarkAsRead,
          ),
        ),
      ),
    );
  }
}
