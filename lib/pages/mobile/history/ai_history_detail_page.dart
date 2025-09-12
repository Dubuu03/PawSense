import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/home/ai_history_list.dart';

class AIHistoryDetailPage extends StatefulWidget {
  final String aiHistoryId;

  const AIHistoryDetailPage({
    super.key,
    required this.aiHistoryId,
  });

  @override
  State<AIHistoryDetailPage> createState() => _AIHistoryDetailPageState();
}

class _AIHistoryDetailPageState extends State<AIHistoryDetailPage> {
  AIHistoryData? _aiHistoryData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAIHistoryData();
  }

  Future<void> _loadAIHistoryData() async {
    setState(() {
      _loading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data based on ID - in real app, fetch from API/database
    final mockData = _getMockAIHistoryData(widget.aiHistoryId);

    setState(() {
      _aiHistoryData = mockData;
      _loading = false;
    });
  }

  AIHistoryData? _getMockAIHistoryData(String id) {
    // Mock data - replace with actual API call
    final mockDataMap = {
      '1': AIHistoryData(
        id: '1',
        title: 'Mange Detection',
        subtitle: 'Detected on Max - German Shepherd',
        type: AIDetectionType.mange,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        confidence: 0.87,
      ),
      '2': AIHistoryData(
        id: '2',
        title: 'Ringworm Detection',
        subtitle: 'Detected on Luna - Labrador',
        type: AIDetectionType.ringworm,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        confidence: 0.92,
      ),
      '3': AIHistoryData(
        id: '3',
        title: 'Pyoderma Detection',
        subtitle: 'Detected on Buddy - Golden Retriever',
        type: AIDetectionType.pyoderma,
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        confidence: 0.78,
      ),
    };

    return mockDataMap[id];
  }

  Color _getDetectionColor() {
    if (_aiHistoryData == null) return AppColors.primary;
    
    switch (_aiHistoryData!.type) {
      case AIDetectionType.mange:
        return const Color(0xFFFF9500);
      case AIDetectionType.ringworm:
        return const Color(0xFF007AFF);
      case AIDetectionType.pyoderma:
        return const Color(0xFFE74C3C);
      case AIDetectionType.hotSpot:
        return const Color(0xFF8E44AD);
      case AIDetectionType.fleaAllergy:
        return const Color(0xFF34C759);
    }
  }

  String _getDetectionLabel() {
    if (_aiHistoryData == null) return '';
    
    switch (_aiHistoryData!.type) {
      case AIDetectionType.mange:
        return 'Mange';
      case AIDetectionType.ringworm:
        return 'Ringworm';
      case AIDetectionType.pyoderma:
        return 'Pyoderma';
      case AIDetectionType.hotSpot:
        return 'Hot Spot';
      case AIDetectionType.fleaAllergy:
        return 'Flea Allergy';
    }
  }

  String _getDetailedDescription() {
    if (_aiHistoryData == null) return '';
    
    switch (_aiHistoryData!.type) {
      case AIDetectionType.mange:
        return 'Mange is a skin disease caused by mites that can cause intense itching, hair loss, and skin irritation in pets.';
      case AIDetectionType.ringworm:
        return 'Ringworm is a fungal infection that affects the skin, hair, and nails, creating circular patches of hair loss.';
      case AIDetectionType.pyoderma:
        return 'Pyoderma is a bacterial skin infection that can cause pustules, crusting, and inflammation of the skin.';
      case AIDetectionType.hotSpot:
        return 'Hot spots are localized areas of skin inflammation and infection that can develop rapidly and cause significant discomfort.';
      case AIDetectionType.fleaAllergy:
        return 'Flea allergy dermatitis is an allergic reaction to flea bites that can cause intense itching and skin irritation.';
    }
  }

  String _getRecommendations() {
    if (_aiHistoryData == null) return '';
    
    switch (_aiHistoryData!.type) {
      case AIDetectionType.mange:
        return '• Consult a veterinarian for proper diagnosis\n• Follow prescribed treatment regimen\n• Maintain good hygiene\n• Isolate from other pets if recommended';
      case AIDetectionType.ringworm:
        return '• Schedule veterinary examination\n• Topical antifungal treatment may be needed\n• Clean and disinfect environment\n• Monitor for spread to other pets';
      case AIDetectionType.pyoderma:
        return '• Veterinary consultation recommended\n• Antibiotics may be prescribed\n• Keep affected area clean and dry\n• Prevent scratching with cone if necessary';
      case AIDetectionType.hotSpot:
        return '• Clean the affected area gently\n• Keep area dry and well-ventilated\n• Prevent licking/scratching\n• Seek veterinary care if spreading';
      case AIDetectionType.fleaAllergy:
        return '• Implement flea control program\n• Use prescribed antihistamines\n• Regular grooming and bathing\n• Treat all pets in household';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home?tab=history'),
        ),
        title: Text(
          'AI Detection Details',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: _loading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildContent() {
    if (_aiHistoryData == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetectionHeader(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildConfidenceSection(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildDescriptionSection(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildRecommendationsSection(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'AI History Not Found',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            'The requested AI detection history could not be loaded.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionHeader() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getDetectionColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDetectionLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getDetectionColor(),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(_aiHistoryData!.timestamp),
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            _aiHistoryData!.title,
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            _aiHistoryData!.subtitle,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection() {
    if (_aiHistoryData?.confidence == null) return const SizedBox.shrink();

    final confidence = _aiHistoryData!.confidence!;
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Confidence',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_getDetectionColor()),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: kMobileTextStyleTitle.copyWith(
                  color: _getDetectionColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${_getDetectionLabel()}',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            _getDetailedDescription(),
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxSmall),
              Text(
                'Recommendations',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            _getRecommendations(),
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to book appointment or find vet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book appointment functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              ),
            ),
            icon: const Icon(Icons.medical_services),
            label: const Text(
              'Book Veterinary Appointment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: kMobileSizedBoxMedium),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to learn more or resources
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Learn more functionality coming soon')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              ),
            ),
            icon: const Icon(Icons.info_outline),
            label: const Text(
              'Learn More',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
