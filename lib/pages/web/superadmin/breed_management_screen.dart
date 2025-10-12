import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';
import 'package:pawsense/core/services/super_admin/pet_breeds_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_statistics_cards.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_search_and_filter.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/breed_card.dart';
import 'package:pawsense/core/widgets/super_admin/breed_management/add_edit_breed_modal.dart';

class BreedManagementScreen extends StatefulWidget {
  const BreedManagementScreen({super.key});

  @override
  State<BreedManagementScreen> createState() => _BreedManagementScreenState();
}

class _BreedManagementScreenState extends State<BreedManagementScreen> {
  List<PetBreed> _filteredBreeds = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  bool _isLoadingStats = true;
  
  // Filters
  String _searchQuery = '';
  BreedSpecies _selectedSpecies = BreedSpecies.all;
  BreedStatus _selectedStatus = BreedStatus.all;
  BreedSortOption _selectedSort = BreedSortOption.nameAsc;
  
  // Debouncing
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _loadBreeds();
    _loadStatistics();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);
    
    try {
      final breeds = await PetBreedsService.fetchAllBreeds(
        speciesFilter: _selectedSpecies == BreedSpecies.all ? null : _selectedSpecies.value,
        statusFilter: _selectedStatus == BreedStatus.all ? null : _selectedStatus.value,
        searchQuery: _searchQuery,
        sortBy: _selectedSort.value,
      );
      
      setState(() {
        _filteredBreeds = breeds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading breeds: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load breeds: $e');
    }
  }
  
  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    
    try {
      final stats = await PetBreedsService.getBreedStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoadingStats = false);
    }
  }
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadBreeds();
    });
  }
  
  void _onSpeciesChanged(BreedSpecies species) {
    setState(() => _selectedSpecies = species);
    _loadBreeds();
  }
  
  void _onStatusChanged(BreedStatus status) {
    setState(() => _selectedStatus = status);
    _loadBreeds();
  }
  
  void _onSortChanged(BreedSortOption sort) {
    setState(() => _selectedSort = sort);
    _loadBreeds();
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
            _loadBreeds();
            _loadStatistics();
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
            _loadBreeds();
            _loadStatistics();
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
                _loadBreeds();
                _loadStatistics();
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
      _loadBreeds();
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kSpacingLarge),
              child: Column(
                children: [
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
                  ),
                  SizedBox(height: kSpacingLarge),
                  
                  // Breeds List/Grid
                  _isLoading ? _buildLoadingState() : _buildBreedsList(),
                ],
              ),
            ),
          ),
        ],
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
