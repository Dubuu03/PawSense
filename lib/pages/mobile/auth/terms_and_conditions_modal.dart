import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants_mobile.dart';

/// Terms and Conditions Modal
///
/// Modal dialog that displays the terms and conditions and requires user agreement.
/// This widget manages the state of the modal and handles user interactions.
class TermsAndConditionsModal extends StatefulWidget {
  const TermsAndConditionsModal({super.key});

  @override
  State<TermsAndConditionsModal> createState() => _TermsAndConditionsModalState();
}

class _TermsAndConditionsModalState extends State<TermsAndConditionsModal>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;
  bool _checked = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && 
        !_scrollController.position.outOfRange) {
      if (!_scrolledToBottom) {
        setState(() => _scrolledToBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildScrollProgress() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        if (!_scrollController.hasClients) {
          return const SizedBox();
        }
        
        final progress = _scrollController.offset / 
            _scrollController.position.maxScrollExtent;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall, vertical: 2),
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsContent() {
    return RichText(
      text: TextSpan(
        style: kMobileTextStyleSubtitle.copyWith(
          color: AppColors.textPrimary,
          height: 1.4,
          fontSize: 12,
        ),
        children: [
          const TextSpan(
            text: 'Welcome to PawSense, an AI-enabled mobile application that uses YOLO-based image processing to assist in the early detection of common pet skin diseases and provide real-time care guidance. '
                'By downloading, accessing, or using the PawSense application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the App.\n\n',
          ),
          TextSpan(
            text: '1. Acceptance of Terms\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'By accessing or using PawSense, you agree to be legally bound by these Terms. If you do not agree, you must discontinue use of the App immediately.\n\n',
          ),
          TextSpan(
            text: '2. Purpose of the App\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'PawSense is designed to:\n'
                '• Provide AI-assisted screening of visible skin conditions in cats and dogs.\n'
                '• Offer non-prescriptive care guidance and informational resources.\n'
                '• Facilitate user access to nearby veterinary clinics and related services.\n\n'
                'Important: PawSense is not a substitute for professional veterinary diagnosis, advice, or treatment. All health concerns should be confirmed with a licensed veterinarian.\n\n',
          ),
          TextSpan(
            text: '3. User Responsibilities\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'You agree to:\n'
                '• Provide accurate and truthful information when registering and using the App.\n'
                '• Use the App only for lawful purposes and in compliance with applicable laws.\n'
                '• Avoid misuse of the App, including attempting to reverse engineer, hack, or disrupt services.\n\n',
          ),
          TextSpan(
            text: '4. AI Detection Limitations\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: '• The App detects only visible skin conditions and cannot diagnose internal health issues.\n'
                '• Accuracy depends on image quality, lighting, and the diversity of the AI training dataset.\n'
                '• Only one condition per image will be identified; multiple conditions may require separate scans.\n\n',
          ),
          TextSpan(
            text: '5. Data Collection and Privacy\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'PawSense collects certain personal data (e.g., name, email, pet details) and scan history to provide services.\n'
                'Images submitted are used for analysis and may be stored for model improvement, with anonymization where applicable.\n'
                'All data handling follows our Privacy Policy. By using the App, you consent to such data processing.\n\n',
          ),
          TextSpan(
            text: '6. Intellectual Property\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'All content, features, and functionalities of PawSense—including text, graphics, AI models, and software—are owned by the PawSense developers and are protected by copyright, trademark, and other intellectual property laws.\n\n',
          ),
          TextSpan(
            text: '7. Third-Party Services\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'The App may include integrations with third-party services (e.g., maps for locating clinics, cloud AI services). Your use of such services is subject to their respective terms and conditions.\n\n',
          ),
          TextSpan(
            text: '8. Disclaimers\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'PawSense is provided "as is" without warranties of any kind, express or implied.\n'
                'The developers are not liable for any damages, losses, or injuries resulting from reliance on the Apps results or guidance.\n'
                'Veterinary care decisions should always be made with professional input.\n\n',
          ),
          TextSpan(
            text: '9. Limitation of Liability\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'To the maximum extent permitted by law, PawSense and its developers will not be liable for:\n'
                '• Errors or inaccuracies in AI analysis.\n'
                '• Any loss or damage resulting from reliance on the Apps outputs.\n'
                '• Service interruptions, bugs, or technical failures.\n\n',
          ),
          TextSpan(
            text: '10. Modifications to Terms\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'We may update these Terms at any time. Continued use of the App after updates means you accept the revised Terms.\n\n',
          ),
          TextSpan(
            text: '11. Governing Law\n',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: 'These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: kMobilePaddingMedium, vertical: 30),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (full width background)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(kMobilePaddingMedium, kMobilePaddingMedium, kMobilePaddingMedium, kMobilePaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(kMobilePaddingSmall),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: kMobileCardShadowSmall,
                        ),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: kMobileSizedBoxMedium),
                      Text(
                        'Terms and Conditions',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: kMobileSizedBoxSmall),
                      Text(
                        'Please read and accept our terms to continue',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Progress indicator
                if (!_scrolledToBottom) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall, vertical: kMobileSizedBoxSmall),
                    color: AppColors.warning.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swipe,
                          color: AppColors.warning,
                          size: 14,
                        ),
                        SizedBox(width: kMobileSizedBoxSmall),
                        Expanded(
                          child: Text(
                            'Please scroll to the bottom to accept terms',
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildScrollProgress(),
                ],
                
                SizedBox(height: 12),
                // Content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      radius: Radius.circular(kMobileBorderRadiusButton),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(kMobilePaddingSmall),
                        child: _buildTermsContent(),
                      ),
                    ),
                  ),
                ),
                
                // Extra spacing before checkbox
                SizedBox(height: kMobileSizedBoxLarge),
                
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall, vertical: 2),
              padding: EdgeInsets.symmetric(horizontal: kMobilePaddingSmall, vertical: 10),
              decoration: BoxDecoration(
                color: _scrolledToBottom
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                border: Border.all(
                  color: _scrolledToBottom
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.textTertiary.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: _scrolledToBottom
                          ? () => setState(() => _checked = !_checked)
                          : null,
                      child: Icon(
                        _checked ? Icons.check_box : Icons.check_box_outline_blank,
                        color: _scrolledToBottom
                            ? (_checked ? AppColors.primary : AppColors.textSecondary)
                            : AppColors.textTertiary,
                        size: 18, // smaller icon
                      ),
                    ),
                  ),
                  SizedBox(width: kMobileSizedBoxMedium - 2),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions',
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontSize: 13, // slightly smaller text
                        color: _scrolledToBottom ? AppColors.primary : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),


                // Action buttons
                Container(
                  padding: EdgeInsets.all(kMobilePaddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                            ),
                            side: BorderSide(color: AppColors.textTertiary),
                          ),
                          child: Text(
                            'Cancel',
                            style: kMobileTextStyleSubtitle.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: kMobileSizedBoxMedium),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_scrolledToBottom && _checked) 
                              ? () => Navigator.pop(context, true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: kMobileTextStyleSubtitle.copyWith(
                              fontSize: 11,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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