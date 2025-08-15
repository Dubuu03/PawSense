import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class VetProfileHeader extends StatelessWidget {
  final VoidCallback? onEditProfile;

  const VetProfileHeader({
    Key? key,
    this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vet Profile & Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your professional profile and service offerings',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onEditProfile,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
