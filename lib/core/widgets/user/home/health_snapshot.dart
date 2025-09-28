import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class HealthData {
  final String condition;
  final int count;
  final Color color;

  HealthData({
    required this.condition,
    required this.count,
    required this.color,
  });
}

class HealthSnapshot extends StatelessWidget {
  final List<HealthData> healthData;

  const HealthSnapshot({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final total = healthData.fold<int>(0, (sum, item) => sum + item.count);
    
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week Snapshot',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            'Most common detections',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: kMobileDonutChartSize,
                height: kMobileDonutChartSize,
                child: Stack(
                  children: [
                    _buildDonutChart(total),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total',
                            style: kMobileTextStyleChartTotal.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Total',
                            style: kMobileTextStyleChartLabel.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: kMobileSizedBoxXXLarge),
              
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: healthData
                      .take(4)
                      .map((data) => _buildLegendItem(data))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(int total) {
    double startAngle = -90;
    
    return CustomPaint(
      size: const Size(kMobileDonutChartSize, kMobileDonutChartSize),
      painter: DonutChartPainter(
        data: healthData,
        total: total,
        startAngle: startAngle,
      ),
    );
  }

  Widget _buildLegendItem(HealthData data) {
    return Padding(
      padding: kMobileLegendPadding,
      child: Row(
        children: [
          Container(
            width: kMobileLegendDotSize,
            height: kMobileLegendDotSize,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: kMobileLegendSpacing),
          Expanded(
            child: Text(
              data.condition,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${data.count}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<HealthData> data;
  final int total;
  final double startAngle;

  DonutChartPainter({
    required this.data,
    required this.total,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.65;

    double currentAngle = startAngle * (3.14159 / 180);

    for (final item in data) {
      final sweepAngle = (item.count / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
