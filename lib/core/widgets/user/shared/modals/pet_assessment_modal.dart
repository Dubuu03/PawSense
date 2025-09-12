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
  bool _isLoading = false;

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
                        onTap: _isLoading ? () {} : () => setState(() => selectedPetType = 'Dog'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPetTypeCard(
                        type: 'Cat',
                        icon: '🐱',
                        isSelected: selectedPetType == 'Cat',
                        onTap: _isLoading ? () {} : () => setState(() => selectedPetType = 'Cat'),
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
                    onPressed: selectedPetType != null && !_isLoading ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    icon,
                    style: TextStyle(
                      fontSize: 40,
                      color: _isLoading ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    type,
                    style: kMobileTextStyleTitle.copyWith(
                      color: _isLoading
                          ? Colors.grey
                          : (isSelected ? AppColors.primary : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading overlay for cards
            if (_isLoading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
          ],
        ),
      ),
    );
  }
  void _onContinue() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading time and prepare navigation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close modal first
      Navigator.of(context).pop();
      
      // Navigate to assessment page with selected pet type and from parameter
      context.go('/assessment?from=/home', extra: {'selectedPetType': selectedPetType});
    } catch (e) {
      // Handle any errors
      setState(() {
        _isLoading = false;
      });
      
      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to assessment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
