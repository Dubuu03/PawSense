import 'package:flutter/material.dart';
import '../../../models/support/faq_item_model.dart';
import '../../../services/support/faq_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../guards/auth_guard.dart';
import 'faq_item.dart';
import 'faq_management_modal.dart';

class FAQList extends StatefulWidget {
  final String? searchQuery;
  
  const FAQList({super.key, this.searchQuery});

  @override
  _FAQListState createState() => _FAQListState();
}

class _FAQListState extends State<FAQList> {
  List<FAQItemModel> _faqItems = [];
  List<FAQItemModel> _filteredFaqItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = await AuthGuard.getCurrentUser();
    if (mounted) {
      setState(() {
        _isSuperAdmin = user?.role == 'super_admin';
      });
    }
  }

  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final faqs = await FAQService.getFAQsForCurrentUser();
      if (mounted) {
        setState(() {
          _faqItems = faqs;
          _applySearchFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load FAQs: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applySearchFilter() {
    final query = widget.searchQuery?.toLowerCase() ?? '';
    
    if (query.isEmpty) {
      _filteredFaqItems = _faqItems;
    } else {
      _filteredFaqItems = _faqItems.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query) ||
            faq.category.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  void didUpdateWidget(FAQList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      setState(() {
        _applySearchFilter();
      });
    }
  }

  void _showAddFAQModal() {
    showDialog(
      context: context,
      builder: (context) => FAQManagementModal(
        onSaved: _loadFAQs,
      ),
    );
  }

  void _showEditFAQModal(FAQItemModel faq) {
    showDialog(
      context: context,
      builder: (context) => FAQManagementModal(
        faq: faq,
        onSaved: _loadFAQs,
      ),
    );
  }

  Future<void> _deleteFAQ(FAQItemModel faq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete FAQ'),
        content: Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FAQService.deleteFAQ(faq.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FAQ deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadFAQs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete FAQ'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: kSpacingMedium),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kSpacingMedium),
            ElevatedButton(
              onPressed: _loadFAQs,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with Add button
        Padding(
          padding: EdgeInsets.only(bottom: kSpacingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSuperAdmin
                    ? 'General App FAQs'
                    : 'Clinic FAQs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddFAQModal,
                icon: Icon(Icons.add, size: 18),
                label: Text('Add FAQ'),
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
              ),
            ],
          ),
        ),

        // FAQ List or Empty State
        Expanded(
          child: _filteredFaqItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(height: kSpacingMedium),
                      Text(
                        widget.searchQuery?.isNotEmpty == true
                            ? 'No FAQs match your search'
                            : 'No FAQs yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        widget.searchQuery?.isNotEmpty == true
                            ? 'Try different keywords'
                            : 'Create your first FAQ to help users',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (_faqItems.isEmpty) ...[
                        SizedBox(height: kSpacingLarge),
                        ElevatedButton.icon(
                          onPressed: _showAddFAQModal,
                          icon: Icon(Icons.add),
                          label: Text('Add Your First FAQ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: kSpacingLarge,
                              vertical: kSpacingMedium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFAQs,
                  child: ListView.separated(
                    itemCount: _filteredFaqItems.length,
                    separatorBuilder: (context, index) => SizedBox(height: kSpacingMedium),
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqItems[index];
                      return FAQItem(
                        faqItem: faq,
                        onToggleExpanded: () {
                          setState(() {
                            // Update the original item in _faqItems
                            final originalIndex = _faqItems.indexWhere((f) => f.id == faq.id);
                            if (originalIndex != -1) {
                              _faqItems[originalIndex] = _faqItems[originalIndex].copyWith(
                                isExpanded: !_faqItems[originalIndex].isExpanded,
                              );
                              _applySearchFilter();
                            }
                          });
                        },
                        onEdit: () => _showEditFAQModal(faq),
                        onDelete: () => _deleteFAQ(faq),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}