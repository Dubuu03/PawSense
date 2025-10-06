import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:go_router/go_router.dart';

/// Skin Disease Detail Page (Mobile/User)
/// 
/// Displays detailed information about a specific skin disease
/// Based on the design from pasted image 3
class SkinDiseaseDetailPage extends StatelessWidget {
  final SkinDiseaseModel disease;

  const SkinDiseaseDetailPage({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                  content: disease.description,
                ),
                
                // Key symptoms
                if (disease.symptoms.isNotEmpty)
                  _buildListSection(
                    title: 'Key symptoms to watch for',
                    icon: '⚠️',
                    items: disease.symptoms,
                    iconColor: AppColors.warning,
                  ),
                
                // Causes
                if (disease.causes.isNotEmpty)
                  _buildListSection(
                    title: 'Common causes',
                    icon: '💊',
                    items: disease.causes,
                    iconColor: AppColors.info,
                  ),
                
                // Treatments
                if (disease.treatments.isNotEmpty)
                  _buildListSection(
                    title: 'Treatment options',
                    icon: '💉',
                    items: disease.treatments,
                    iconColor: AppColors.success,
                  ),
                
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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
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
      actions: [
        IconButton(
          onPressed: () {
            // Bookmark functionality (future)
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            // Share functionality (future)
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            disease.imageUrl.isNotEmpty
                ? Image.network(
                    disease.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
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
                    disease.categories.join(' • ').toUpperCase(),
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
                    disease.name,
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
                      color: _getSeverityColor(disease.severity).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${disease.severity} Severity',
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
      child: Row(
        children: [
          // Species badge
          Expanded(
            child: _buildBadge(
              icon: '🐾',
              label: 'SPECIES',
              value: disease.speciesDisplay,
            ),
          ),
          const SizedBox(width: 12),
          // Duration badge
          Expanded(
            child: _buildBadge(
              icon: '⏱️',
              label: 'DURATION',
              value: disease.duration,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildActionButtons(BuildContext context) {
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
          
          const SizedBox(height: 12),
          
          // Track condition button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to assessment or tracking
                context.push('/assessment');
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
                    'Track ${disease.name}',
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
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'high':
        return AppColors.error;
      case 'moderate':
      default:
        return AppColors.warning;
    }
  }
}
