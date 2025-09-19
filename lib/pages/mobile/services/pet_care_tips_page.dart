import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/services/pet_care_tip_model.dart';
import 'package:pawsense/core/services/mobile/services/pet_care_tip_service.dart';

class PetCareTipsPage extends StatefulWidget {
  const PetCareTipsPage({super.key});

  @override
  State<PetCareTipsPage> createState() => _PetCareTipsPageState();
}

class _PetCareTipsPageState extends State<PetCareTipsPage> {
  List<PetCareTipModel> _tips = [];
  List<String> _categories = [];
  List<String> _petTypes = ['All', 'Dog', 'Cat', 'Bird', 'Rabbit', 'Fish'];
  List<String> _ageGroups = ['All', 'Puppy/Kitten', 'Adult', 'Senior'];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _selectedPetType = 'All';
  String _selectedAgeGroup = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final tips = await PetCareTipService.getActiveTips();
      final categories = await PetCareTipService.getCategories();
      
      setState(() {
        _tips = tips;
        _categories = ['All', ...categories];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tips: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<PetCareTipModel> get _filteredTips {
    var filtered = _tips;
    
    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((tip) => tip.category == _selectedCategory).toList();
    }
    
    // Filter by pet type
    if (_selectedPetType != 'All') {
      filtered = filtered.where((tip) => tip.petType == _selectedPetType || tip.petType == 'All').toList();
    }
    
    // Filter by age group
    if (_selectedAgeGroup != 'All') {
      filtered = filtered.where((tip) => tip.ageGroup == _selectedAgeGroup || tip.ageGroup == 'All').toList();
    }
    
    // Filter by search
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((tip) =>
          tip.title.toLowerCase().contains(searchTerm) ||
          tip.content.toLowerCase().contains(searchTerm) ||
          tip.tags.any((tag) => tag.toLowerCase().contains(searchTerm))
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Pet Care Tips',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _loading ? _buildLoadingState() : _buildTipsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: kMobileMarginCard,
      color: AppColors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search pet care tips...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Filter dropdowns
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() => _selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  'Pet Type',
                  _selectedPetType,
                  _petTypes,
                  (value) => setState(() => _selectedPetType = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Age Group',
                  _selectedAgeGroup,
                  _ageGroups,
                  (value) => setState(() => _selectedAgeGroup = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container()), // Empty space for balance
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kMobileTextStyleSubtitle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildTipsList() {
    final filteredTips = _filteredTips;
    
    if (filteredTips.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: kMobileMarginCard,
      itemCount: filteredTips.length,
      separatorBuilder: (context, index) => const SizedBox(height: kMobileSizedBoxMedium),
      itemBuilder: (context, index) {
        return _buildTipCard(filteredTips[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'No tips found',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            'Try adjusting your search or filters',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(PetCareTipModel tip) {
    return InkWell(
      onTap: () => _viewTipDetails(tip),
      child: Container(
        padding: kMobilePaddingCard,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: kMobileBorderRadiusCardPreset,
          boxShadow: kMobileCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCategoryChip(tip.category),
                const Spacer(),
                _buildEngagementIndicators(tip),
              ],
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            
            Text(
              tip.title,
              style: kMobileTextStyleTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            
            Text(
              tip.content,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Pet types and age groups
            Row(
              children: [
                _buildInfoChip(
                  tip.petType,
                  Icons.pets,
                  AppColors.info,
                ),
                const SizedBox(width: 6),
                _buildInfoChip(
                  tip.ageGroup,
                  Icons.schedule,
                  AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tip.likes}',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tip.views}',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Read More',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: kMobileTextStyleSubtitle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementIndicators(PetCareTipModel tip) {
    final isPopular = tip.likes > 50 || tip.views > 200;
    final isNew = DateTime.now().difference(tip.createdAt).inDays < 7;
    
    return Row(
      children: [
        if (isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NEW',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        if (isNew && isPopular) const SizedBox(width: 4),
        if (isPopular)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 8, color: AppColors.white),
                const SizedBox(width: 2),
                Text(
                  'HOT',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _viewTipDetails(PetCareTipModel tip) {
    // TODO: Navigate to detailed tip view
    context.push('/pet-care-tips/${tip.id}', extra: tip);
  }
}