import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool isLoading;

  const SummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading 
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: kFontSizeRegular + 2,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: kFontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
