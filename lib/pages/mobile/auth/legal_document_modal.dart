import 'package:flutter/material.dart';
import '../../../core/models/system/legal_document_model.dart';
import '../../../core/widgets/mobile/legal_document_viewer.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants_mobile.dart';

/// Legal Document Modal for Mobile
///
/// Modal dialog that displays legal documents (Terms & Conditions, Privacy Policy)
/// from Firestore with scroll detection and acceptance requirement.
class LegalDocumentModal extends StatefulWidget {
  final DocumentType documentType;
  final bool requireAcceptance;

  const LegalDocumentModal({
    super.key,
    required this.documentType,
    this.requireAcceptance = true,
  });

  @override
  State<LegalDocumentModal> createState() => _LegalDocumentModalState();
}

class _LegalDocumentModalState extends State<LegalDocumentModal>
    with TickerProviderStateMixin {
  bool _scrolledToBottom = false;
  bool _checked = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.documentType) {
      case DocumentType.termsAndConditions:
        return 'Terms and Conditions';
      case DocumentType.privacyPolicy:
        return 'Privacy Policy';
      case DocumentType.userAgreement:
        return 'User Agreement';
      case DocumentType.other:
        return 'Legal Document';
    }
  }

  String get _subtitle {
    if (widget.requireAcceptance) {
      return 'Please read and accept our terms to continue';
    }
    return 'Please review our ${widget.documentType.displayName.toLowerCase()}';
  }

  IconData get _icon {
    switch (widget.documentType) {
      case DocumentType.termsAndConditions:
        return Icons.pets_rounded;
      case DocumentType.privacyPolicy:
        return Icons.privacy_tip_outlined;
      case DocumentType.userAgreement:
        return Icons.assignment_outlined;
      case DocumentType.other:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: kMobilePaddingMedium,
            vertical: 30,
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    kMobilePaddingMedium,
                    kMobilePaddingMedium,
                    kMobilePaddingMedium,
                    kMobilePaddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(kMobilePaddingSmall),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: kMobileCardShadowSmall,
                        ),
                        child: Icon(
                          _icon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: kMobileSizedBoxMedium),
                      Text(
                        _title,
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: kMobileSizedBoxSmall),
                      Text(
                        _subtitle,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Document viewer
                Expanded(
                  child: LegalDocumentViewer(
                    documentType: widget.documentType,
                    requireScrollToBottom: widget.requireAcceptance,
                    onScrolledToBottom: (scrolled) {
                      if (mounted) {
                        setState(() => _scrolledToBottom = scrolled);
                      }
                    },
                  ),
                ),
                
                // Acceptance checkbox (if required)
                if (widget.requireAcceptance) ...[
                  SizedBox(height: kMobileSizedBoxLarge),
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: kMobilePaddingSmall,
                      vertical: 2,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: kMobilePaddingSmall,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _scrolledToBottom
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                      border: Border.all(
                        color: _scrolledToBottom
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.textTertiary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: _scrolledToBottom
                                ? () => setState(() => _checked = !_checked)
                                : null,
                            child: Icon(
                              _checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _scrolledToBottom
                                  ? (_checked
                                      ? AppColors.primary
                                      : AppColors.textSecondary)
                                  : AppColors.textTertiary,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: kMobileSizedBoxMedium - 2),
                        Expanded(
                          child: Text(
                            'I agree to the ${widget.documentType.displayName}',
                            style: kMobileTextStyleSubtitle.copyWith(
                              fontSize: 13,
                              color: _scrolledToBottom
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action buttons
                Container(
                  padding: EdgeInsets.all(kMobilePaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                kMobileBorderRadiusSmall,
                              ),
                            ),
                            side: BorderSide(color: AppColors.textTertiary),
                          ),
                          child: Text(
                            widget.requireAcceptance ? 'Cancel' : 'Close',
                            style: kMobileTextStyleSubtitle.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (widget.requireAcceptance) ...[
                        SizedBox(width: kMobileSizedBoxMedium),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (_scrolledToBottom && _checked)
                                ? () => Navigator.pop(context, true)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  kMobileBorderRadiusSmall,
                                ),
                              ),
                            ),
                            child: Text(
                              'Accept',
                              style: kMobileTextStyleSubtitle.copyWith(
                                fontSize: 11,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
