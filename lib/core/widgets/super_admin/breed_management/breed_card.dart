import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';

class BreedCard extends StatelessWidget {
  final PetBreed breed;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const BreedCard({
    super.key,
    required this.breed,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadius),
      hoverColor: AppColors.primary.withValues(alpha: 0.05),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kSpacingMedium + 4,
          vertical: kSpacingMedium,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Breed name
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.only(right: kSpacingSmall),
                child: Text(
                  breed.name,
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            
            // Species chip
            SizedBox(
              width: 100,
              child: _buildSpeciesChip(),
            ),
            SizedBox(width: kSpacingLarge),
            
            // Status toggle
            SizedBox(
              width: 100,
              child: Center(
                child: Switch(
                  value: breed.isActive,
                  onChanged: onStatusToggle,
                  activeColor: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            
            // Date added
            SizedBox(
              width: 100,
              child: Text(
                _formatDate(breed.createdAt),
                style: kTextStyleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: kSpacingLarge),
            
            // Actions
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.info,
                    onPressed: onEdit,
                    tooltip: 'Edit Breed',
                    splashRadius: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: kSpacingSmall),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                    onPressed: onDelete,
                    tooltip: 'Delete Breed',
                    splashRadius: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesChip() {
    final isCat = breed.species == 'cat';
    final chipColor = isCat ? Color(0xFFFF9500) : Color(0xFF007AFF);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCat ? Icons.pets : Icons.pets,
              size: 14,
              color: chipColor,
            ),
            SizedBox(width: 4),
            Text(
              breed.speciesDisplayName,
              style: kTextStyleSmall.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
