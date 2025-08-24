import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class ClinicSummaryCards extends StatelessWidget {
  final int totalClinics;
  final int pendingClinics;
  final int approvedClinics;
  final int rejectedClinics;
  final int suspendedClinics;

  const ClinicSummaryCards({
    Key? key,
    required this.totalClinics,
    required this.pendingClinics,
    required this.approvedClinics,
    required this.rejectedClinics,
    required this.suspendedClinics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Clinics',
            count: totalClinics,
            color: AppColors.primary,
            icon: Icons.local_hospital_outlined,
            bgColor: AppColors.primary.withOpacity(0.1),
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Pending',
            count: pendingClinics,
            color: AppColors.clinicPending,
            icon: Icons.pending_outlined,
            bgColor: AppColors.clinicPendingBg,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Approved',
            count: approvedClinics,
            color: AppColors.clinicApproved,
            icon: Icons.check_circle_outline,
            bgColor: AppColors.clinicApprovedBg,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Rejected',
            count: rejectedClinics,
            color: AppColors.clinicRejected,
            icon: Icons.cancel_outlined,
            bgColor: AppColors.clinicRejectedBg,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Suspended',
            count: suspendedClinics,
            color: AppColors.clinicSuspended,
            icon: Icons.block_outlined,
            bgColor: AppColors.clinicSuspendedBg,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: kIconSizeLarge,
                ),
              ),
              Text(
                count.toString(),
                style: kTextStyleTitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            title,
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
