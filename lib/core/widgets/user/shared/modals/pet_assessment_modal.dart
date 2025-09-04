import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetAssessmentModal extends StatefulWidget {
  const PetAssessmentModal({super.key});

  @override
  State<PetAssessmentModal> createState() => _PetAssessmentModalState();
}

class _PetAssessmentModalState extends State<PetAssessmentModal> {
  String? selectedPetType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kMobileBorderRadiusCard),
          topRight: Radius.circular(kMobileBorderRadiusCard),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(kMobilePaddingLarge),
            child: Column(
              children: [
                // Header
                Text(
                  'Select Pet Type',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the pet you\'re assessing.',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Pet type selection
                Row(
                  children: [
                    Expanded(
                      child: _buildPetTypeCard(
                        type: 'Dog',
                        icon: '🐶',
                        isSelected: selectedPetType == 'Dog',
                        onTap: () => setState(() => selectedPetType = 'Dog'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPetTypeCard(
                        type: 'Cat',
                        icon: '🐱',
                        isSelected: selectedPetType == 'Cat',
                        onTap: () => setState(() => selectedPetType = 'Cat'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedPetType != null ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Disclaimer
                const Text(
                  'This is a preliminary differential analysis. For a confirmed diagnosis, please consult a licensed veterinarian.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetTypeCard({
    required String type,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              type,
              style: kMobileTextStyleTitle.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    // Close modal and navigate to assessment
    Navigator.of(context).pop();
    // Navigate to assessment page with selected pet type
    context.push('/assessment', extra: {'selectedPetType': selectedPetType});
  }
}
