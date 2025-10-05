import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AboutPawSensePage extends StatelessWidget {
  const AboutPawSensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'About PawSense',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: kMobileSizedBoxLarge),
            
            // Hero Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              ),
              child: Column(
                children: [
                  // PawSense Logo
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/img/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image fails to load
                        return Icon(
                          Icons.pets,
                          size: 40,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Meet PawSense Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Meet PawSense',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Main Title
                  Text(
                    'Compassionate technology for every furry companion',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'PawSense blends computer vision with veterinary best practices, transforming everyday photos into actionable health insights so pets receive care at the perfect moment.',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
            
            // Three Pillars Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPillarCard(
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.primary,
                    title: 'Early Insight First',
                    description: 'We surface subtle skin changes before they become emergencies, empowering caregivers to take action quickly.',
                  ),
                  const SizedBox(height: 16),
                  _buildPillarCard(
                    icon: Icons.sync_outlined,
                    iconColor: AppColors.primary,
                    title: 'Partnering With Vets',
                    description: 'PawSense augments veterinary expertise with structured reports and rich context that make consultations more productive.',
                  ),
                  const SizedBox(height: 16),
                  _buildPillarCard(
                    icon: Icons.star_outline,
                    iconColor: AppColors.primary,
                    title: 'Accessible By Design',
                    description: 'Guided flows, inclusive language, and adaptive visuals ensure every pet family can confidently navigate care decisions.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
            
            // Why Families Choose PawSense Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Why families choose PawSense',
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Designed to complement routine checkups with proactive home screenings and clear next steps.',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PawSense began as a collaboration between veterinary clinicians and pet parents who wanted reassurance when skin issues appeared. Today, our platform is trusted in clinics and living rooms alike to triage symptoms, track healing, and connect families with the right professionals.',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.shield_outlined,
                    text: 'Secure sharing controls let you invite your veterinary team or keep assessments private until you are ready.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.camera_alt_outlined,
                    text: 'Guided scanning tips adjust to each species and coat type, producing consistent imagery for accurate analysis.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.article_outlined,
                    text: 'Personalized wellness plans summarize findings, recommend care steps, and celebrate improvements over time.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
            
            // Our Promise Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our promise moving forward',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We continue to evolve with every pet we help, guided by evidence, empathy, and transparent collaboration.',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPromiseCard(
                        icon: Icons.medical_services_outlined,
                        iconColor: AppColors.primary,
                        title: 'Clinical-Grade Guidance',
                        description: 'Our AI models are co-developed with licensed veterinarians and continuously reviewed against real-world cases.',
                      ),
                      const SizedBox(height: 16),
                      _buildPromiseCard(
                        icon: Icons.security_outlined,
                        iconColor: AppColors.primary,
                        title: 'Privacy You Can Trust',
                        description: 'Photos and assessments are stored securely, giving families full control over how and when data is shared.',
                      ),
                      const SizedBox(height: 16),
                      _buildPromiseCard(
                        icon: Icons.psychology_outlined,
                        iconColor: AppColors.primary,
                        title: 'Continuous Learning',
                        description: 'Feedback loops from clinics and caregivers strengthen detection accuracy with every scan submitted.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
            
            // Version Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Version 1.0.0',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '© 2025 PawSense',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: kMobilePaddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromiseCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}