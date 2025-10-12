import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/services/super_admin/skin_diseases_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_card.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/add_edit_disease_modal.dart';

class DiseasesManagementScreen extends StatefulWidget {
  const DiseasesManagementScreen({super.key});

  @override
  State<DiseasesManagementScreen> createState() =>
      _DiseasesManagementScreenState();
}

class _DiseasesManagementScreenState extends State<DiseasesManagementScreen> {
  bool _isLoading = true;
  List<SkinDiseaseModel> _filteredDiseases = [];
  Map<String, int> _statistics = {};

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
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diseases = await SkinDiseasesService.fetchAllDiseases(
        detectionFilter: _detectionFilter,
        speciesFilter: _speciesFilter.isEmpty ? null : _speciesFilter,
        severityFilter: _severityFilter,
        categoriesFilter:
            _categoriesFilter.isEmpty ? null : _categoriesFilter,
        contagiousFilter: _contagiousFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
      );

      final stats = await SkinDiseasesService.getDiseaseStatistics();

      setState(() {
        _filteredDiseases = diseases;
        _statistics = stats;
        _isLoading = false;
      });
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

  Future<void> _handleDuplicate(SkinDiseaseModel disease) async {
    try {
      await SkinDiseasesService.duplicateDisease(disease.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disease duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadDiseases();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating disease: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _handleExportCSV() {
    // TODO: Implement CSV export in next phase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV export will be implemented in the next phase'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleViewDetails(SkinDiseaseModel disease) {
    // TODO: Implement detail view in next phase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detail view for "${disease.name}" - coming in next phase'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleEdit(SkinDiseaseModel disease) {
    showDialog(
      context: context,
      builder: (context) => AddEditDiseaseModal(
        disease: disease,
        onSuccess: _loadDiseases,
      ),
    );
  }

  void _handleAdd() {
    showDialog(
      context: context,
      builder: (context) => AddEditDiseaseModal(
        onSuccess: _loadDiseases,
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
                isLoading: _isLoading,
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
          // Image - Fixed 60px
          const SizedBox(width: 60),
          const SizedBox(width: 16),

          // Name - Flex 2
          Expanded(
            flex: 2,
            child: _buildHeaderText('Disease Name'),
          ),
          const SizedBox(width: 16),

          // Detection - Fixed 120px
          SizedBox(
            width: 120,
            child: _buildHeaderText('Detection'),
          ),
          const SizedBox(width: 16),

          // Species - Flex 1
          Expanded(
            flex: 1,
            child: _buildHeaderText('Species'),
          ),
          const SizedBox(width: 16),

          // Severity - Fixed 100px
          SizedBox(
            width: 100,
            child: _buildHeaderText('Severity'),
          ),
          const SizedBox(width: 16),

          // Categories - Flex 2
          Expanded(
            flex: 2,
            child: _buildHeaderText('Categories'),
          ),
          const SizedBox(width: 16),

          // Contagious - Fixed 80px
          SizedBox(
            width: 80,
            child: _buildHeaderText('Contagious'),
          ),
          const SizedBox(width: 16),

          // Actions - Fixed 48px
          const SizedBox(width: 48),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
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
          onDuplicate: () => _handleDuplicate(disease),
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
