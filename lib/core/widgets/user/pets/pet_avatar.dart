import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetAvatar extends StatelessWidget {
  final String petType;
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const PetAvatar({
    super.key,
    required this.petType,
    this.imageUrl,
    this.size = kMobilePetIconContainerSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? kMobileBorderRadiusIconPreset;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: radius,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPetIcon();
                },
              ),
            )
          : _buildPetIcon(),
    );
  }

  Widget _buildPetIcon() {
    IconData icon;
    switch (petType.toLowerCase()) {
      case 'dog':
        icon = Icons.pets;
        break;
      case 'cat':
        icon = Icons.pets;
        break;
      default:
        icon = Icons.pets;
    }

    return Icon(
      icon,
      size: kMobilePetIconSize, // Use constant pet icon size
      color: AppColors.primary,
    );
  }
}