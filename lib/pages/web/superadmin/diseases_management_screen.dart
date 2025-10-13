import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/services/super_admin/skin_diseases_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/shared/pagination_widget.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_card.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/add_edit_disease_modal.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_detail_modal.dart';

class DiseasesManagementScreen extends StatefulWidget {
  const DiseasesManagementScreen({super.key});

  @override
  State<DiseasesManagementScreen> createState() =>
      _DiseasesManagementScreenState();
}

class _DiseasesManagementScreenState extends State<DiseasesManagementScreen> {
  bool _isLoading = true;
  bool _isLoadingStats = true;
  List<SkinDiseaseModel> _filteredDiseases = [];
  Map<String, int> _statistics = {};

  // Pagination states
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalDiseases = 0;
  int _totalPages = 0;

  // Filter states
  String _searchQuery = '';
  String? _detectionFilter;
  List<String> _speciesFilter = [];
  String? _severityFilter;
  List<String> _categoriesFilter = [];
  bool? _contagiousFilter;
  String _sortBy = 'name_asc';

  @override
  void initState() {
    super.initState();
    _loadStatistics(); // Load stats first
    _loadDiseases(); // Then load diseases
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await SkinDiseasesService.getDiseaseStatistics();

      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      print('Error loading statistics: $e');
    }
  }

  Future<void> _loadDiseases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SkinDiseasesService.getPaginatedDiseases(
        page: _currentPage,
        itemsPerPage: _itemsPerPage,
        detectionFilter: _detectionFilter,
        speciesFilter: _speciesFilter.isEmpty ? null : _speciesFilter,
        severityFilter: _severityFilter,
        categoriesFilter:
            _categoriesFilter.isEmpty ? null : _categoriesFilter,
        contagiousFilter: _contagiousFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
      );

      setState(() {
        _filteredDiseases = result['diseases'] as List<SkinDiseaseModel>;
        _totalDiseases = result['totalDiseases'] as int;
        _totalPages = result['totalPages'] as int;
        _currentPage = result['currentPage'] as int;
        _isLoading = false;
      });
      
      print('✅ Loaded ${_filteredDiseases.length} diseases on page $_currentPage of $_totalPages (total: $_totalDiseases)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading diseases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _loadDiseases();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadDiseases();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _detectionFilter = null;
      _speciesFilter = [];
      _severityFilter = null;
      _categoriesFilter = [];
      _contagiousFilter = null;
      _sortBy = 'name_asc';
    });
    _loadDiseases();
  }

  Future<void> _handleDelete(SkinDiseaseModel disease) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Disease'),
        content: Text(
          'Are you sure you want to delete "${disease.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SkinDiseasesService.deleteDisease(disease.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disease deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadStatistics();
        _loadDiseases();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting disease: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleExportCSV() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Preparing export...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      // Fetch ALL filtered diseases (not just current page)
      final result = await SkinDiseasesService.getPaginatedDiseases(
        page: 1,
        itemsPerPage: 999999, // Get all matching records
        detectionFilter: _detectionFilter,
        speciesFilter: _speciesFilter.isEmpty ? null : _speciesFilter,
        severityFilter: _severityFilter,
        categoriesFilter: _categoriesFilter.isEmpty ? null : _categoriesFilter,
        contagiousFilter: _contagiousFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
      );

      final allFilteredDiseases = result['diseases'] as List<SkinDiseaseModel>;

      if (allFilteredDiseases.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No diseases to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate CSV content
      final csvContent = _generateCSV(allFilteredDiseases);

      // Create blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'pawsense_diseases_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      html.document.body?.children.add(anchor);
      anchor.click();

      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${allFilteredDiseases.length} diseases to CSV'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${allFilteredDiseases.length} diseases to CSV');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error exporting CSV: $e');
    }
  }

  String _generateCSV(List<SkinDiseaseModel> diseases) {
    final buffer = StringBuffer();
    
    // CSV Headers
    buffer.writeln(
      'ID,Name,Description,Detection Method,Species,Severity,Categories,Contagious,'
      'Duration,Symptoms,Causes,Treatments,Image URL,View Count,Created At,Updated At'
    );

    // CSV Rows
    for (final disease in diseases) {
      buffer.writeln(
        '${_escapeCsv(disease.id)},'
        '${_escapeCsv(disease.name)},'
        '${_escapeCsv(disease.description)},'
        '${_escapeCsv(disease.detectionMethod)},'
        '${_escapeCsv(disease.species.join('; '))},'
        '${_escapeCsv(disease.severity)},'
        '${_escapeCsv(disease.categories.join('; '))},'
        '${disease.isContagious ? 'Yes' : 'No'},'
        '${_escapeCsv(disease.duration)},'
        '${_escapeCsv(disease.symptoms.join('; '))},'
        '${_escapeCsv(disease.causes.join('; '))},'
        '${_escapeCsv(disease.treatments.join('; '))},'
        '${_escapeCsv(disease.imageUrl)},'
        '${disease.viewCount},'
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(disease.createdAt)},'
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(disease.updatedAt)}'
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    // Escape double quotes and wrap in quotes if contains comma, newline, or quotes
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _handleViewDetails(SkinDiseaseModel disease) {
    // Increment view count
    SkinDiseasesService.incrementViewCount(disease.id);
    
    // Show detail modal
    showDialog(
      context: context,
      builder: (context) => DiseaseDetailModal(disease: disease),
    );
  }

  void _handleEdit(SkinDiseaseModel disease) {
    showDialog(
      context: context,
      builder: (context) => AddEditDiseaseModal(
        disease: disease,
        onSuccess: () {
          _loadStatistics();
          _loadDiseases();
        },
      ),
    );
  }

  void _handleAdd() {
    showDialog(
      context: context,
      builder: (context) => AddEditDiseaseModal(
        onSuccess: () {
          _loadStatistics();
          _loadDiseases();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Skin Diseases Management',
                      subtitle:
                          'Manage AI-detectable skin diseases and informational resources',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handleAdd,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Disease'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Statistics Cards
              DiseaseStatisticsCards(
                statistics: _statistics,
                isLoading: _isLoadingStats,
              ),

              const SizedBox(height: 24),

              // Search and Filters
              DiseaseSearchAndFilter(
                searchQuery: _searchQuery,
                detectionFilter: _detectionFilter,
                speciesFilter: _speciesFilter,
                severityFilter: _severityFilter,
                categoriesFilter: _categoriesFilter,
                contagiousFilter: _contagiousFilter,
                sortBy: _sortBy,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
                onDetectionChanged: (value) {
                  setState(() {
                    _detectionFilter = value;
                  });
                  _applyFilters();
                },
                onSpeciesChanged: (value) {
                  setState(() {
                    _speciesFilter = value;
                  });
                  _applyFilters();
                },
                onSeverityChanged: (value) {
                  setState(() {
                    _severityFilter = value;
                  });
                  _applyFilters();
                },
                onCategoriesChanged: (value) {
                  setState(() {
                    _categoriesFilter = value;
                  });
                  _applyFilters();
                },
                onContagiousChanged: (value) {
                  setState(() {
                    _contagiousFilter = value;
                  });
                  _applyFilters();
                },
                onSortChanged: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                  _applyFilters();
                },
                onClearFilters: _clearFilters,
                onExportCSV: _handleExportCSV,
              ),

              const SizedBox(height: 24),

              // Diseases Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Table Header
                    _buildTableHeader(),

                    const Divider(height: 1),

                    // Table Content
                    if (_isLoading)
                      _buildLoadingState()
                    else if (_filteredDiseases.isEmpty)
                      _buildEmptyState()
                    else
                      _buildDiseasesList(),
                  ],
                ),
              ),

              // Pagination
              if (!_isLoading && _totalDiseases > 0) ...[
                const SizedBox(height: 24),
                PaginationWidget(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  totalItems: _totalDiseases,
                  onPageChanged: _onPageChanged,
                  isLoading: _isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Disease Name - Flex 3
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildHeaderText('DISEASE NAME'),
            ),
          ),

          // Detection - Fixed 100px
          SizedBox(
            width: 100,
            child: _buildHeaderText('DETECTION'),
          ),
          const SizedBox(width: 16),

          // Species - Fixed 120px
          SizedBox(
            width: 120,
            child: _buildHeaderText('SPECIES'),
          ),
          const SizedBox(width: 16),

          // Severity - Fixed 100px
          SizedBox(
            width: 100,
            child: Center(child: _buildHeaderText('SEVERITY')),
          ),
          const SizedBox(width: 16),

          // Categories - Fixed 120px
          SizedBox(
            width: 120,
            child: _buildHeaderText('CATEGORIES'),
          ),
          const SizedBox(width: 16),

          // Contagious - Fixed 100px
          SizedBox(
            width: 100,
            child: Center(child: _buildHeaderText('CONTAGIOUS')),
          ),
          const SizedBox(width: 16),

          // Actions - Fixed 80px
          SizedBox(
            width: 80,
            child: _buildHeaderText('ACTIONS', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, {TextAlign textAlign = TextAlign.left}) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDiseasesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredDiseases.length,
      itemBuilder: (context, index) {
        final disease = _filteredDiseases[index];
        return DiseaseCard(
          disease: disease,
          onTap: () => _handleViewDetails(disease),
          onEdit: () => _handleEdit(disease),
          onDelete: () => _handleDelete(disease),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(80.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(80.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No diseases found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ||
                      _detectionFilter != null ||
                      _speciesFilter.isNotEmpty ||
                      _severityFilter != null ||
                      _categoriesFilter.isNotEmpty ||
                      _contagiousFilter != null
                  ? 'Try adjusting your filters'
                  : 'No diseases have been added yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
