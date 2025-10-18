import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pawsense/core/models/analytics/system_analytics_models.dart';

/// Service for generating PDF reports for System Analytics
class AnalyticsPdfService {
  /// Generate comprehensive analytics PDF report
  static Future<Uint8List> generateAnalyticsReport({
    required AnalyticsPeriod period,
    required UserStats userStats,
    required ClinicStats clinicStats,
    required AppointmentStats appointmentStats,
    required AIUsageStats aiStats,
    required PetStats petStats,
    required SystemHealthScore systemHealth,
    required List<ClinicPerformance> topClinics,
    required List<ClinicAlert> clinicAlerts,
    required List<DiseaseData> topDiseases,
    required DateTime generatedAt,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(generatedAt, generatedBy),
              pw.SizedBox(height: 30),

              // Report Title
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'System Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Period: ${period.label}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.purple700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${DateFormat('MMMM d, yyyy \'at\' h:mm a').format(generatedAt)}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // System Health Score
              _buildSystemHealthSection(systemHealth),

              pw.SizedBox(height: 20),

              // Executive Summary
              _buildExecutiveSummary(
                userStats,
                clinicStats,
                appointmentStats,
                aiStats,
                petStats,
              ),
            ],
          );
        },
      ),
    );

    // Add detailed metrics page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildSectionHeader('Detailed Metrics'),
            pw.SizedBox(height: 20),

            // User Metrics
            _buildMetricCard('User Statistics', [
              _buildMetricRow('Total Users', userStats.totalUsers.toString()),
              _buildMetricRow('Active Users', '${userStats.activeUsers} (${_calculatePercentage(userStats.activeUsers, userStats.totalUsers)}%)'),
              _buildMetricRow('Suspended Users', userStats.suspendedUsers.toString()),
              _buildMetricRow('New Users (Period)', userStats.newUsers.toString()),
              _buildMetricRow('Growth Rate', '${userStats.growthRate.toStringAsFixed(1)}%'),
            ]),

            pw.SizedBox(height: 15),

            // Clinic Metrics
            _buildMetricCard('Clinic Statistics', [
              _buildMetricRow('Total Clinics', clinicStats.totalClinics.toString()),
              _buildMetricRow('Active Clinics', '${clinicStats.activeClinics} (${_calculatePercentage(clinicStats.activeClinics, clinicStats.totalClinics)}%)'),
              _buildMetricRow('Pending Applications', clinicStats.pendingClinics.toString()),
              _buildMetricRow('Approval Rate', '${clinicStats.approvalRate.toStringAsFixed(1)}%'),
              _buildMetricRow('New Clinics (Period)', clinicStats.newClinics.toString()),
            ]),

            pw.SizedBox(height: 15),

            // Appointment Metrics
            _buildMetricCard('Appointment Statistics', [
              _buildMetricRow('Total Appointments', appointmentStats.totalAppointments.toString()),
              _buildMetricRow('Completed', '${appointmentStats.completedAppointments} (${appointmentStats.completionRate.toStringAsFixed(1)}%)'),
              _buildMetricRow('Pending', appointmentStats.pendingAppointments.toString()),
              _buildMetricRow('Cancelled/Rejected', '${appointmentStats.cancelledAppointments + appointmentStats.rejectedAppointments}'),
              _buildMetricRow('New Appointments (Period)', appointmentStats.newAppointments.toString()),
            ]),

            pw.SizedBox(height: 15),

            // AI Usage Metrics
            _buildMetricCard('AI Usage Statistics', [
              _buildMetricRow('Total Scans', aiStats.totalScans.toString()),
              _buildMetricRow('High Confidence Scans', '${aiStats.highConfidenceScans} (${aiStats.totalScans > 0 ? ((aiStats.highConfidenceScans / aiStats.totalScans) * 100).toStringAsFixed(1) : '0'}%)'),
              _buildMetricRow('Average Confidence', '${aiStats.avgConfidence.toStringAsFixed(1)}%'),
              _buildMetricRow('Scan→Appointment Conversions', aiStats.scanToAppointmentConversions.toString()),
              _buildMetricRow('New Scans (Period)', aiStats.newScans.toString()),
            ]),

            pw.SizedBox(height: 15),

            // Pet Metrics
            _buildMetricCard('Pet Statistics', [
              _buildMetricRow('Total Registered Pets', petStats.totalPets.toString()),
              _buildMetricRow('Dogs', '${petStats.dogsCount} (${_calculatePercentage(petStats.dogsCount, petStats.totalPets)}%)'),
              _buildMetricRow('Cats', '${petStats.catsCount} (${_calculatePercentage(petStats.catsCount, petStats.totalPets)}%)'),
              _buildMetricRow('Others', '${petStats.othersCount} (${_calculatePercentage(petStats.othersCount, petStats.totalPets)}%)'),
              _buildMetricRow('New Pets (Period)', petStats.newPets.toString()),
            ]),
          ];
        },
      ),
    );

    // Add top clinics page
    if (topClinics.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Top Performing Clinics'),
                pw.SizedBox(height: 20),
                _buildTopClinicsTable(topClinics),
              ],
            );
          },
        ),
      );
    }

    // Add clinic alerts page
    if (clinicAlerts.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Clinics Needing Attention'),
                pw.SizedBox(height: 20),
                _buildClinicAlertsTable(clinicAlerts),
              ],
            );
          },
        ),
      );
    }

    // Add top diseases page
    if (topDiseases.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Top Detected Diseases'),
                pw.SizedBox(height: 20),
                _buildTopDiseasesTable(topDiseases),
              ],
            );
          },
        ),
      );
    }

    // Add footer to all pages
    return pdf.save();
  }

  static pw.Widget _buildHeader(DateTime generatedAt, String? generatedBy) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PawSense',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple,
              ),
            ),
            pw.Text(
              'System Analytics Dashboard',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated By:',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              generatedBy ?? 'Super Admin',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSystemHealthSection(SystemHealthScore health) {
    PdfColor scoreColor;
    String status;

    if (health.score >= 90) {
      scoreColor = PdfColors.green;
      status = 'Excellent';
    } else if (health.score >= 75) {
      scoreColor = PdfColors.blue;
      status = 'Good';
    } else if (health.score >= 60) {
      scoreColor = PdfColors.orange;
      status = 'Fair';
    } else {
      scoreColor = PdfColors.red;
      status = 'Poor';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: scoreColor, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'System Health Score',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                status,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: scoreColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: scoreColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              '${health.score.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExecutiveSummary(
    UserStats userStats,
    ClinicStats clinicStats,
    AppointmentStats appointmentStats,
    AIUsageStats aiStats,
    PetStats petStats,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Executive Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Users', userStats.totalUsers.toString(), PdfColors.blue),
              _buildSummaryItem('Active Clinics', clinicStats.activeClinics.toString(), PdfColors.green),
              _buildSummaryItem('Appointments', appointmentStats.totalAppointments.toString(), PdfColors.orange),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('AI Scans', aiStats.totalScans.toString(), PdfColors.purple),
              _buildSummaryItem('Registered Pets', petStats.totalPets.toString(), PdfColors.teal),
              _buildSummaryItem('Completion Rate', '${appointmentStats.completionRate.toStringAsFixed(0)}%', PdfColors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color.shade(0.2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.purple, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.purple900,
        ),
      ),
    );
  }

  static pw.Widget _buildMetricCard(String title, List<pw.Widget> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple900,
            ),
          ),
          pw.SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  static pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopClinicsTable(List<ClinicPerformance> clinics) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple50),
          children: [
            _buildTableHeader('Rank'),
            _buildTableHeader('Clinic Name'),
            _buildTableHeader('Appointments'),
            _buildTableHeader('Rating'),
            _buildTableHeader('Completion'),
          ],
        ),
        // Data rows
        ...clinics.map((clinic) => pw.TableRow(
              children: [
                _buildTableCell('#${clinic.rank}'),
                _buildTableCell(clinic.clinicName),
                _buildTableCell(clinic.appointmentCount.toString()),
                _buildTableCell('${clinic.averageRating.toStringAsFixed(1)} ⭐ (${clinic.totalRatings})'),
                _buildTableCell('${clinic.completionRate.toStringAsFixed(0)}%'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildClinicAlertsTable(List<ClinicAlert> alerts) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange50),
          children: [
            _buildTableHeader('Clinic Name'),
            _buildTableHeader('Alert Type'),
            _buildTableHeader('Message'),
          ],
        ),
        // Data rows
        ...alerts.take(10).map((alert) => pw.TableRow(
              children: [
                _buildTableCell(alert.clinicName),
                _buildTableCell(_formatAlertType(alert.alertType)),
                _buildTableCell(alert.message),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTopDiseasesTable(List<DiseaseData> diseases) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.red50),
          children: [
            _buildTableHeader('Disease Name'),
            _buildTableHeader('Count'),
            _buildTableHeader('Percentage'),
          ],
        ),
        // Data rows
        ...diseases.map((disease) => pw.TableRow(
              children: [
                _buildTableCell(disease.diseaseName),
                _buildTableCell(disease.count.toString()),
                _buildTableCell('${disease.percentage.toStringAsFixed(1)}%'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static String _formatAlertType(String type) {
    switch (type) {
      case 'no_appointments':
        return 'No Appointments';
      case 'low_completion':
        return 'Low Completion';
      case 'high_cancellation':
        return 'High Cancellation';
      default:
        return type;
    }
  }

  static String _calculatePercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
  }
}
