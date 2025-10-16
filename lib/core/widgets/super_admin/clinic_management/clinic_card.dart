import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'clinic_details_modal.dart';

class ClinicCard extends StatelessWidget {
  final ClinicRegistration clinic;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final Function(ClinicRegistration)? onUpdateClinic;

  const ClinicCard({
    super.key,
    required this.clinic,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    this.onUpdateClinic,
  });

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
          // Clinic Logo
          _buildClinicLogo(),
          SizedBox(width: kSpacingMedium),
          
          // Clinic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clinic.clinicName,
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (clinic.status == ClinicStatus.approved)
                      Container(
                        margin: EdgeInsets.only(left: kSpacingSmall),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: kSpacingSmall),
                // Rating Display
                if (clinic.totalRatings != null && clinic.totalRatings! > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${clinic.averageRating?.toStringAsFixed(1) ?? '0.0'}',
                        style: kTextStyleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(${clinic.totalRatings} ${clinic.totalRatings == 1 ? 'review' : 'reviews'})',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No reviews yet',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
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
                    onPressed: () => _showClinicDetailsModal(context),
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

  Widget _buildClinicLogo() {
    // Check if clinic has a logo URL
    if (clinic.logoUrl != null && clinic.logoUrl!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            clinic.logoUrl!,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultLogo();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            },
          ),
        ),
      );
    }

    // Default logo if no URL
    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.local_hospital,
        size: 30,
        color: _getStatusColor(),
      ),
    );
  }

  void _showClinicDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClinicDetailsModal(
        clinic: clinic,
        onUpdateClinic: onUpdateClinic,
        onStatusChange: (status, reason) {
          // Handle status changes based on the new status
          switch (status) {
            case ClinicStatus.approved:
              onApprove();
              break;
            case ClinicStatus.rejected:
              onReject();
              break;
            case ClinicStatus.suspended:
              onSuspend();
              break;
            case ClinicStatus.pending:
              // Handle pending status if needed
              break;
          }
        },
      ),
    );
  }
}
