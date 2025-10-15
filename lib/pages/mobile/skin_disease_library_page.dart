import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/user/skin_disease_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/skin_disease/disease_info_banner.dart';
import 'package:pawsense/core/widgets/user/skin_disease/disease_search_bar.dart';
import 'package:pawsense/core/widgets/user/skin_disease/species_toggle.dart';
import 'package:pawsense/core/widgets/user/skin_disease/disease_filters.dart';
import 'package:pawsense/core/widgets/user/skin_disease/disease_card.dart';
import 'package:pawsense/core/widgets/user/skin_disease/disease_empty_state.dart';
import 'package:pawsense/core/widgets/shared/ui/scroll_to_top_fab.dart';
import 'package:pawsense/pages/mobile/skin_disease_detail_page.dart';

/// Skin Disease Information Library Page (Mobile/User)
/// 
/// Displays a searchable, filterable list of skin diseases
/// Component-based architecture for clean and maintainable code
class SkinDiseaseLibraryPage extends StatefulWidget {
  const SkinDiseaseLibraryPage({super.key});

  @override
  State<SkinDiseaseLibraryPage> createState() => _SkinDiseaseLibraryPageState();
}

class _SkinDiseaseLibraryPageState extends State<SkinDiseaseLibraryPage> {
  final SkinDiseaseService _service = SkinDiseaseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SkinDiseaseModel> _allDiseases = [];
  List<SkinDiseaseModel> _filteredDiseases = [];
  List<String> _categories = [];
  
  UserModel? _userModel;
  bool _userLoading = true;
  bool _isLoading = true;
  String _selectedSpecies = 'cat'; // 'cat', 'dog'
  String? _selectedCategory; // null means "All"
  String? _selectedDetectionMethod; // null, 'ai', 'vet_guided'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== DATA LOADING ====================

  Future<void> _fetchUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (mounted) {
        setState(() {
          _userModel = user;
          _userLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _service.getAllDiseases(useCache: false),
        _service.getCategories(useCache: false),
      ]);
      
      setState(() {
        _allDiseases = results[0] as List<SkinDiseaseModel>;
        _categories = results[1] as List<String>;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load skin diseases: $e')),
        );
      }
    }
  }

  // ==================== FILTERING LOGIC ====================

  void _applyFilters() {
    setState(() {
      _filteredDiseases = _allDiseases.where((disease) {
        // Species filter - case-insensitive check for both singular and plural forms
        final speciesLower = disease.species.map((s) => s.toLowerCase()).toList();
        bool matchesSpecies = speciesLower.contains(_selectedSpecies.toLowerCase()) ||
            speciesLower.contains('${_selectedSpecies}s'.toLowerCase()) || // plural: cat -> cats
            speciesLower.contains('both');
        
        // Category filter (null means show all)
        bool matchesCategory = _selectedCategory == null ||
            disease.categories.contains(_selectedCategory);
        
        // Detection method filter
        bool matchesDetection = _selectedDetectionMethod == null ||
            disease.detectionMethod == _selectedDetectionMethod ||
            disease.detectionMethod == 'both';
        
        // Search query filter
        bool matchesSearch = _searchQuery.isEmpty ||
            disease.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            disease.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesSpecies && matchesCategory && matchesDetection && matchesSearch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecies = 'cat';
      _selectedCategory = null; // null = "All"
      _selectedDetectionMethod = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  // ==================== EVENT HANDLERS ====================

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onSpeciesChanged(String species) {
    setState(() {
      _selectedSpecies = species;
    });
    _applyFilters();
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (category == 'All') {
        _selectedCategory = null; // null = show all categories
      } else {
        // Toggle: if same category clicked, deselect (show all)
        _selectedCategory = _selectedCategory == category ? null : category;
      }
    });
    _applyFilters();
  }

  void _onDetectionMethodToggled() {
    setState(() {
      if (_selectedDetectionMethod == null) {
        _selectedDetectionMethod = 'ai';
      } else {
        _selectedDetectionMethod = null;
      }
    });
    _applyFilters();
  }

  void _navigateToDetail(SkinDiseaseModel disease) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkinDiseaseDetailPage(disease: disease),
      ),
    );
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    // Check if we came from services grid
    final uri = GoRouterState.of(context).uri;
    final source = uri.queryParameters['source'];
    final fromServices = source == 'services';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: fromServices 
        ? AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Skin Disease Info',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : UserAppBar(user: _userModel),
      floatingActionButton: _isLoading || _userLoading 
          ? null
          : ScrollToTopFab(
              scrollController: _scrollController,
              showThreshold: 200.0,
              tooltip: 'Scroll to top',
            ),
      body: _isLoading || _userLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Info banner component
                  const SliverToBoxAdapter(
                    child: DiseaseInfoBanner(),
                  ),
                  
                  // Search bar component
                  SliverToBoxAdapter(
                    child: DiseaseSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      hasQuery: _searchQuery.isNotEmpty,
                    ),
                  ),
                  
                  // Species toggle component (Cats/Dogs)
                  SliverToBoxAdapter(
                    child: SpeciesToggle(
                      selectedSpecies: _selectedSpecies,
                      onSpeciesChanged: _onSpeciesChanged,
                    ),
                  ),
                  
                  // Filter chips component (Categories + AI Detectable) - STICKY
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      child: Container(
                        color: AppColors.background,
                        child: DiseaseFilters(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          selectedDetectionMethod: _selectedDetectionMethod,
                          onCategorySelected: _onCategorySelected,
                          onDetectionMethodToggled: _onDetectionMethodToggled,
                        ),
                      ),
                    ),
                  ),
                  
                  // Disease list or empty state
                  _filteredDiseases.isEmpty
                      ? SliverFillRemaining(
                          child: DiseaseEmptyState(
                            message: _searchQuery.isNotEmpty
                                ? 'No results found'
                                : 'No diseases match your filters',
                            submessage: 'Try adjusting your filters',
                            onReset: _clearFilters,
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(kMobileMarginHorizontal),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return DiseaseCard(
                                  disease: _filteredDiseases[index],
                                  onTap: () => _navigateToDetail(_filteredDiseases[index]),
                                );
                              },
                              childCount: _filteredDiseases.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

/// Sticky header delegate for categories section
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 165; // Minimum height when sticky (increased to prevent overflow)

  @override
  double get maxExtent => 165; // Maximum height

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return true; // Always rebuild to reflect state changes
  }
}
