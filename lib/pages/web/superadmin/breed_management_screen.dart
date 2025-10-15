import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';
import 'package:pawsense/core/services/super_admin/pet_breeds_service.dart';
import 'package:pawsense/core/services/super_admin/breed_cache_service.dart';
import 'package:pawsense/core/services/super_admin/screen_state_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/shared/pagination_widget.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_card.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/add_edit_breed_modal.dart';

class BreedManagementScreen extends StatefulWidget {
  const BreedManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('breed_management'));

  @override
  State<BreedManagementScreen> createState() => _BreedManagementScreenState();
}

class _BreedManagementScreenState extends State<BreedManagementScreen> with AutomaticKeepAliveClientMixin {
  List<PetBreed> _filteredBreeds = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool _isPaginationLoading = false; // Separate loading state for pagination
  bool _isLoadingStats = true;
  
  // Pagination - fixed at 10 items per page
  int _currentPage = 1;
  int _totalBreeds = 0;
  int _totalPages = 0;
  final int _itemsPerPage = 10;
  
  // Filters
  String _searchQuery = '';
  BreedSpecies _selectedSpecies = BreedSpecies.all;
  BreedStatus _selectedStatus = BreedStatus.all;
  BreedSortOption _selectedSort = BreedSortOption.nameAsc;
  
