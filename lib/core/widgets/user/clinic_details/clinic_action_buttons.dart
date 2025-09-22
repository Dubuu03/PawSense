import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';

class ClinicActionButtons extends StatelessWidget {
  final ClinicDetails clinic;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onMessageClinic;

  const ClinicActionButtons({
    super.key,
    required this.clinic,
    this.onBookAppointment,
    this.onMessageClinic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        children: [
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: clinic.isActive ? onBookAppointment : null,
                  icon: Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: kMobilePaddingSmall,
                      horizontal: kMobilePaddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: kMobileBorderRadiusButtonPreset,
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(width: kMobileSizedBoxMedium),
              
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: clinic.isActive ? onMessageClinic : null,
                  icon: Icon(Icons.message, size: 16),
                  label: Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      vertical: kMobilePaddingSmall,
                      horizontal: kMobilePaddingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: kMobileBorderRadiusButtonPreset,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (!clinic.isActive) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Container(
              padding: const EdgeInsets.all(kMobilePaddingSmall),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: kMobileBorderRadiusButtonPreset,
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: kMobileSizedBoxMedium),
                  Expanded(
                    child: Text(
                      'This clinic is currently inactive',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}