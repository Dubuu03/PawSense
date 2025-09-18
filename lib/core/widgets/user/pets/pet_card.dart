import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/breed_options.dart';
import 'pet_avatar.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const PetCard({
    super.key,
    required this.pet,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      padding: const EdgeInsets.all(kMobilePaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Row(
        children: [
          // Pet Avatar
          PetAvatar(
            petType: pet.petType,
            imageUrl: pet.imageUrl,
            size: kMobileIconContainerSize,
          ),
          
          const SizedBox(width: kMobileSizedBoxMedium),
          
          // Pet Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.petName,
                  style: kMobileTextStylePetName.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: kMobileFontSizeServiceTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.petType} • ${_getFormattedBreed(pet.petType, pet.breed)}',
                  style: kMobileTextStyleServiceSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.ageString} • ${pet.weightString}',
                  style: kMobileTextStylePetType.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions Menu
          if (showActions) _buildActionsMenu(),
        ],
      ),
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: kMobileSizedBoxSmall),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: kMobileSizedBoxSmall),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(kMobileSizedBoxSmall),
        child: const Icon(
          Icons.more_vert,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  // Helper method to format and validate breed display
  String _getFormattedBreed(String petType, String breed) {
    try {
      // Get valid breeds for the pet type
      final validBreeds = BreedOptions.getBreedsForPetType(petType);
      
      // Check if the breed is in the valid list
      if (validBreeds.contains(breed)) {
        return breed;
      }
      
      // If breed is not found, try to find a close match
      final lowerBreed = breed.toLowerCase();
      for (final validBreed in validBreeds) {
        if (validBreed.toLowerCase() == lowerBreed) {
          return validBreed;
        }
      }
      
      // If no match found, return the original breed with a note
      return '$breed (Custom)';
    } catch (e) {
      // If there's any error, just return the original breed
      return breed;
    }
  }
}