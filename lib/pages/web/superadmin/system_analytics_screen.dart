import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/shared/page_header.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  String selectedPeriod = 'Last 30 Days';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'System Analytics',
            subtitle: 'Comprehensive system performance and usage analytics',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Action Bar
                  _buildActionBar(),
                  
                  SizedBox(height: kSpacingLarge),
                  
                  if (isLoading) ...[
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: kSpacingMedium),
                          Text(
                            'Loading analytics data...',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Main Dashboard Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildUserGrowthTrendCard(),
                              SizedBox(height: kSpacingLarge),
                              _buildClinicPerformanceCard(),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: kSpacingLarge),
                        
                        // Right Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildScanUsageDistributionCard(),
                              SizedBox(height: kSpacingLarge),
                              _buildSystemHealthMetricsCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: kSpacingLarge),
                    
                    // Bottom Full-Width Cards
                    _buildRevenueAnalyticsCard(),
                    
                    SizedBox(height: kSpacingLarge),
                    
                    _buildAppointmentMetricsCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kSpacingLarge, vertical: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Time Period:',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: kSpacingMedium),
          Container(
            padding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: kSpacingSmall),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPeriod = newValue;
                    });
                    _loadAnalyticsData();
                  }
                },
                items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Last Year']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: kTextStyleRegular),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Spacer(),
          
          Text(
            'Last updated: ${_formatDateTime(DateTime.now())}',
            style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
          ),
          
          SizedBox(width: kSpacingLarge),
          
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: Icon(Icons.refresh, size: kIconSizeMedium),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
            ),
          ),
          
          SizedBox(width: kSpacingMedium),
          
          ElevatedButton.icon(
            onPressed: _exportAnalytics,
            icon: Icon(Icons.download, size: kIconSizeMedium),
            label: Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthTrendCard() {
    final growthData = [
      {'month': 'Jan', 'users': 12450},
      {'month': 'Feb', 'users': 13230},
      {'month': 'Mar', 'users': 13980},
      {'month': 'Apr', 'users': 14560},
      {'month': 'May', 'users': 15120},
      {'month': 'Jun', 'users': 15847},
    ];

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Growth Trend',
                style: kTextStyleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+23.5% growth',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: kSpacingLarge),
          
          // Growth bars visualization
          ...growthData.map((data) => Padding(
            padding: EdgeInsets.only(bottom: kSpacingMedium),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    data['month'] as String,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    width: ((data['users'] as int) / 16000) * 300,
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Text(
                  (data['users'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScanUsageDistributionCard() {
    final scanData = [
      {'type': 'Diagnostic Scans', 'count': 3456, 'color': AppColors.primary},
      {'type': 'Routine Checkups', 'count': 2890, 'color': AppColors.info},
      {'type': 'Emergency Scans', 'count': 1245, 'color': AppColors.error},
      {'type': 'Follow-up Scans', 'count': 978, 'color': AppColors.warning},
      {'type': 'Preventive Care', 'count': 623, 'color': AppColors.success},
    ];

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Usage Distribution',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          ...scanData.map((data) => Padding(
            padding: EdgeInsets.only(bottom: kSpacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data['type'] as String,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (data['count'] as int) / 3500,
                    child: Container(
                      decoration: BoxDecoration(
                        color: data['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Text(
                  (data['count'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildClinicPerformanceCard() {
    final clinicData = [
      {'name': 'VetCare Central', 'score': 94, 'color': AppColors.success},
      {'name': 'Pet Health Plus', 'score': 87, 'color': AppColors.info},
      {'name': 'Animal Wellness', 'score': 91, 'color': AppColors.success},
      {'name': 'Furry Friends', 'score': 76, 'color': AppColors.warning},
      {'name': 'Downtown Pet', 'score': 82, 'color': AppColors.info},
    ];

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Clinic Performance Scores',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          ...clinicData.map((data) => Padding(
            padding: EdgeInsets.only(bottom: kSpacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data['name'] as String,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (data['score'] as int) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: data['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Text(
                  '${data['score']}%',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSystemHealthMetricsCard() {
    final healthMetrics = [
      {
        'title': 'API Response Time',
        'value': '245ms',
        'change': '-8.3%',
        'isPositive': true,
        'color': AppColors.info,
      },
      {
        'title': 'Database Performance',
        'value': '99.2%',
        'change': '+0.5%',
        'isPositive': true,
        'color': AppColors.success,
      },
      {
        'title': 'Error Rate',
        'value': '0.08%',
        'change': '-12.4%',
        'isPositive': true,
        'color': AppColors.info,
      },
    ];

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health Metrics',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          ...healthMetrics.map((metric) => Container(
            margin: EdgeInsets.only(bottom: kSpacingMedium),
            padding: EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric['title'] as String,
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        metric['value'] as String,
                        style: kTextStyleLarge.copyWith(
                          color: metric['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      (metric['isPositive'] as bool) ? Icons.trending_up : Icons.trending_down,
                      color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      metric['change'] as String,
                      style: kTextStyleSmall.copyWith(
                        color: (metric['isPositive'] as bool) ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: kSpacingSmall),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: metric['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalyticsCard() {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Analytics',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          Row(
            children: [
              _buildQuickStatCard(
                'Total Revenue',
                '₱2.45M',
                '+18.2% vs last month',
                AppColors.success,
                Icons.account_balance_wallet,
              ),
              SizedBox(width: kSpacingLarge),
              _buildQuickStatCard(
                'Monthly Average',
                '₱408K',
                '+12.5% growth',
                AppColors.info,
                Icons.trending_up,
              ),
              SizedBox(width: kSpacingLarge),
              _buildQuickStatCard(
                'Avg Transaction',
                '₱756',
                '+5.3% vs last month',
                AppColors.primary,
                Icons.receipt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentMetricsCard() {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Metrics',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          Row(
            children: [
              _buildQuickStatCard(
                'Total Appointments',
                '8,934',
                '+15.7% vs last month',
                AppColors.primary,
                Icons.calendar_today,
              ),
              SizedBox(width: kSpacingLarge),
              _buildQuickStatCard(
                'Completion Rate',
                '87.5%',
                '+2.1% improvement',
                AppColors.success,
                Icons.check_circle,
              ),
              SizedBox(width: kSpacingLarge),
              _buildQuickStatCard(
                'No-Show Rate',
                '8.3%',
                '-1.2% improvement',
                AppColors.warning,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, String change, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(kSpacingLarge),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: kIconSizeLarge),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: kTextStyleSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: kSpacingMedium),
            Text(
              value,
              style: kTextStyleTitle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              title,
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 800));

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _exportAnalytics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: kSpacingMedium),
            Text('Exporting analytics...'),
          ],
        ),
      ),
    );

    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics exported successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
