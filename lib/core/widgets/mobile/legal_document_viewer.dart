import 'package:flutter/material.dart';
import '../../models/system/legal_document_model.dart';
import '../../services/system/legal_document_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants_mobile.dart';

/// Mobile widget for viewing legal documents with scroll detection
class LegalDocumentViewer extends StatefulWidget {
  final DocumentType documentType;
  final bool requireScrollToBottom;
  final Function(bool)? onScrolledToBottom;

  const LegalDocumentViewer({
    super.key,
    required this.documentType,
    this.requireScrollToBottom = false,
    this.onScrolledToBottom,
  });

  @override
  State<LegalDocumentViewer> createState() => _LegalDocumentViewerState();
}

class _LegalDocumentViewerState extends State<LegalDocumentViewer> {
  final LegalDocumentService _service = LegalDocumentService();
  final ScrollController _scrollController = ScrollController();
  
  LegalDocumentModel? _document;
  bool _isLoading = true;
  String? _error;
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
    if (widget.requireScrollToBottom) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await _service.getActiveDocumentByType(widget.documentType);
      
      if (!mounted) return;
      
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to load document: $e';
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && 
        !_scrollController.position.outOfRange) {
      if (!_scrolledToBottom) {
        setState(() => _scrolledToBottom = true);
        widget.onScrolledToBottom?.call(true);
      }
    }
  }

  Widget _buildScrollProgress() {
    if (!widget.requireScrollToBottom) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        if (!_scrollController.hasClients) {
          return const SizedBox();
        }
        
        final progress = _scrollController.offset / 
            _scrollController.position.maxScrollExtent;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall, vertical: 2),
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'Loading document...',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: kMobileSizedBoxMedium),
            Text(
              _error!,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kMobileSizedBoxMedium),
            ElevatedButton.icon(
              onPressed: _loadDocument,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_document == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'No ${widget.documentType.displayName} available',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Show scroll indicator if required
        if (widget.requireScrollToBottom && !_scrolledToBottom) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kMobilePaddingSmall,
              vertical: kMobileSizedBoxSmall,
            ),
            color: AppColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.swipe,
                  color: AppColors.warning,
                  size: 14,
                ),
                SizedBox(width: kMobileSizedBoxSmall),
                Expanded(
                  child: Text(
                    'Please scroll to the bottom to accept terms',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildScrollProgress(),
        ],
        
        SizedBox(height: 12),
        
        // Document content
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              radius: Radius.circular(kMobileBorderRadiusButton),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(kMobilePaddingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document metadata
                    Container(
                      padding: EdgeInsets.all(kMobilePaddingSmall),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: kMobileSizedBoxSmall),
                              Expanded(
                                child: Text(
                                  'Version ${_document!.version}',
                                  style: kMobileTextStyleSubtitle.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: kMobileSizedBoxSmall),
                          Text(
                            'Last updated: ${_formatDate(_document!.lastUpdated)}',
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: kMobileSizedBoxMedium),
                    
                    // Document content (rendered as formatted text)
                    _buildFormattedContent(_document!.content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedContent(String content) {
    // Simple HTML-like formatting parser
    // Remove HTML tags and format text
    String plainText = content
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<li>'), '• ')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ''); // Remove remaining HTML tags
    
    // Parse sections for better formatting
    final lines = plainText.split('\n');
    final spans = <TextSpan>[];
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Check if it's a heading (ends with : or all caps)
      if (trimmed.endsWith(':') || (trimmed.length > 2 && trimmed == trimmed.toUpperCase() && !trimmed.startsWith('•'))) {
        spans.add(TextSpan(
          text: '$trimmed\n',
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$trimmed\n',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textPrimary,
            height: 1.4,
            fontSize: 12,
          ),
        ));
      }
      
      // Add spacing after paragraphs
      if (!trimmed.startsWith('•')) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
