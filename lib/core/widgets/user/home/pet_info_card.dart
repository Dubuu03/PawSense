import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetInfo {
  final String name;
  final String type;
  final IconData icon;
  final String? nextAppointment;

  PetInfo({
    required this.name,
    required this.type,
    required this.icon,
    this.nextAppointment,
  });
}

class PetInfoCard extends StatelessWidget {
  final List<PetInfo> pets;
  final String? nextAppointmentDate;
  final String? nextAppointmentTime;

  const PetInfoCard({
    super.key,
    required this.pets,
    this.nextAppointmentDate,
    this.nextAppointmentTime,
  });

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
          // Title row with View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Pets',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (pets.length > 2)
                TextButton(
                  onPressed: () {
                    // Handle view all pets
                  },
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
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Pets and appointment row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pets section - 2 columns, multiple rows
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // First row of pets
                      Row(
                        children: pets.take(2).map((pet) => 
                          Expanded(child: _buildPetIcon(pet))
                        ).toList(),
                      ),
                      // Second row of pets if there are more than 2
                      if (pets.length > 2) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: pets.skip(2).take(2).map((pet) => 
                            Expanded(child: _buildPetIcon(pet))
                          ).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // View All button below pets
                      Container(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle view all pets
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Next appointment section
                if (nextAppointmentDate != null && nextAppointmentTime != null)
                  Expanded(
                    flex: 3,
                    child: _buildNextAppointment(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetIcon(PetInfo pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pet.icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pet.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Appointment',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextAppointmentDate ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      nextAppointmentTime ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
