import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'clinic_card.dart';

class ClinicsList extends StatelessWidget {
  final List<ClinicRegistration> clinics;
  final bool isLoading;
  final int totalClinics; // Add total clinics count
  final Function(ClinicRegistration) onViewDetails;
  final Function(ClinicRegistration) onApprove;
  final Function(ClinicRegistration) onReject;
  final Function(ClinicRegistration) onSuspend;

  const ClinicsList({
    Key? key,
    required this.clinics,
    required this.isLoading,
    required this.totalClinics,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: EdgeInsets.all(kSpacingLarge * 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(kShadowOpacity),
              spreadRadius: kShadowSpreadRadius,
              blurRadius: kShadowBlurRadius,
              offset: kShadowOffset,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: kSpacingMedium),
              Text(
                'Loading clinics...',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (clinics.isEmpty) {
      return Container(
        padding: EdgeInsets.all(kSpacingLarge * 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(kShadowOpacity),
              spreadRadius: kShadowSpreadRadius,
              blurRadius: kShadowBlurRadius,
              offset: kShadowOffset,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: kSpacingMedium),
              Text(
                'No clinics found',
                style: kTextStyleLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: kSpacingSmall),
              Text(
                'Try adjusting your search criteria',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
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
        children: [
          Text(
            'Clinic Registrations ($totalClinics)',
            style: kTextStyleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingMedium),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return ClinicCard(
                clinic: clinic,
                onViewDetails: () => onViewDetails(clinic),
                onApprove: () => onApprove(clinic),
                onReject: () => onReject(clinic),
                onSuspend: () => onSuspend(clinic),
              );
            },
          ),
        ],
      ),
    );
  }
}
