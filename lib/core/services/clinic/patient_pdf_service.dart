import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pawsense/core/services/clinic/patient_record_service.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';

class PatientPdfService {
  /// Generate a professional PDF report for a patient
  static Future<Uint8List> generatePatientReport({
    required PatientRecord patient,
    required List<AppointmentBooking> appointmentHistory,
    required String clinicName,
    String? clinicAddress,
    Uint8List? clinicLogo,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    
    // Calculate appointment statistics
    final totalAppointments = appointmentHistory.length;
    final completedAppointments = appointmentHistory
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final cancelledAppointments = appointmentHistory
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;
    final pendingAppointments = appointmentHistory
        .where((a) => a.status == AppointmentStatus.pending || 
                      a.status == AppointmentStatus.confirmed)
        .length;
    
    // Get first and last visit dates
    DateTime? firstVisit;
    DateTime? lastVisit;
    if (appointmentHistory.isNotEmpty) {
      final sortedAppointments = List<AppointmentBooking>.from(appointmentHistory)
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      firstVisit = sortedAppointments.first.appointmentDate;
      lastVisit = sortedAppointments.last.appointmentDate;
    }
    
    // Build all widgets for the multi-page document
    List<pw.Widget> allWidgets = [];
    
    // Header Section
    allWidgets.add(_buildHeader(
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      clinicLogo: clinicLogo,
    ));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Patient Information Section
    allWidgets.add(_buildPatientInfo(patient));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Owner Information Section
    allWidgets.add(_buildOwnerInfo(patient));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Visit Statistics Section
    allWidgets.add(_buildVisitStatistics(
      totalAppointments: totalAppointments,
      completedAppointments: completedAppointments,
      cancelledAppointments: cancelledAppointments,
      pendingAppointments: pendingAppointments,
      firstVisit: firstVisit,
      lastVisit: lastVisit,
    ));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Appointment History Section
    if (appointmentHistory.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Appointment History'));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildAppointmentHistoryTable(appointmentHistory));
    }
    
    // Add all widgets to a multi-page document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => allWidgets,
        footer: (context) => _buildFooter(
          context,
          generatedBy: generatedBy,
        ),
      ),
    );
    