  // Services
  final _cacheService = BreedCacheService();
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
    _loadBreeds();
  }
  
  @override
  void dispose() {
    _saveState();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    _currentPage = _stateService.breedCurrentPage;
    _searchQuery = _stateService.breedSearchQuery;
    
    // Convert string back to enum
    switch (_stateService.breedSelectedSpecies) {
      case 'all':
        _selectedSpecies = BreedSpecies.all;
        break;
      case 'cat':
        _selectedSpecies = BreedSpecies.cat;
        break;
      case 'dog':
        _selectedSpecies = BreedSpecies.dog;
        break;
      default:
        _selectedSpecies = BreedSpecies.all;
    }
    
    switch (_stateService.breedSelectedStatus) {
      case 'all':
        _selectedStatus = BreedStatus.all;
        break;
      case 'active':
        _selectedStatus = BreedStatus.active;
        break;
      case 'inactive':
        _selectedStatus = BreedStatus.inactive;
        break;
      default:
        _selectedStatus = BreedStatus.all;
    }
    
    switch (_stateService.breedSelectedSort) {
      case 'name_asc':
        _selectedSort = BreedSortOption.nameAsc;
        break;
      case 'name_desc':
        _selectedSort = BreedSortOption.nameDesc;
        break;
      case 'species':
        _selectedSort = BreedSortOption.species;
        break;
      case 'date_added':
        _selectedSort = BreedSortOption.dateAdded;
        break;
      default:
        _selectedSort = BreedSortOption.nameAsc;
    }
    
    print('🔄 Restored breed management state: page=$_currentPage, species="${_selectedSpecies.value}", status="${_selectedStatus.value}", sort="${_selectedSort.value}", search="$_searchQuery"');
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveBreedState(
      currentPage: _currentPage,
      searchQuery: _searchQuery,
      selectedSpecies: _selectedSpecies.value,
      selectedStatus: _selectedStatus.value,
      selectedSort: _selectedSort.value,
    );
  }
  
  Future<void> _loadBreeds({bool forceRefresh = false, bool isPagination = false}) async {
    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(
      _selectedSpecies.value,
      _selectedStatus.value,
      _searchQuery,
      _selectedSort.value,
    );
    if (filtersChanged && !_isInitialLoad) {
      _cacheService.invalidateCacheForFilterChange();
    }
    
    // Try to load from multi-page cache first
    if (!forceRefresh && !_isInitialLoad) {
      final cachedPage = _cacheService.getCachedPage(
        speciesFilter: _selectedSpecies.value,
        statusFilter: _selectedStatus.value,
        searchQuery: _searchQuery,
        sortBy: _selectedSort.value,
        page: _currentPage,
      );
      
      if (cachedPage != null) {
        print('📦 Using cached page data - no network call needed');
        setState(() {
          _filteredBreeds = cachedPage.breeds;
          _totalBreeds = cachedPage.totalBreeds;
          _totalPages = cachedPage.totalPages;
          _isPaginationLoading = false;
        });
        
        // Load stats from cache if available
        final cachedStats = _cacheService.cachedStats;
        if (cachedStats != null) {
          setState(() {
            _statistics = cachedStats;
            _isLoadingStats = false;
          });
        }
        return;
      }
    }
    
    // Set appropriate loading state
    setState(() {
      if (_isInitialLoad) {
        _isLoading = true;
        _isLoadingStats = true;
      } else if (isPagination) {
        _isPaginationLoading = true;
      }
    });
    
    try {
      print('🔄 Loading breeds from Firestore...');
      print('Selected Species: "${_selectedSpecies.value}", Status: "${_selectedStatus.value}", Sort: "${_selectedSort.value}"');
      
      // Convert filter strings to API format
      String? speciesFilter;
      if (_selectedSpecies != BreedSpecies.all) {
        speciesFilter = _selectedSpecies.value;
      }
      
      String? statusFilter;
      if (_selectedStatus != BreedStatus.all) {
        statusFilter = _selectedStatus.value;
      }
      
      print('Filters - Species: $speciesFilter, Status: $statusFilter, Search: $_searchQuery, Sort: ${_selectedSort.value}');
      
      // Fetch statistics and paginated breeds in parallel for better performance
      final results = await Future.wait([
        PetBreedsService.getBreedStatistics(),
        PetBreedsService.getPaginatedBreeds(
          page: _currentPage,
          itemsPerPage: _itemsPerPage,
          speciesFilter: speciesFilter,
          statusFilter: statusFilter,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          sortBy: _selectedSort.value,
        ),
      ]);
      
      final stats = results[0] as Map<String, int>;
      final paginatedResult = results[1];
      
      final breeds = paginatedResult['breeds'] as List<PetBreed>;
      final totalBreeds = paginatedResult['totalBreeds'] as int;
      final totalPages = paginatedResult['totalPages'] as int;
      
      // Update cache with current page data
      _cacheService.updateCache(
        breeds: breeds,
        totalBreeds: totalBreeds,
        totalPages: totalPages,
        stats: stats,
        speciesFilter: _selectedSpecies.value,
        statusFilter: _selectedStatus.value,
        searchQuery: _searchQuery,
        sortBy: _selectedSort.value,
        page: _currentPage,
      );
      
      setState(() {
        _filteredBreeds = breeds;
        _totalBreeds = totalBreeds;
        _totalPages = totalPages;
        _statistics = stats;
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false;
        _isLoadingStats = false;
      });
      
      print('✅ Loaded ${breeds.length} breeds on page $_currentPage of $_totalPages (total: $totalBreeds)');
    } catch (e) {
      print('❌ Error loading breeds: $e');
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false;
        _isLoadingStats = false;
      });
      _showErrorSnackBar('Failed to load breeds: $e');
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when search changes
    
    // Debounce search to avoid excessive API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _loadBreeds(); // Reload with new search after debounce (will clear cache)
    });
  }
  
  void _onSpeciesChanged(BreedSpecies species) {
    setState(() {
      _selectedSpecies = species;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when filter changes
    _loadBreeds(); // Reload with new filter immediately (will clear cache)
  }
  
  void _onStatusChanged(BreedStatus status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when filter changes
    _loadBreeds(); // Reload with new filter immediately (will clear cache)
  }
  
  void _onSortChanged(BreedSortOption sort) {
    setState(() {
      _selectedSort = sort;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when sort changes
    _loadBreeds(); // Reload with new sort immediately (will clear cache)
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _saveState(); // Save state when page changes
    _loadBreeds(isPagination: true); // Load new page data from server with pagination flag
  }
  
  void _showAddBreedModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBreedModal(
        onSave: (breed) async {
          try {
            await PetBreedsService.createBreed(breed);
            Navigator.of(context).pop();
            _showSuccessSnackBar('Breed created successfully!');
            
            // Invalidate cache and reload to get fresh data
            _cacheService.invalidateCache();
            _loadBreeds(forceRefresh: true);
          } catch (e) {
            _showErrorSnackBar(e.toString());
          }
        },
      ),
    );
  }
  
  void _showEditBreedModal(PetBreed breed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBreedModal(
        breed: breed,
        onSave: (updatedBreed) async {
          try {
            await PetBreedsService.updateBreed(breed.id, updatedBreed);
            Navigator.of(context).pop();
            _showSuccessSnackBar('Breed updated successfully!');
            
            // Update the local breed item
            final updatedBreedWithId = updatedBreed.copyWith(id: breed.id);
            setState(() {
              final idx = _filteredBreeds.indexWhere((b) => b.id == breed.id);
              if (idx != -1) {
                _filteredBreeds[idx] = updatedBreedWithId;
              }
            });
            
            // Update cache without full reload
            _cacheService.updateBreedInCache(updatedBreedWithId);
          } catch (e) {
            _showErrorSnackBar(e.toString());
          }
        },
      ),
    );
  }
  
  void _showDeleteDialog(PetBreed breed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${breed.name}?'),
        content: Text('This will permanently remove this breed. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PetBreedsService.deleteBreed(breed.id);
                _showSuccessSnackBar('Breed deleted successfully!');
                
                // Remove breed from local list and cache
                setState(() {
                  _filteredBreeds.removeWhere((b) => b.id == breed.id);
                  _totalBreeds = _totalBreeds > 0 ? _totalBreeds - 1 : 0;
                });
                
                _cacheService.removeBreedFromCache(breed.id);
                
                // If current page is now empty and not the first page, go back one page
                if (_filteredBreeds.isEmpty && _currentPage > 1) {
                  _currentPage--;
                  _saveState();
                  _loadBreeds();
                }
              } catch (e) {
                _showErrorSnackBar('Failed to delete breed: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _toggleBreedStatus(PetBreed breed, bool isActive) async {
    try {
      await PetBreedsService.toggleBreedStatus(breed.id, isActive);
      _showSuccessSnackBar('Breed status updated!');
      
      // Update the local breed item
      final updatedBreed = breed.copyWith(
        status: isActive ? 'active' : 'inactive',
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        final idx = _filteredBreeds.indexWhere((b) => b.id == breed.id);
        if (idx != -1) {
          _filteredBreeds[idx] = updatedBreed;
        }
      });
      
      // Update cache without full reload
      _cacheService.updateBreedInCache(updatedBreed);
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
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
      // Fetch ALL filtered breeds (not just current page)
      final result = await PetBreedsService.getPaginatedBreeds(
        page: 1,
        itemsPerPage: 999999, // Get all matching records
        speciesFilter: _selectedSpecies == BreedSpecies.all ? null : _selectedSpecies.value,
        statusFilter: _selectedStatus == BreedStatus.all ? null : _selectedStatus.value,
        searchQuery: _searchQuery,
        sortBy: _selectedSort.value,
      );

      final allFilteredBreeds = result['breeds'] as List<PetBreed>;

      if (allFilteredBreeds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No breeds to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate CSV content
      final csvContent = _generateCSV(allFilteredBreeds);

      // Create blob and download using platform-agnostic downloader
      final bytes = utf8.encode(csvContent);
      final fileName = 'pawsense_breeds_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      file_downloader.downloadFile(fileName, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${allFilteredBreeds.length} breeds to CSV'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${allFilteredBreeds.length} breeds to CSV');
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

  String _generateCSV(List<PetBreed> breeds) {
    final buffer = StringBuffer();
    
    // CSV Headers
    buffer.writeln(
      'ID,Name,Species,Status,Created By,Created At,Updated At'
    );

    // CSV Rows
    for (final breed in breeds) {
      buffer.writeln(
        '${_escapeCsv(breed.id)},'
        '${_escapeCsv(breed.name)},'
        '${_escapeCsv(breed.species)},'
        '${_escapeCsv(breed.status)},'
        '${_escapeCsv(breed.createdBy)},'
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(breed.createdAt)},'
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(breed.updatedAt)}'
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
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: kSpacingMedium),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: kSpacingMedium),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              title: 'Pet Breeds Management',
              subtitle: 'Manage cat and dog breeds in the system',
              actions: [
                ElevatedButton.icon(
                  onPressed: _showAddBreedModal,
                  icon: Icon(Icons.add, size: kIconSizeMedium),
                  label: Text('Add New Breed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge,
                      vertical: kSpacingMedium,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Statistics Cards
            BreedStatisticsCards(
              statistics: _statistics,
              isLoading: _isLoadingStats,
            ),
            SizedBox(height: kSpacingLarge),
            
            // Search and Filters
            BreedSearchAndFilter(
              searchQuery: _searchQuery,
              onSearchChanged: _onSearchChanged,
              selectedSpecies: _selectedSpecies,
              onSpeciesChanged: _onSpeciesChanged,
              selectedStatus: _selectedStatus,
              onStatusChanged: _onStatusChanged,
              selectedSort: _selectedSort,
              onSortChanged: _onSortChanged,
              onExportCSV: _handleExportCSV,
            ),
            SizedBox(height: kSpacingLarge),
            
            // Breeds List with pagination loading overlay
            Stack(
              children: [
                _isLoading ? _buildLoadingState() : _buildBreedsList(),
                
                // Show loading overlay during pagination
                if (_isPaginationLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading page $_currentPage...',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
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
            
            if (!_isLoading && _filteredBreeds.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination with loading state
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalBreeds,
                onPageChanged: _onPageChanged,
                isLoading: _isPaginationLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildBreedsList() {
    if (_filteredBreeds.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildListView();
  }
  
  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
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
          Divider(height: 1, thickness: 1, color: AppColors.border),
          
          // Breed rows
          ..._filteredBreeds.map((breed) => BreedCard(
            breed: breed,
            onTap: () => _showEditBreedModal(breed),
            onEdit: () => _showEditBreedModal(breed),
            onDelete: () => _showDeleteDialog(breed),
            onStatusToggle: (isActive) => _toggleBreedStatus(breed, isActive),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingMedium,
        vertical: kSpacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadius)),
      ),
      child: Row(
        children: [
          // Breed Name column
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(right: kSpacingSmall),
              child: Text('BREED NAME', style: _headerStyle()),
            ),
          ),
          
          // Species column
          SizedBox(
            width: 100,
            child: Text('SPECIES', style: _headerStyle()),
          ),
          SizedBox(width: kSpacingLarge),
          
          // Status column
          SizedBox(
            width: 100,
            child: Center(child: Text('STATUS', style: _headerStyle())),
          ),
          SizedBox(width: kSpacingLarge),
          
          // Date column
          SizedBox(
            width: 100,
            child: Text('DATE ADDED', style: _headerStyle(), textAlign: TextAlign.center),
          ),
          SizedBox(width: kSpacingLarge),
          
          // Actions column
          SizedBox(
            width: 80,
            child: Text('ACTIONS', style: _headerStyle(), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
  
  TextStyle _headerStyle() {
    return kTextStyleSmall.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
  }
  

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(kSpacingXLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: AppColors.textSecondary),
          SizedBox(height: kSpacingLarge),
          Text(
            'No breeds found',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: kSpacingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first breed to get started',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: kSpacingLarge),
          ElevatedButton.icon(
            onPressed: _searchQuery.isNotEmpty || _selectedSpecies != BreedSpecies.all || _selectedStatus != BreedStatus.all
                ? () {
                    setState(() {
                      _searchQuery = '';
                      _selectedSpecies = BreedSpecies.all;
                      _selectedStatus = BreedStatus.all;
                    });
                    _loadBreeds();
                  }
                : _showAddBreedModal,
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
            label: Text(_searchQuery.isNotEmpty ? 'Clear Filters' : 'Add First Breed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(kSpacingXLarge * 2),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: kSpacingMedium),
            Text(
              'Loading breeds...',
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
