import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/services/super_admin/skin_diseases_service.dart';
import 'package:pawsense/core/services/super_admin/disease_cache_service.dart';
import 'package:pawsense/core/services/super_admin/screen_state_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/shared/pagination_widget.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_card.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/add_edit_disease_modal.dart';
import 'package:pawsense/core/widgets/super_admin/disease_management/disease_detail_modal.dart';
import '../../../core/services/super_admin/disease_pdf_service.dart';

class DiseasesManagementScreen extends StatefulWidget {
  const DiseasesManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('disease_management'));

  @override
  State<DiseasesManagementScreen> createState() =>
      _DiseasesManagementScreenState();
}

class _DiseasesManagementScreenState extends State<DiseasesManagementScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool _isPaginationLoading = false; // Separate loading state for pagination
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

  // Services
  final _cacheService = DiseaseCacheService();
  final _stateService = ScreenStateService();
  
  // Debouncing
  Timer? _debounceTimer;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    _restoreState();
    _loadDiseases();
  }

  @override
  void dispose() {
    _saveState();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    _currentPage = _stateService.diseaseCurrentPage;
    _searchQuery = _stateService.diseaseSearchQuery;
    _detectionFilter = _stateService.diseaseDetectionFilter;
    _speciesFilter = List.from(_stateService.diseaseSpeciesFilter);
    _severityFilter = _stateService.diseaseSeverityFilter;
    _categoriesFilter = List.from(_stateService.diseaseCategoriesFilter);
    _contagiousFilter = _stateService.diseaseContagiousFilter;
    _sortBy = _stateService.diseaseSortBy;
    
    print('🔄 Restored disease management state: page=$_currentPage, detection="$_detectionFilter", species=$_speciesFilter, severity="$_severityFilter", sort="$_sortBy", search="$_searchQuery"');
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveDiseaseState(
      currentPage: _currentPage,
      searchQuery: _searchQuery,
      detectionFilter: _detectionFilter,
      speciesFilter: _speciesFilter,
      severityFilter: _severityFilter,
      categoriesFilter: _categoriesFilter,
      contagiousFilter: _contagiousFilter,
      sortBy: _sortBy,
    );
  }

  Future<void> _loadDiseases({bool forceRefresh = false, bool isPagination = false}) async {
    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(
      _detectionFilter,
      _speciesFilter,
      _severityFilter,
      _categoriesFilter,
      _contagiousFilter,
      _searchQuery,
      _sortBy,
    );
    if (filtersChanged && !_isInitialLoad) {
      _cacheService.invalidateCacheForFilterChange();
    }
    
    // Try to load from multi-page cache first
    if (!forceRefresh && !_isInitialLoad) {
      final cachedPage = _cacheService.getCachedPage(
        detectionFilter: _detectionFilter,
        speciesFilter: _speciesFilter,
        severityFilter: _severityFilter,
        categoriesFilter: _categoriesFilter,
        contagiousFilter: _contagiousFilter,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        page: _currentPage,
      );
      
      if (cachedPage != null) {
        print('📦 Using cached page data - no network call needed');
        setState(() {
          _filteredDiseases = cachedPage.diseases;
          _totalDiseases = cachedPage.totalDiseases;
          _totalPages = cachedPage.totalPages;
          _isPaginationLoading = false;
        });
        
        // Load stats from cache if available
        final cachedStats = _cacheService.cachedStats;
        if (cachedStats != null) {
          setState(() {
            _statistics = cachedStats;
          });
        }
        return;
      }
    }
    
    // Set appropriate loading state
    setState(() {
      if (_isInitialLoad) {
        _isLoading = true;
      } else if (isPagination) {
        _isPaginationLoading = true;
      }
    });

    try {
      print('🔄 Loading diseases from Firestore...');
      print('Selected Detection: "$_detectionFilter", Species: $_speciesFilter, Severity: "$_severityFilter", Categories: $_categoriesFilter, Contagious: $_contagiousFilter, Sort: "$_sortBy"');
      
      // Fetch statistics and paginated diseases in parallel for better performance
      final results = await Future.wait([
        SkinDiseasesService.getDiseaseStatistics(),
        SkinDiseasesService.getPaginatedDiseases(
          page: _currentPage,
          itemsPerPage: _itemsPerPage,
          detectionFilter: _detectionFilter,
          speciesFilter: _speciesFilter.isEmpty ? null : _speciesFilter,
          severityFilter: _severityFilter,
          categoriesFilter: _categoriesFilter.isEmpty ? null : _categoriesFilter,
          contagiousFilter: _contagiousFilter,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          sortBy: _sortBy,
        ),
      ]);
      
      final stats = results[0] as Map<String, int>;
      final paginatedResult = results[1];

      final diseases = paginatedResult['diseases'] as List<SkinDiseaseModel>;
      final totalDiseases = paginatedResult['totalDiseases'] as int;
      final totalPages = paginatedResult['totalPages'] as int;
      final currentPage = paginatedResult['currentPage'] as int;
      
      // Update cache with current page data
      _cacheService.updateCache(
        diseases: diseases,
        totalDiseases: totalDiseases,
        totalPages: totalPages,
        stats: stats,
        detectionFilter: _detectionFilter,
        speciesFilter: _speciesFilter,
        severityFilter: _severityFilter,
        categoriesFilter: _categoriesFilter,
        contagiousFilter: _contagiousFilter,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        page: _currentPage,
      );

      setState(() {
        _filteredDiseases = diseases;
        _totalDiseases = totalDiseases;
        _totalPages = totalPages;
        _currentPage = currentPage;
        _statistics = stats;
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false;
      });
      
      print('✅ Loaded ${diseases.length} diseases on page $_currentPage of $_totalPages (total: $totalDiseases)');
    } catch (e) {
      print('❌ Error loading diseases: $e');
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false;
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

  /// Check if any filters are actively applied (non-default values)
  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _detectionFilter != null ||
        _speciesFilter.isNotEmpty ||
        _severityFilter != null ||
        _categoriesFilter.isNotEmpty ||
        _contagiousFilter != null;
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when filters change
    _loadDiseases(); // Reload with new filters (will clear cache)
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _saveState(); // Save state when page changes
    _loadDiseases(isPagination: true); // Load new page data from server with pagination flag
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
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when clearing filters
    _loadDiseases(); // Reload with cleared filters (will clear cache)
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
              Text('Generating PDF report...'),
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

      // Get current admin name
      String? adminName = 'Super Admin';

      // Generate PDF
      final Uint8List pdfBytes = await DiseasePdfService.generateDiseaseReport(
        diseases: allFilteredDiseases,
        detectionMethodFilter: _detectionFilter != null && _detectionFilter!.isNotEmpty ? _detectionFilter : null,
        speciesFilter: _speciesFilter.isNotEmpty ? _speciesFilter.join(', ') : null,
        severityFilter: _severityFilter != null && _severityFilter!.isNotEmpty ? _severityFilter : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        generatedBy: adminName,
      );

      // Download PDF
      final fileName = 'disease_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      file_downloader.downloadFile(fileName, pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF report generated with ${allFilteredDiseases.length} diseases'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${allFilteredDiseases.length} diseases to PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error generating PDF: $e');
    }
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
          // Invalidate cache and reload to get fresh data
          _cacheService.invalidateCache();
          _loadDiseases(forceRefresh: true);
        },
      ),
    );
  }

  void _handleAdd() {
    showDialog(
      context: context,
      builder: (context) => AddEditDiseaseModal(
        onSuccess: () {
          // Invalidate cache and reload to get fresh data
          _cacheService.invalidateCache();
          _loadDiseases(forceRefresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
                  
                  // Debounce search to avoid excessive API calls
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(_debounceDuration, () {
                    _applyFilters();
                  });
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

              // Diseases Table with pagination loading overlay
              Stack(
                children: [
                  _isLoading ? _buildLoadingState() : _buildDiseasesTable(),
                  
                  // Show loading overlay during pagination
                  if (_isPaginationLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading page $_currentPage...',
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Pagination
              if (!_isLoading && _totalDiseases > 0) ...[
                const SizedBox(height: 24),
                PaginationWidget(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  totalItems: _totalDiseases,
                  onPageChanged: _onPageChanged,
                  isLoading: _isPaginationLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseasesTable() {
    if (_filteredDiseases.isEmpty) {
      return _buildEmptyState();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          _buildTableHeader(),
          
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          // Disease rows
          _buildDiseasesList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
          const SizedBox(
            width: 100,
            child: Text(
              'DETECTION',
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Species - Fixed 120px
          const SizedBox(
            width: 120,
            child: Text(
              'SPECIES',
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Severity - Fixed 100px
          const SizedBox(
            width: 100,
            child: Center(
              child: Text(
                'SEVERITY',
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Categories - Fixed 120px
          const SizedBox(
            width: 120,
            child: Text(
              'CATEGORIES',
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Contagious - Fixed 100px
          const SizedBox(
            width: 100,
            child: Center(
              child: Text(
                'CONTAGIOUS',
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Actions - Fixed 60px
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'ACTIONS',
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, {TextAlign textAlign = TextAlign.left}) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
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
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading diseases...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No diseases found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters
                    ? 'Try adjusting your search or filters'
                    : 'Add your first disease to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
