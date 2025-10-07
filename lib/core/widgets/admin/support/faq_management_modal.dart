import 'package:flutter/material.dart';
import '../../../models/support/faq_item_model.dart';
import '../../../services/support/faq_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../guards/auth_guard.dart';

class FAQManagementModal extends StatefulWidget {
  final FAQItemModel? faq; // null for creating new FAQ
  final VoidCallback? onSaved;

  const FAQManagementModal({
    super.key,
    this.faq,
    this.onSaved,
  });

  @override
  State<FAQManagementModal> createState() => _FAQManagementModalState();
}

class _FAQManagementModalState extends State<FAQManagementModal> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isPublished = true;
  bool _isLoading = false;
  bool _isSuperAdmin = false;

  final List<String> _categories = [
    'General',
    'Appointments',
    'Emergency Care',
    'Technology',
    'Billing',
    'Preventive Care',
    'Services',
    'Account',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    if (widget.faq != null) {
      _questionController.text = widget.faq!.question;
      _answerController.text = widget.faq!.answer;
      _selectedCategory = widget.faq!.category;
      _isPublished = widget.faq!.isPublished;
    }
  }

  Future<void> _checkUserRole() async {
    final user = await AuthGuard.getCurrentUser();
    if (mounted) {
      setState(() {
        _isSuperAdmin = user?.role == 'super_admin';
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveFAQ() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (widget.faq == null) {
        // Create new FAQ
        success = await FAQService.createFAQ(
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          category: _selectedCategory,
          isSuperAdminFAQ: _isSuperAdmin,
        );
      } else {
        // Update existing FAQ
        success = await FAQService.updateFAQ(
          faqId: widget.faq!.id,
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          category: _selectedCategory,
          isPublished: _isPublished,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.faq == null ? 'FAQ created successfully' : 'FAQ updated successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onSaved?.call();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save FAQ. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.faq != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_outlined : Icons.add,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit FAQ' : 'Add New FAQ',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _isSuperAdmin
                              ? 'General app FAQ - visible to all users'
                              : 'Clinic-specific FAQ - visible to your patients',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(kSpacingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        'Category',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: kSpacingMedium,
                            vertical: kSpacingMedium,
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      SizedBox(height: kSpacingLarge),

                      // Question
                      Text(
                        'Question',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      TextFormField(
                        controller: _questionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Enter the FAQ question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.all(kSpacingMedium),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          if (value.trim().length < 10) {
                            return 'Question must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: kSpacingLarge),

                      // Answer
                      Text(
                        'Answer',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      TextFormField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Enter the detailed answer...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: EdgeInsets.all(kSpacingMedium),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an answer';
                          }
                          if (value.trim().length < 20) {
                            return 'Answer must be at least 20 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: kSpacingLarge),

                      // Published Status (only for editing)
                      if (isEditing) ...[
                        Container(
                          padding: EdgeInsets.all(kSpacingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Published',
                                      style: kTextStyleRegular.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Unpublished FAQs won\'t be visible to users',
                                      style: kTextStyleSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublished,
                                onChanged: (value) {
                                  setState(() => _isPublished = value);
                                },
                                activeColor: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: EdgeInsets.all(kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingLarge,
                        vertical: kSpacingMedium,
                      ),
                    ),
                  ),
                  SizedBox(width: kSpacingMedium),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveFAQ,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingLarge,
                        vertical: kSpacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : Text(isEditing ? 'Update FAQ' : 'Create FAQ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
