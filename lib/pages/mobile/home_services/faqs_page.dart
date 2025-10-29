import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  List<Map<String, dynamic>> _clinics = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await ClinicListService.getAllActiveClinics();
      setState(() {
        _clinics = clinics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredClinics {
    if (_searchQuery.isEmpty) return _clinics;
    
    return _clinics.where((clinic) {
      final name = (clinic['name'] ?? '').toString().toLowerCase();
      final address = (clinic['address'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? _buildLoadingState()
          : _filteredClinics.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: kMobileMarginCard,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                size: 50,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: kSpacingLarge),
            Text(
              _searchQuery.isEmpty 
                  ? 'No Clinics Available'
                  : 'No Results Found',
              style: kMobileTextStyleTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: kSpacingSmall),
            Text(
              _searchQuery.isEmpty
                  ? 'We\'re working on adding more veterinary clinics to help answer your questions.'
                  : 'Try adjusting your search to find what you\'re looking for.',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildStatsSection(),
                _buildClinicsList(),
                const SizedBox(height: kSpacingLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: kMobileCardShadowSmall,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search clinics...',
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        kMobileMarginHorizontal,
        kSpacingSmall,
        kMobileMarginHorizontal,
        kSpacingMedium,
      ),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: kMobileBorderRadiusCardPreset,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.help_center,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: kSpacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help Center',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get answers from trusted clinics',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: kSpacingSmall,
      ),
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_hospital,
            title: '${_filteredClinics.length}',
            subtitle: _filteredClinics.length == 1 ? 'Clinic' : 'Clinics',
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.quiz,
            title: 'Expert',
            subtitle: 'Answers',
            color: AppColors.success,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.support_agent,
            title: '24/7',
            subtitle: 'Support',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: kMobileTextStyleTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: kMobileTextStyleSubtitle.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kMobileMarginHorizontal,
            kSpacingMedium,
            kMobileMarginHorizontal,
            kSpacingSmall,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_city,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Available Clinics',
                style: kMobileTextStyleTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filteredClinics.length}',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
          itemCount: _filteredClinics.length,
          itemBuilder: (context, index) {
            final clinic = _filteredClinics[index];
            return _buildClinicCard(clinic, index);
          },
        ),
      ],
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic, int index) {
    final clinicName = clinic['name'] ?? 'Unknown Clinic';
    final clinicAddress = clinic['address'] ?? '';
    final clinicPhone = clinic['phone'] ?? '';
    final clinicId = clinic['id'] ?? '';

    // Different colors for variety
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.15),
        ),
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/clinic-faqs?clinicId=$clinicId&clinicName=${Uri.encodeComponent(clinicName)}');
          },
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: kMobilePaddingCard,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: kMobileBorderRadiusIconPreset,
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        style: kMobileTextStyleTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (clinicAddress.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clinicAddress,
                                style: kMobileTextStyleSubtitle.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (clinicPhone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clinicPhone,
                              style: kMobileTextStyleSubtitle.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: kSpacingSmall),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}