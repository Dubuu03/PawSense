// widgets/superadmin/model_training/training_image_list_view.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../services/superadmin/model_training_service.dart';

class TrainingImageListView extends StatelessWidget {
  final List<String> labels;
  final Map<String, List<TrainingImageData>> groupedImages;
  final Set<String> expandedLabels;
  final Set<String> selectedImageIds;
  final TrainingImageData? selectedImage;
  final Function(String) onLabelToggle;
  final Function(TrainingImageData) onImageSelect;
  final Function(String) onImageToggleSelection;
  final Function(String, bool) onSelectAllInLabel;
  final List<TrainingImageData> Function(String) getImagesForLabel;

  const TrainingImageListView({
    Key? key,
    required this.labels,
    required this.groupedImages,
    required this.expandedLabels,
    required this.selectedImageIds,
    required this.selectedImage,
    required this.onLabelToggle,
    required this.onImageSelect,
    required this.onImageToggleSelection,
    required this.onSelectAllInLabel,
    required this.getImagesForLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Checkbox space
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Disease Label',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Images',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Pet Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // List Items
          Expanded(
            child: ListView.builder(
              itemCount: labels.length,
              itemBuilder: (context, index) {
                final label = labels[index];
                final images = getImagesForLabel(label);
                final isExpanded = expandedLabels.contains(label);
                
                final allImagesSelected = images.every((img) => selectedImageIds.contains(img.id));
                
                return Column(
                  children: [
                    // Label Row
                    InkWell(
                      onTap: () => onLabelToggle(label),
                      onDoubleTap: () => onSelectAllInLabel(label, !allImagesSelected),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            Checkbox(
                              value: allImagesSelected,
                              tristate: true,
                              onChanged: (value) {
                                onSelectAllInLabel(label, value ?? false);
                              },
                              activeColor: AppColors.primary,
                            ),
                            
                            // Expand Icon
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            
                            // Disease Icon
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.medical_services, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            
                            // Label Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            
                            // Image Count
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${images.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Pet Types
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: _buildPetTypeChips(images),
                              ),
                            ),
                            
                            // Validation Types
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: _buildValidationTypeChips(images),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded Images
                    if (isExpanded)
                      ...images.map((image) => _buildImageRow(image)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(TrainingImageData image) {
    final isSelected = selectedImageIds.contains(image.id);
    final isCurrentlyViewed = selectedImage?.id == image.id;
    
    return InkWell(
      onTap: () => onImageSelect(image),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentlyViewed 
              ? AppColors.primary.withOpacity(0.05)
              : (isSelected ? AppColors.info.withOpacity(0.03) : Colors.white),
          border: Border(
            left: BorderSide(
              color: isCurrentlyViewed ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => onImageToggleSelection(image.id),
              activeColor: AppColors.primary,
            ),
            
            const SizedBox(width: 28), // Align with parent
            
            // Thumbnail
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: image.primaryImageUrl.isNotEmpty
                    ? Image.network(
                        image.primaryImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 24, color: AppColors.textSecondary);
                        },
                      )
                    : const Icon(Icons.image, size: 24, color: AppColors.textSecondary),
              ),
            ),
            
            // Filename
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.uniqueFilename ?? '${image.id.substring(0, 12)}.jpg',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${image.petBreed} • ${_formatDate(image.validatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Image indicator
            const Expanded(
              flex: 1,
              child: SizedBox(), // Empty space
            ),
            
            // Pet Type
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPetTypeColor(image.petType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    image.petType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getPetTypeColor(image.petType),
                    ),
                  ),
                ),
              ),
            ),
            
            // Validation Type
            Expanded(
              flex: 1,
              child: Center(
                child: _buildValidationBadge(image),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetTypeChips(List<TrainingImageData> images) {
    final petTypes = images.map((img) => img.petType).toSet().toList();
    
    if (petTypes.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getPetTypeColor(petTypes.first).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          petTypes.first,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getPetTypeColor(petTypes.first),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 4,
      children: petTypes.map((type) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getPetTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type.substring(0, 1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getPetTypeColor(type),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildValidationTypeChips(List<TrainingImageData> images) {
    final hasValidated = images.any((img) => img.canUseForTraining);
    final hasCorrected = images.any((img) => img.canUseForRetraining);
    
    if (hasValidated && hasCorrected) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.success),
          SizedBox(width: 4),
          Icon(Icons.edit, size: 14, color: AppColors.warning),
        ],
      );
    } else if (hasValidated) {
      return const Icon(Icons.check_circle, size: 14, color: AppColors.success);
    } else if (hasCorrected) {
      return const Icon(Icons.edit, size: 14, color: AppColors.warning);
    }
    
    return const SizedBox();
  }

  Widget _buildValidationBadge(TrainingImageData image) {
    if (image.canUseForTraining) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Valid',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    } else if (image.canUseForRetraining) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 12, color: AppColors.warning),
            SizedBox(width: 4),
            Text(
              'Fixed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox();
  }

  Color _getPetTypeColor(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return const Color(0xFF2196F3);
      case 'cat':
        return const Color(0xFFFF9800);
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
