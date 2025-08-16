import 'package:flutter/material.dart';
import '../../../models/faq_item_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class FAQItem extends StatefulWidget {
  final FAQItemModel faqItem;
  final VoidCallback? onToggleExpanded;

  const FAQItem({
    super.key,
    required this.faqItem,
    this.onToggleExpanded,
  });

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.faqItem.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      if (widget.faqItem.isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
    widget.onToggleExpanded?.call();
  }

  Color _getCategoryColor() {
    switch (widget.faqItem.category) {
      case 'Appointments':
        return Colors.blue;
      case 'Emergency Care':
        return Colors.red;
      case 'Technology':
        return Colors.purple;
      case 'Billing':
        return Colors.green;
      case 'Preventive Care':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(kSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.faqItem.question,
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.faqItem.category,
                          style: TextStyle(
                            color: _getCategoryColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: kSpacingSmall),
                      RotationTransition(
                        turns: _animation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: kSpacingSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${widget.faqItem.views} views',
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: kSpacingMedium),
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${widget.faqItem.helpfulVotes} found helpful',
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                kSpacingLarge,
                0,
                kSpacingLarge,
                kSpacingLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: Colors.grey.shade200,
                    thickness: 1,
                  ),
                  SizedBox(height: kSpacingMedium),
                  Text(
                    widget.faqItem.answer,
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: kSpacingMedium),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Handle edit
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 16,
                        ),
                        label: Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      SizedBox(width: kSpacingSmall),
                      TextButton.icon(
                        onPressed: () {
                          // Handle delete
                        },
                        icon: Icon(
                          Icons.delete_outlined,
                          size: 16,
                        ),
                        label: Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