    return pdf.save();
  }
  
  /// Build header with clinic information
  static pw.Widget _buildHeader({
    required String clinicName,
    String? clinicAddress,
    Uint8List? clinicLogo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.purple700, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clinicName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                if (clinicAddress != null && clinicAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    clinicAddress,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Text(
                  'Patient Medical Record',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple700,
                  ),
                ),
              ],
            ),
          ),
          if (clinicLogo != null)
            pw.Container(
              width: 60,
              height: 60,
              child: pw.Image(pw.MemoryImage(clinicLogo)),
            ),
        ],
      ),
    );
  }
  
  /// Build patient information section
  static pw.Widget _buildPatientInfo(PatientRecord patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Name', patient.petName),
              ),
              pw.Expanded(
                child: _buildInfoRow('Type', patient.petType),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Breed', patient.breed),
              ),
              pw.Expanded(
                child: _buildInfoRow('Age', patient.ageString),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Weight', patient.weightString),
              ),
              pw.Expanded(
                child: _buildInfoRow('Health Status', _getHealthStatusText(patient.healthStatus)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build owner information section
  static pw.Widget _buildOwnerInfo(PatientRecord patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Owner Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Name', patient.ownerName),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Phone', patient.ownerPhone),
              ),
              pw.Expanded(
                child: _buildInfoRow('Email', patient.ownerEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build visit statistics section
  static pw.Widget _buildVisitStatistics({
    required int totalAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required int pendingAppointments,
    DateTime? firstVisit,
    DateTime? lastVisit,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.purple300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Visit Statistics',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Total Visits', totalAppointments.toString(), PdfColors.purple700),
              _buildStatCard('Completed', completedAppointments.toString(), PdfColors.green700),
              _buildStatCard('Pending', pendingAppointments.toString(), PdfColors.orange700),
              _buildStatCard('Cancelled', cancelledAppointments.toString(), PdfColors.red700),
            ],
          ),
          if (firstVisit != null || lastVisit != null) ...[
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                if (firstVisit != null)
                  pw.Expanded(
                    child: _buildInfoRow('First Visit', DateFormat('MMM dd, yyyy').format(firstVisit)),
                  ),
                if (lastVisit != null)
                  pw.Expanded(
                    child: _buildInfoRow('Last Visit', DateFormat('MMM dd, yyyy').format(lastVisit)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build section header
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple700,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }
  
  /// Build appointment history table
  static List<pw.Widget> _buildAppointmentHistoryTable(List<AppointmentBooking> appointments) {
    // Sort appointments by date (most recent first)
    final sortedAppointments = List<AppointmentBooking>.from(appointments)
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    
    List<pw.Widget> widgets = [];
    
    // Build single consolidated table
    final List<pw.TableRow> tableRows = [];
    
    // Add header row
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.purple700),
        children: [
          _buildTableHeaderCell('Date', isHeader: true),
          _buildTableHeaderCell('Time', isHeader: true),
          _buildTableHeaderCell('Service / Reason', isHeader: true),
          _buildTableHeaderCell('Status', isHeader: true),
        ],
      ),
    );
    
    // Build data rows
    for (var i = 0; i < sortedAppointments.length; i++) {
      final appointment = sortedAppointments[i];
      final isEven = i % 2 == 0;
      
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : PdfColors.grey50,
          ),
          children: [
            _buildTableCell(DateFormat('MMM dd, yyyy').format(appointment.appointmentDate)),
            _buildTableCell(appointment.appointmentTime),
            _buildTableCell(appointment.serviceName),
            _buildTableCell(_getStatusText(appointment.status)),
          ],
        ),
      );
      
      // Add notes row if available
      if (appointment.notes.isNotEmpty) {
        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey50 : PdfColors.grey100,
            ),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Notes: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        appointment.notes,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(), // Empty cell
              pw.Container(), // Empty cell
              pw.Container(), // Empty cell
            ],
          ),
        );
      }
      
      // Add clinic evaluation row if available
      if (appointment.status == AppointmentStatus.completed) {
        final hasDiagnosis = appointment.diagnosis != null && appointment.diagnosis!.trim().isNotEmpty;
        final hasTreatment = appointment.treatment != null && appointment.treatment!.trim().isNotEmpty;
        final hasPrescription = appointment.prescription != null && appointment.prescription!.trim().isNotEmpty;
        
        if (hasDiagnosis || hasTreatment || hasPrescription) {
          tableRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Clinic Evaluation:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (hasDiagnosis) ...[
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Diagnosis: ',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                appointment.diagnosis!,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      if (hasTreatment) ...[
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Treatment: ',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                appointment.treatment!,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      if (hasPrescription) ...[
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Prescription: ',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                appointment.prescription!,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Container(), // Empty cell
                pw.Container(), // Empty cell
                pw.Container(), // Empty cell
              ],
            ),
          );
        }
      }
    }
    
    // Add single table with all rows
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(3),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: tableRows,
      ),
    );
    
    return widgets;
  }
  
  /// Build info row
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build stat card
  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build table header cell
  static pw.Widget _buildTableHeaderCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: isHeader ? PdfColors.white : PdfColors.purple900,
        ),
      ),
    );
  }
  
  /// Build table cell
  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey800,
        ),
      ),
    );
  }
  
  /// Build footer
  static pw.Widget _buildFooter(pw.Context context, {String? generatedBy}) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(now);
    
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedBy != null 
                ? 'Generated by $generatedBy - $dateStr'
                : 'Generated on $dateStr',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get health status text
  static String _getHealthStatusText(PatientHealthStatus status) {
    switch (status) {
      case PatientHealthStatus.healthy:
        return 'Healthy';
      case PatientHealthStatus.treatment:
        return 'Under Treatment';
      case PatientHealthStatus.scheduled:
        return 'Visit Scheduled';
      default:
        return 'Unknown';
    }
  }
  
  /// Get status text
  static String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
