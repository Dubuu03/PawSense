import 'package:flutter/material.dart';
import '../../models/system/legal_document_model.dart';
import '../../services/system/legal_document_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

/// Legal Document Acceptance Dialog for Web (Admin Signup)
///
/// Modal dialog that displays legal documents (Terms & Conditions, Privacy Policy)
/// from Firestore with scroll detection and acceptance requirement.
/// Follows the same pattern as mobile auth legal document modal.
class LegalDocumentAcceptanceDialog extends StatefulWidget {
  final DocumentType documentType;

  const LegalDocumentAcceptanceDialog({
    super.key,
    required this.documentType,
  });

  @override
  State<LegalDocumentAcceptanceDialog> createState() =>
      _LegalDocumentAcceptanceDialogState();
}

class _LegalDocumentAcceptanceDialogState
    extends State<LegalDocumentAcceptanceDialog> {
  final LegalDocumentService _service = LegalDocumentService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  LegalDocumentModel? _document;

  bool _scrolledToBottom = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      final document =
          await _service.getActiveDocumentByType(widget.documentType);

      if (mounted) {
        if (document != null) {
          setState(() {
            _document = document;
            _isLoading = false;
            _hasError = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Document not available at this time.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading document: ${e.toString()}';
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll - 50; // 50px from bottom

      if (currentScroll >= threshold && !_scrolledToBottom) {
        setState(() => _scrolledToBottom = true);
      }
    }
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
    return 'Please read and accept to continue with your registration';
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

  Widget _buildFormattedContent() {
    if (_document == null) return const SizedBox.shrink();

    final content = _document!.content;
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Headers (###, ##, #)
      if (trimmed.startsWith('###')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed.substring(3).trim(),
              style: kTextStyleRegular.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('##')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              trimmed.substring(2).trim(),
              style: kTextStyleRegular.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('#')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              trimmed.substring(1).trim(),
              style: kTextStyleTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        );
      }
      // Bold text (**text**)
      else if (trimmed.contains('**')) {
        final parts = trimmed.split('**');
        final spans = <TextSpan>[];
        for (int i = 0; i < parts.length; i++) {
          if (i % 2 == 1) {
            // Bold part
            spans.add(
              TextSpan(
                text: parts[i],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          } else {
            spans.add(TextSpan(text: parts[i]));
          }
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                style: kTextStyleRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                children: spans,
              ),
            ),
          ),
        );
      }
      // List items (-, *, or numbered)
      else if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: kTextStyleRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.primary,
                    height: 1.6,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmed.replaceFirst(RegExp(r'^[-*]\s|\d+\.\s'), ''),
                    style: kTextStyleRegular.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              trimmed,
              style: kTextStyleRegular.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _icon,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _title,
                    style: kTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Document content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _hasError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage ?? 'Error loading document',
                                  style: kTextStyleRegular.copyWith(
                                    color: AppColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: _buildFormattedContent(),
                          ),
              ),
            ),

            // Scroll indicator (if not scrolled to bottom)
            if (!_scrolledToBottom && !_isLoading && !_hasError)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please scroll down to read the entire document',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Acceptance checkbox and buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _checked,
                        onChanged: _scrolledToBottom
                            ? (value) {
                                setState(() => _checked = value ?? false);
                              }
                            : null,
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          'I have read and agree to the ${_title}',
                          style: kTextStyleRegular.copyWith(
                            fontSize: 14,
                            color: _scrolledToBottom
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: kTextStyleRegular.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _checked
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Agree & Continue',
                          style: kTextStyleRegular.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
