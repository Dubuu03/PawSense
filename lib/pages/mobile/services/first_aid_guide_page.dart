import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/services/first_aid_guide_model.dart';
import 'package:pawsense/core/services/mobile/services/first_aid_guide_service.dart';

class FirstAidGuidePage extends StatefulWidget {
  const FirstAidGuidePage({super.key});

  @override
  State<FirstAidGuidePage> createState() => _FirstAidGuidePageState();
}

class _FirstAidGuidePageState extends State<FirstAidGuidePage> {
  List<FirstAidGuideModel> _guides = [];
  List<String> _categories = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _selectedUrgency = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _urgencyLevels = ['All', 'Low', 'Medium', 'High', 'Critical'];

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
      final guides = await FirstAidGuideService.getActiveGuides();
      final categories = await FirstAidGuideService.getCategories();
      
      setState(() {
        _guides = guides;
        _categories = ['All', ...categories];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading guides: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<FirstAidGuideModel> get _filteredGuides {
    var filtered = _guides;
    
    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((guide) => guide.category == _selectedCategory).toList();
    }
    
    // Filter by urgency
    if (_selectedUrgency != 'All') {
      filtered = filtered.where((guide) => guide.urgencyLevel == _selectedUrgency).toList();
    }
    
    // Filter by search
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((guide) =>
          guide.title.toLowerCase().contains(searchTerm) ||
          guide.description.toLowerCase().contains(searchTerm) ||
          guide.tags.any((tag) => tag.toLowerCase().contains(searchTerm))
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
          'First Aid Guide',
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
            child: _loading ? _buildLoadingState() : _buildGuidesList(),
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
              hintText: 'Search first aid guides...',
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
          
          // Filter chips
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
                  'Urgency',
                  _selectedUrgency,
                  _urgencyLevels,
                  (value) => setState(() => _selectedUrgency = value!),
                ),
              ),
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

  Widget _buildGuidesList() {
    final filteredGuides = _filteredGuides;
    
    if (filteredGuides.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: kMobileMarginCard,
      itemCount: filteredGuides.length,
      separatorBuilder: (context, index) => const SizedBox(height: kMobileSizedBoxMedium),
      itemBuilder: (context, index) {
        return _buildGuideCard(filteredGuides[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'No guides found',
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

  Widget _buildGuideCard(FirstAidGuideModel guide) {
    return InkWell(
      onTap: () => _viewGuideDetails(guide),
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
                _buildUrgencyBadge(guide.urgencyLevel),
                const Spacer(),
                _buildCategoryChip(guide.category),
              ],
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            
            Text(
              guide.title,
              style: kMobileTextStyleTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            
            Text(
              guide.description,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (guide.tags.isNotEmpty) ...[
              const SizedBox(height: kMobileSizedBoxMedium),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: guide.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${guide.steps.length} steps',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'View Guide',
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

  Widget _buildUrgencyBadge(String urgencyLevel) {
    Color color;
    IconData icon;
    
    switch (urgencyLevel.toLowerCase()) {
      case 'critical':
        color = AppColors.error;
        icon = Icons.emergency;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.yellow.shade700;
        icon = Icons.warning;
        break;
      default:
        color = AppColors.success;
        icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            urgencyLevel,
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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

  void _viewGuideDetails(FirstAidGuideModel guide) {
    // TODO: Navigate to detailed guide view
    context.push('/first-aid-guide/${guide.id}', extra: guide);
  }
}