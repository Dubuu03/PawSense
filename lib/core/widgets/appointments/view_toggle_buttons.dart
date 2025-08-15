import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ViewToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const ViewToggleButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent, 
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: kFontSizeRegular,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, 
          ),
        ),
      ),
    );
  }
}
