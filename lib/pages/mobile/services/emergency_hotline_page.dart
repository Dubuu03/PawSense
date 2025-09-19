import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/services/emergency_hotline_model.dart';
import 'package:pawsense/core/services/mobile/services/emergency_hotline_service.dart';

class EmergencyHotlinePage extends StatefulWidget {
  const EmergencyHotlinePage({super.key});

  @override
  State<EmergencyHotlinePage> createState() => _EmergencyHotlinePageState();
}

class _EmergencyHotlinePageState extends State<EmergencyHotlinePage> {
  List<EmergencyHotlineModel> _hotlines = [];
  bool _loading = true;
  String _selectedType = 'All';

  final List<String> _emergencyTypes = [
    'All',
    'General',
    'Poisoning',
    'Medical',
    'Trauma',
    'Behavioral',
  ];

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  Future<void> _loadHotlines() async {
    setState(() => _loading = true);
    
    try {
      List<EmergencyHotlineModel> hotlines;
      if (_selectedType == 'All') {
        hotlines = await EmergencyHotlineService.getActiveHotlines();
      } else {
        hotlines = await EmergencyHotlineService.getHotlinesByType(_selectedType);
      }
      
      setState(() {
        _hotlines = hotlines;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hotlines: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Emergency Hotline',
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
          _buildEmergencyBanner(),
          _buildFilterChips(),
          Expanded(
            child: _loading ? _buildLoadingState() : _buildHotlinesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: kMobileBorderRadiusCardPreset,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emergency,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Support',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '24/7 assistance for pet emergencies',
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

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _emergencyTypes.length,
        itemBuilder: (context, index) {
          final type = _emergencyTypes[index];
          final isSelected = type == _selectedType;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedType = type);
                _loadHotlines();
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildHotlinesList() {
    if (_hotlines.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: kMobileMarginCard,
      itemCount: _hotlines.length,
      separatorBuilder: (context, index) => const SizedBox(height: kMobileSizedBoxMedium),
      itemBuilder: (context, index) {
        return _buildHotlineCard(_hotlines[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_disabled,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'No hotlines available',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            'Try selecting a different emergency type',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(EmergencyHotlineModel hotline) {
    return Container(
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
              _buildPriorityIcon(hotline.priority),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotline.title,
                      style: kMobileTextStyleTitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotline.emergencyType,
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (hotline.isAvailable24_7)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '24/7',
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          Text(
            hotline.description,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          if (hotline.operatingHours.isNotEmpty) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: hotline.operatingHours.map((hours) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hours,
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              )).toList(),
            ),
          ],
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(hotline.phoneNumber),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (hotline.website != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openWebsite(hotline.website!),
                  icon: const Icon(Icons.web),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
              if (hotline.email != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendEmail(hotline.email!),
                  icon: const Icon(Icons.email),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIcon(int priority) {
    IconData icon;
    Color color;
    
    if (priority >= 9) {
      icon = Icons.priority_high;
      color = AppColors.error;
    } else if (priority >= 7) {
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      icon = Icons.info;
      color = AppColors.primary;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // TODO: Implement phone call functionality with url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call: $phoneNumber'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Copy',
          textColor: AppColors.white,
          onPressed: () {
            // TODO: Copy to clipboard
          },
        ),
      ),
    );
  }

  Future<void> _openWebsite(String website) async {
    // TODO: Implement website opening with url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Website: $website'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _sendEmail(String email) async {
    // TODO: Implement email sending with url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email: $email'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}