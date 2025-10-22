import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.title,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDisabled 
        ? AppColors.textSecondary.withOpacity(0.4)
        : isActive 
            ? AppColors.primary 
            : AppColors.textSecondary;
    
    final Color textColor = isDisabled 
        ? AppColors.textSecondary.withOpacity(0.4)
        : isActive 
            ? AppColors.primary 
            : AppColors.textSecondary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive && !isDisabled 
            ? AppColors.primary.withOpacity(0.08) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive && !isDisabled 
              ? AppColors.primary.withOpacity(0.5) 
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: kFontSizeRegular,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            color: textColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: isDisabled ? null : onTap,
        mouseCursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      ),
    );
  }
}
