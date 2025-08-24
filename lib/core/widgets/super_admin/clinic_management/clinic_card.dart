import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class ClinicCard extends StatelessWidget {
  final ClinicRegistration clinic;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;

  const ClinicCard({
    Key? key,
    required this.clinic,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
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
        children: [
          // Clinic Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color: _getStatusColor(),
              size: kIconSizeLarge,
            ),
          ),
          SizedBox(width: kSpacingMedium),
          
          // Clinic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clinic.clinicName,
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Text(
                  clinic.email,
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                if (clinic.phone.isNotEmpty)
                  Text(
                    clinic.phone,
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: kIconSizeSmall,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        clinic.address,
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: kSpacingSmall),
                Text(
                  'License: ${clinic.licenseNumber}',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Status and Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(),
              SizedBox(height: kSpacingSmall),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onViewDetails,
                    icon: Icon(Icons.visibility_outlined, size: kIconSizeMedium),
                    color: AppColors.info,
                    tooltip: 'View Details',
                    padding: EdgeInsets.all(kSpacingSmall),
                    constraints: BoxConstraints(),
                  ),
                  if (clinic.status == ClinicStatus.pending) ...[
                    IconButton(
                      onPressed: onApprove,
                      icon: Icon(Icons.check_outlined, size: kIconSizeMedium),
                      color: AppColors.success,
                      tooltip: 'Approve',
                      padding: EdgeInsets.all(kSpacingSmall),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: onReject,
                      icon: Icon(Icons.close_outlined, size: kIconSizeMedium),
                      color: AppColors.error,
                      tooltip: 'Reject',
                      padding: EdgeInsets.all(kSpacingSmall),
                      constraints: BoxConstraints(),
                    ),
                  ],
                  if (clinic.status == ClinicStatus.approved)
                    IconButton(
                      onPressed: onSuspend,
                      icon: Icon(Icons.block_outlined, size: kIconSizeMedium),
                      color: AppColors.warning,
                      tooltip: 'Suspend',
                      padding: EdgeInsets.all(kSpacingSmall),
                      constraints: BoxConstraints(),
                    ),
                  if (clinic.status == ClinicStatus.suspended)
                    IconButton(
                      onPressed: onApprove,
                      icon: Icon(Icons.check_circle_outlined, size: kIconSizeMedium),
                      color: AppColors.success,
                      tooltip: 'Re-approve',
                      padding: EdgeInsets.all(kSpacingSmall),
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
              SizedBox(height: kSpacingSmall),
              Text(
                'Applied: ${_formatDate(clinic.applicationDate)}',
                style: kTextStyleSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (clinic.status) {
      case ClinicStatus.pending:
        return AppColors.clinicPending;
      case ClinicStatus.approved:
        return AppColors.clinicApproved;
      case ClinicStatus.rejected:
        return AppColors.clinicRejected;
      case ClinicStatus.suspended:
        return AppColors.clinicSuspended;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (clinic.status) {
      case ClinicStatus.pending:
        return AppColors.clinicPendingBg;
      case ClinicStatus.approved:
        return AppColors.clinicApprovedBg;
      case ClinicStatus.rejected:
        return AppColors.clinicRejectedBg;
      case ClinicStatus.suspended:
        return AppColors.clinicSuspendedBg;
    }
  }

  Widget _buildStatusChip() {
    final statusColor = _getStatusColor();
    final statusText = clinic.status.displayName;
    final bgColor = _getStatusBackgroundColor();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
