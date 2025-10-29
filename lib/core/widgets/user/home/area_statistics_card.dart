import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/user/disease_statistics_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class AreaStatisticsCard extends StatefulWidget {
  const AreaStatisticsCard({super.key});

  @override
  State<AreaStatisticsCard> createState() => AreaStatisticsCardState();
}

class AreaStatisticsCardState extends State<AreaStatisticsCard> {
  final DiseaseStatisticsService _statisticsService = DiseaseStatisticsService();
  AreaDiseaseStatistics? _statistics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Public method to refresh statistics (can be called from parent widget)
  Future<void> refreshStatistics() async {
    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null || user.address == null || user.address!.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No address set';
          });
        }
        return;
      }

      final statistics = await _statisticsService.getMostCommonDiseaseInArea(user.address!);

      if (mounted) {
        setState(() {
          _statistics = statistics;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load statistics';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: kMobileMarginCard,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area Statistics',
                      style: kMobileTextStyleTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Most common disease in your area',
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

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.3),
          ),

          const SizedBox(height: 16),

          // Content
          if (_loading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_statistics == null || 
                   (_statistics!.dogStatistics.isEmpty && _statistics!.catStatistics.isEmpty))
            _buildNoDataState()
          else
            _buildStatisticsContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading statistics...',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load statistics',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.textTertiary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No disease data available in your area yet',
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    final statistics = _statistics!;
    final dogStats = statistics.dogStatistics;
    final catStats = statistics.catStatistics;
    
    return Column(
      children: [
        // Location display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statistics.location,
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Dog statistics
        if (dogStats.isNotEmpty) ...[
          _buildSpeciesSection(dogStats, '🐶 Dogs', AppColors.primary),
          if (catStats.isNotEmpty) const SizedBox(height: 24),
        ],
        
        // Cat statistics
        if (catStats.isNotEmpty) ...[
          _buildSpeciesSection(catStats, '🐱 Cats', const Color(0xFF9C27B0)),
        ],
      ],
    );
  }

  Widget _buildSpeciesSection(List<DiseaseStatistic> statistics, String title, Color accentColor) {
    if (statistics.isEmpty) return const SizedBox.shrink();
    
    final totalCases = statistics.first.totalCases;
    final topStats = statistics.take(5).toList();
    
    // Predefined colors for the chart segments
    final colors = [
      accentColor,
      accentColor.withOpacity(0.8),
      accentColor.withOpacity(0.6),
      accentColor.withOpacity(0.4),
      accentColor.withOpacity(0.25),
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: kMobileTextStyleTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCases total',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row with labels on left and chart on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Labels (left side)
              Expanded(
                flex: 3,
                child: Column(
                  children: topStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final color = colors[index % colors.length];
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < topStats.length - 1 ? 10 : 0),
                      child: Row(
                        children: [
                          // Color indicator
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Disease name
                          Expanded(
                            child: Text(
                              _formatDiseaseName(stat.diseaseName),
                              style: kMobileTextStyleSubtitle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Count and percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${stat.count}',
                                style: kMobileTextStyleTitle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              Text(
                                '${stat.percentage.toStringAsFixed(1)}%',
                                style: kMobileTextStyleSubtitle.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Pie chart (right side)
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    data: topStats.asMap().entries.map((entry) {
                      final stat = entry.value;
                      return _ChartData(
                        value: stat.count.toDouble(),
                        color: colors[entry.key % colors.length],
                        percentage: stat.percentage,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDiseaseName(String diseaseName) {
    // Convert disease name to title case and remove underscores
    return diseaseName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

// Chart data model
class _ChartData {
  final double value;
  final Color color;
  final double percentage;

  _ChartData({
    required this.value,
    required this.color,
    required this.percentage,
  });
}

// Custom painter for pie chart
class _PieChartPainter extends CustomPainter {
  final List<_ChartData> data;

  _PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    double startAngle = -math.pi / 2; // Start from top (-90 degrees)

    for (var segment in data) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;

      // Draw main segment
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut chart effect)
    final centerPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);

    // Draw center border
    final centerBorderPaint = Paint()
      ..color = AppColors.border.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.5, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
