import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/system/legal_document_model.dart';
import '../../../services/system/legal_document_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'edit_legal_document_modal.dart';

/// Legal Documents tab for System Settings
class LegalDocumentsTab extends StatefulWidget {
  const LegalDocumentsTab({super.key});

  @override
  State<LegalDocumentsTab> createState() => _LegalDocumentsTabState();
}

class _LegalDocumentsTabState extends State<LegalDocumentsTab> {
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
      setState(() {
        _documents = docs;
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

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleCreateDocument() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const EditLegalDocumentModal(),
    );

    if (result == true) {
      _showSuccessSnackbar('✅ Document created successfully');
      _loadDocuments();
    }
  }

  Future<void> _handleEditDocument(LegalDocumentModel document) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditLegalDocumentModal(document: document),
    );

    if (result == true) {
      _showSuccessSnackbar('✅ Document updated successfully');
      _loadDocuments();
    }
  }

  Future<void> _handleToggleStatus(LegalDocumentModel document) async {
    try {
      // If activating, deactivate all others of same type
      if (!document.isActive) {
        await _service.deactivateAllOfType(document.type);
      }
      
      await _service.toggleDocumentStatus(document.id, !document.isActive);
      _showSuccessSnackbar(
        document.isActive
            ? '✅ Document deactivated'
            : '✅ Document activated',
      );
      _loadDocuments();
    } catch (e) {
      _showErrorSnackbar('Failed to update status: $e');
    }
  }

  Future<void> _handleViewHistory(LegalDocumentModel document) async {
    try {
      final history = await _service.getVersionHistory(document.id);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _VersionHistoryDialog(
          document: document,
          history: history,
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to load version history: $e');
    }
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
        // Header with search and create button
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
                    'Manage terms and conditions, privacy policies, and other legal documents',
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
            SizedBox(width: kSpacingMedium),
            ElevatedButton.icon(
              onPressed: _handleCreateDocument,
              icon: const Icon(Icons.add),
              label: const Text('Create Document'),
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
                        ? 'No legal documents found'
                        : 'No documents match your search',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    SizedBox(height: kSpacingMedium),
                    ElevatedButton.icon(
                      onPressed: _handleCreateDocument,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
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
                onEdit: () => _handleEditDocument(doc),
                onToggleStatus: () => _handleToggleStatus(doc),
                onViewHistory: () => _handleViewHistory(doc),
              );
            },
          ),
      ],
    );
  }
}

/// Document card widget
class _DocumentCard extends StatelessWidget {
  final LegalDocumentModel document;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewHistory;

  const _DocumentCard({
    required this.document,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onViewHistory,
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
            // Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: document.isActive ? AppColors.success : AppColors.textTertiary,
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
                          color: document.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          document.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: kTextStyleSmall.copyWith(
                            color: document.isActive
                                ? AppColors.success
                                : AppColors.textTertiary,
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
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onViewHistory,
                  icon: const Icon(Icons.history, size: 18),
                  tooltip: 'View History',
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.all(6),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                SizedBox(width: kSpacingSmall),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Document',
                  color: AppColors.primary,
                  padding: EdgeInsets.all(6),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                SizedBox(width: kSpacingSmall),
                IconButton(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    document.isActive ? Icons.toggle_on : Icons.toggle_off,
                    size: 20,
                  ),
                  tooltip: document.isActive ? 'Deactivate' : 'Activate',
                  color: document.isActive ? AppColors.success : AppColors.textTertiary,
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

/// Version history dialog
class _VersionHistoryDialog extends StatelessWidget {
  final LegalDocumentModel document;
  final List<DocumentVersionHistory> history;

  const _VersionHistoryDialog({
    required this.document,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version History: ${document.title}',
              style: kTextStyleTitle.copyWith(fontSize: 20),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              '${history.length} versions',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: kSpacingLarge),
            
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final version = history[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: kSpacingMedium),
                    child: Padding(
                      padding: EdgeInsets.all(kSpacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: kSpacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'v${version.version}',
                                  style: kTextStyleSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: kSpacingSmall),
                              Text(
                                DateFormat('MMM d, yyyy \'at\' h:mm a').format(version.timestamp),
                                style: kTextStyleSmall,
                              ),
                              Spacer(),
                              Text(
                                'by ${version.updatedBy}',
                                style: kTextStyleSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (version.changeNotes.isNotEmpty) ...[
                            SizedBox(height: kSpacingSmall),
                            Text(
                              version.changeNotes,
                              style: kTextStyleRegular,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: kSpacingMedium),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
