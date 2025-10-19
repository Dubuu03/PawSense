import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/system/legal_document_model.dart';
import '../../../services/system/legal_document_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

/// Legal Documents Settings for Admin (Read-Only View)
/// 
/// Allows clinic admins to view active legal documents but not edit them.
/// Only Super Admins can create/edit legal documents.
class LegalDocumentsSettings extends StatefulWidget {
  const LegalDocumentsSettings({super.key});

  @override
  State<LegalDocumentsSettings> createState() => _LegalDocumentsSettingsState();
}

class _LegalDocumentsSettingsState extends State<LegalDocumentsSettings> {
  final LegalDocumentService _service = LegalDocumentService();
  bool _isLoading = true;
  List<LegalDocumentModel> _documents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _service.getAllDocuments();
      // Filter to show only active documents for admin view
      setState(() {
        _documents = docs.where((doc) => doc.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load documents: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleViewDocument(LegalDocumentModel document) async {
    await showDialog(
      context: context,
      builder: (context) => _LegalDocumentViewerDialog(document: document),
    );
  }

  List<LegalDocumentModel> get _filteredDocuments {
    if (_searchQuery.isEmpty) return _documents;
    
    return _documents.where((doc) {
      final query = _searchQuery.toLowerCase();
      return doc.title.toLowerCase().contains(query) ||
          doc.type.displayName.toLowerCase().contains(query) ||
          doc.version.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Documents',
                    style: kTextStyleTitle.copyWith(fontSize: 20),
                  ),
                  SizedBox(height: kSpacingSmall),
                  Text(
                    'View terms and conditions, privacy policies, and other legal documents',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: kSpacingMedium),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingLarge),

        // Info banner
        Container(
          padding: EdgeInsets.all(kSpacingMedium),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: kSpacingMedium),
              Expanded(
                child: Text(
                  'These legal documents are managed by the Super Admin. You can view the active versions that apply to your clinic.',
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.info,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: kSpacingLarge),

        // Documents list
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(kSpacingXLarge),
              child: const CircularProgressIndicator(),
            ),
          )
        else if (_filteredDocuments.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(kSpacingXLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: kSpacingMedium),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No legal documents available'
                        : 'No documents match your search',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredDocuments.length,
            itemBuilder: (context, index) {
              final doc = _filteredDocuments[index];
              return _DocumentCard(
                document: doc,
                onView: () => _handleViewDocument(doc),
              );
            },
          ),
      ],
    );
  }
}

/// Document card widget (Read-only for admin)
class _DocumentCard extends StatelessWidget {
  final LegalDocumentModel document;
  final VoidCallback onView;

  const _DocumentCard({
    required this.document,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: kShadowBlurRadius / 2,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(kSpacingMedium),
        child: Row(
          children: [
            // Status indicator (Active documents only)
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            SizedBox(width: kSpacingMedium),
            
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        document.title,
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: kSpacingSmall),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: kSpacingSmall),
                  Text(
                    '${document.type.displayName} • Version ${document.version}',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  Text(
                    'Last updated: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(document.lastUpdated)} by ${document.updatedBy}',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            // View button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View Document',
                  color: AppColors.primary,
                  padding: EdgeInsets.all(6),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Legal Document Viewer Dialog (Read-only)
class _LegalDocumentViewerDialog extends StatelessWidget {
  final LegalDocumentModel document;

  const _LegalDocumentViewerDialog({
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(kSpacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                  child: Icon(
                    Icons.description_outlined,
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
                        document.title,
                        style: kTextStyleTitle.copyWith(fontSize: 20),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        '${document.type.displayName} • Version ${document.version}',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            
            SizedBox(height: kSpacingMedium),
            
            // Metadata
            Container(
              padding: EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: kSpacingSmall),
                  Text(
                    'Last updated: ${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(document.lastUpdated)} by ${document.updatedBy}',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Content
            Expanded(
              child: Container(
                padding: EdgeInsets.all(kSpacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(kSpacingMedium),
                    child: SelectableText(
                      _parseHtmlToText(document.content),
                      style: kTextStyleRegular.copyWith(
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: kSpacingMedium),
            
            // Footer
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: kSpacingLarge,
                    vertical: kSpacingMedium,
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _parseHtmlToText(String html) {
    // Simple HTML to text parser
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p>'), '\n\n')
        .replaceAll(RegExp(r'</p>'), '')
        .replaceAll(RegExp(r'<li>'), '• ')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<h[1-6]>'), '\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
  }
}
