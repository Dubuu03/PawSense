import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/ui/scroll_to_top_fab.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/services/clinic/clinic_recommendation_service.dart';
import 'package:pawsense/core/widgets/user/clinic/recommended_clinics_widget.dart';

/// Skin Disease Detail Page (Mobile/User)
/// 
/// Displays detailed information about a specific skin disease
/// With collapsing app bar and conditional UI based on disease properties
class SkinDiseaseDetailPage extends StatefulWidget {
  final SkinDiseaseModel disease;

  const SkinDiseaseDetailPage({
    super.key,
    required this.disease,
  });

  @override
  State<SkinDiseaseDetailPage> createState() => _SkinDiseaseDetailPageState();
}

class _SkinDiseaseDetailPageState extends State<SkinDiseaseDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  List<Map<String, dynamic>> _recommendedClinics = [];
  bool _isLoadingClinics = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchRecommendedClinics();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Collapse threshold at 150 pixels
    final shouldCollapse = _scrollController.offset > 150;
    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
    }
  }

  /// Fetch recommended clinics based on the disease
  Future<void> _fetchRecommendedClinics() async {
    setState(() {
      _isLoadingClinics = true;
    });
    
    try {
      print('🔍 Fetching recommended clinics for: ${widget.disease.name}');
      
      final recommendedClinics = await ClinicRecommendationService
          .getRecommendedClinicsForDisease(widget.disease.name);
      
      if (mounted) {
        setState(() {
          _recommendedClinics = recommendedClinics;
          _isLoadingClinics = false;
        });
      }
      
      print('✅ Found ${recommendedClinics.length} recommended clinics');
    } catch (e) {
      print('❌ Error fetching recommended clinics: $e');
      if (mounted) {
        setState(() {
          _isLoadingClinics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScrollToTopFab(
        scrollController: _scrollController,
        showThreshold: 250.0, // Higher threshold since this is a detail page
        tooltip: 'Scroll to top',
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with image
          _buildAppBar(context),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Species, Duration, Cause, Contagious badges
                _buildInfoBadges(),
                
                // What is this condition?
                _buildSection(
                  title: 'What is this condition?',
                  content: widget.disease.description,
                ),
                
                // Key symptoms
                if (widget.disease.symptoms.isNotEmpty)
                  _buildListSection(
                    title: 'Key symptoms to watch for',
                    icon: '⚠️',
                    items: widget.disease.symptoms,
                    iconColor: AppColors.warning,
                  ),
                
                // Causes
                if (widget.disease.causes.isNotEmpty)
                  _buildListSection(
                    title: 'Common causes',
                    icon: '💊',
                    items: widget.disease.causes,
                    iconColor: AppColors.info,
                  ),
                
                // Treatments
                if (widget.disease.treatments.isNotEmpty)
                  _buildListSection(
                    title: 'Treatment options',
                    icon: '💉',
                    items: widget.disease.treatments,
                    iconColor: AppColors.success,
                  ),
                
                // Initial Care Guidelines (if available)
                if (widget.disease.initialRemedies != null)
                  _buildInitialCareSection(),
                
                // Recommended Clinics Section
                if (_recommendedClinics.isNotEmpty || _isLoadingClinics)
                  _buildRecommendedClinicsSection(),
                
                if (_recommendedClinics.isNotEmpty || _isLoadingClinics)
                  const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(context),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: _isCollapsed
            ? const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 24,
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
      ),
      title: _isCollapsed
          ? Text(
              widget.disease.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            widget.disease.imageUrl.isNotEmpty
                ? _buildImage()
                : _buildPlaceholderImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            
            // Title at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  Text(
                    widget.disease.categories.join(' • ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name
                  Text(
                    widget.disease.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(widget.disease.severity).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.disease.severity} Severity',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if imageUrl is a network URL or a local asset filename
    final isNetworkImage = widget.disease.imageUrl.startsWith('http://') || 
                           widget.disease.imageUrl.startsWith('https://');
    
    if (isNetworkImage) {
      // Use network image
      return Image.network(
        widget.disease.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      // Use asset image - construct path from filename
      final assetPath = 'assets/img/skin_diseases/${widget.disease.imageUrl}';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.border,
      child: const Center(
        child: Icon(
          Icons.medical_information_outlined,
          size: 80,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildInfoBadges() {
    return Container(
      margin: const EdgeInsets.all(kMobileMarginHorizontal),
      child: Column(
        children: [
          // First row: Species and Duration
          Row(
            children: [
              // Species badge
              Expanded(
                child: _buildBadge(
                  icon: '🐾',
                  label: 'SPECIES',
                  value: widget.disease.speciesDisplay,
                ),
              ),
              const SizedBox(width: 12),
              // Duration badge
              Expanded(
                child: _buildBadge(
                  icon: '⏱️',
                  label: 'DURATION',
                  value: widget.disease.duration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Contagious and Severity
          Row(
            children: [
              // Contagious badge
              Expanded(
                child: _buildBadge(
                  icon: widget.disease.isContagious ? '⚠️' : '✅',
                  label: 'CONTAGIOUS',
                  value: widget.disease.isContagious ? 'Yes' : 'No',
                ),
              ),
              const SizedBox(width: 12),
              // Severity badge
              Expanded(
                child: _buildBadge(
                  icon: _getSeverityIcon(),
                  label: 'SEVERITY',
                  value: '${widget.disease.severity[0].toUpperCase()}${widget.disease.severity.substring(1)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSeverityIcon() {
    switch (widget.disease.severity.toLowerCase()) {
      case 'low':
      case 'mild':
        return '🟢';
      case 'high':
      case 'severe':
        return '🔴';
      case 'moderate':
      default:
        return '🟡';
    }
  }

  Widget _buildBadge({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: kMobilePaddingCard,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kMobileCardShadowSmall,
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required String icon,
    required List<String> items,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kMobileCardShadowSmall,
            ),
            child: Column(
              children: items
                  .map((item) => _buildListItem(icon, item, iconColor))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCareSection() {
    final remedies = widget.disease.initialRemedies!;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Important disclaimer banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚕️ Professional Diagnosis Required',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Always consult your veterinarian for proper diagnosis. The information below is for educational purposes only.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Section title
          Text(
            'If Diagnosed: How to Manage',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If your vet confirms this condition, here are care guidelines to help manage it:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // Care guidelines container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kMobileCardShadowSmall,
            ),
            child: Column(
              children: [
                // Immediate Care
                if (remedies.containsKey('immediateCare'))
                  _buildCareItem(
                    icon: Icons.medical_information,
                    iconColor: AppColors.error,
                    title: (remedies['immediateCare'] as Map<String, dynamic>)['title'] ?? 'Immediate Care',
                    actions: List<String>.from((remedies['immediateCare'] as Map<String, dynamic>)['actions'] ?? []),
                  ),
                
                // Topical Treatment / Environmental Care
                if (remedies.containsKey('topicalTreatment'))
                  _buildCareItem(
                    icon: Icons.healing,
                    iconColor: AppColors.primary,
                    title: (remedies['topicalTreatment'] as Map<String, dynamic>)['title'] ?? 'Treatment',
                    actions: List<String>.from((remedies['topicalTreatment'] as Map<String, dynamic>)['actions'] ?? []),
                    note: (remedies['topicalTreatment'] as Map<String, dynamic>)['note'] as String?,
                  ),
                
                // Monitoring
                if (remedies.containsKey('monitoring'))
                  _buildCareItem(
                    icon: Icons.track_changes,
                    iconColor: AppColors.info,
                    title: (remedies['monitoring'] as Map<String, dynamic>)['title'] ?? 'Monitor Progress',
                    actions: List<String>.from((remedies['monitoring'] as Map<String, dynamic>)['actions'] ?? []),
                  ),
                
                // When to Seek Help
                if (remedies.containsKey('whenToSeekHelp'))
                  _buildCareItem(
                    icon: Icons.warning_amber,
                    iconColor: AppColors.warning,
                    title: (remedies['whenToSeekHelp'] as Map<String, dynamic>)['title'] ?? 'When to Seek Help',
                    actions: List<String>.from((remedies['whenToSeekHelp'] as Map<String, dynamic>)['actions'] ?? []),
                    urgency: (remedies['whenToSeekHelp'] as Map<String, dynamic>)['urgency'] as String?,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCareItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> actions,
    String? note,
    String? urgency,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          // Urgency indicator
          if (urgency != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Timeframe: ${urgency.replaceAll('_', ' ')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Actions list
          ...actions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          // Note
          if (note != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.info,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendedClinicsSection() {
    if (_isLoadingClinics) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Finding specialized clinics...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendedClinics.isEmpty) {
      return const SizedBox.shrink();
    }

    return RecommendedClinicsWidget(
      recommendedClinics: _recommendedClinics,
      detectedDisease: widget.disease.name,
      onClinicTap: (clinicId, clinicName) {
        // Navigate to book appointment with preselected clinic
        context.push(
          '/book-appointment',
          extra: {
            'preselectedClinicId': clinicId,
            'preselectedClinicName': clinicName,
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Check if disease has AI detection
    final hasAIDetection = widget.disease.detectionMethod.toLowerCase() == 'ai';
    
    return Container(
      margin: const EdgeInsets.all(kMobileMarginHorizontal),
      child: Column(
        children: [
          // Book vet appointment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to book appointment
                context.push('/book-appointment');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Book vet appointment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Track condition button - only show for AI-detectable diseases
          if (hasAIDetection) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _handleTrackCondition(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Track ${widget.disease.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Handle track condition button tap
  /// Shows species selection if disease affects multiple species
  void _handleTrackCondition(BuildContext context) {
    final species = widget.disease.species;
    
    if (species.length > 1) {
      // Multiple species - show selection modal
      _showSpeciesSelection(context);
    } else if (species.isNotEmpty) {
      // Single species - route directly to assessment
      final selectedSpecies = species.first.toLowerCase();
      String petType = 'Dog'; // Default
      
      if (selectedSpecies.contains('cat')) {
        petType = 'Cat';
      } else if (selectedSpecies.contains('dog')) {
        petType = 'Dog';
      }
      
      // Navigate to assessment page with selectedPetType
      context.push(
        '/assessment',
        extra: {'selectedPetType': petType},
      );
    }
  }
  
  /// Show species selection bottom sheet
  void _showSpeciesSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Select Your Pet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which type of pet you want to assess',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Species buttons
            Row(
              children: [
                // Cat button
                Expanded(
                  child: _buildSpeciesButton(
                    context: context,
                    icon: '🐱',
                    label: 'Cat',
                    species: 'cats',
                  ),
                ),
                const SizedBox(width: 16),
                // Dog button
                Expanded(
                  child: _buildSpeciesButton(
                    context: context,
                    icon: '🐶',
                    label: 'Dog',
                    species: 'dogs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  /// Build species selection button
  Widget _buildSpeciesButton({
    required BuildContext context,
    required String icon,
    required String label,
    required String species,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Navigate to assessment page with selected pet type
        String petType = label; // 'Cat' or 'Dog'
        context.push(
          '/assessment',
          extra: {'selectedPetType': petType},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
      case 'mild':
        return AppColors.success;
      case 'high':
      case 'severe':
        return AppColors.error;
      case 'moderate':
      default:
        return AppColors.warning;
    }
  }
}
