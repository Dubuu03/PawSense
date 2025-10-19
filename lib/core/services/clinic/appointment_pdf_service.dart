import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/clinic/appointment_models.dart' as AppointmentModels;

class AppointmentPdfService {
  /// Generate a professional PDF report for appointments
  static Future<Uint8List> generateAppointmentReport({
    required List<AppointmentModels.Appointment> appointments,
    required String clinicName,
    required String clinicAddress,
    Uint8List? clinicLogo,
    String? statusFilter,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? petTypeFilter,
    String? breedFilter,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    
    // Calculate summary statistics
    final stats = _calculateStatistics(appointments);
    
    // Format date range
    String dateRange = 'All Time';
    if (startDate != null || endDate != null) {
      final start = startDate != null ? DateFormat('MMM dd, yyyy').format(startDate) : 'Start';
      final end = endDate != null ? DateFormat('MMM dd, yyyy').format(endDate) : 'Now';
      dateRange = '$start - $end';
    }
    
    // Build applied filters text
    List<String> appliedFilters = [];
    if (statusFilter != null && statusFilter != 'All Status') {
      appliedFilters.add('Status: $statusFilter');
    }
    if (petTypeFilter != null) {
      appliedFilters.add('Pet Type: $petTypeFilter');
    }
    if (breedFilter != null) {
      appliedFilters.add('Breed: $breedFilter');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      appliedFilters.add('Search: "$searchQuery"');
    }
    
    String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');
    
    // Separate appointments by pet type
    final dogAppointments = appointments.where((a) => a.pet.type.toLowerCase() == 'dog').toList();
    final catAppointments = appointments.where((a) => a.pet.type.toLowerCase() == 'cat').toList();
    final otherAppointments = appointments.where((a) {
      final type = a.pet.type.toLowerCase();
      return type != 'dog' && type != 'cat';
    }).toList();
    
    // Build all widgets for the multi-page document
    List<pw.Widget> allWidgets = [];
    
    // Header Section
    allWidgets.add(_buildHeader(
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      clinicLogo: clinicLogo,
    ));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Report Info Section
    allWidgets.add(_buildReportInfo(
      dateRange: dateRange,
      filtersText: filtersText,
      generatedAt: DateTime.now(),
    ));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Summary Statistics Section
    allWidgets.add(_buildSummaryStatistics(stats));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Dog Appointments Section
    if (dogAppointments.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Dog Appointments (${dogAppointments.length})', PdfColors.blue700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildAppointmentsTableChunked(dogAppointments));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    // Cat Appointments Section
    if (catAppointments.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Cat Appointments (${catAppointments.length})', PdfColors.purple700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildAppointmentsTableChunked(catAppointments));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    // Other Animals Section
    if (otherAppointments.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Other Animals (${otherAppointments.length})', PdfColors.green700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildAppointmentsTableChunked(otherAppointments));
    }
    
    // Add single multi-page with all widgets
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => allWidgets,
        footer: (context) => _buildFooter(
          pageNumber: context.pageNumber,
          totalPages: context.pagesCount,
          generatedBy: generatedBy,
        ),
      ),
    );
    
    return pdf.save();
  }
  
  /// Build header section with logo and clinic info
  static pw.Widget _buildHeader({
    required String clinicName,
    required String clinicAddress,
    Uint8List? clinicLogo,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue700,
            width: 2,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Clinic Info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clinicName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  clinicAddress,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          
          // Logo (if available)
          if (clinicLogo != null)
            pw.Container(
              width: 60,
              height: 60,
              child: pw.Image(
                pw.MemoryImage(clinicLogo),
                fit: pw.BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build report info section
  static pw.Widget _buildReportInfo({
    required String dateRange,
    required String filtersText,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'APPOINTMENT REPORT',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Date Range:', dateRange),
              _buildInfoRow('Generated:', DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)),
            ],
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow('Filters Applied:', filtersText),
        ],
      ),
    );
  }
  
  /// Build info row helper
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
  
  /// Build summary statistics section
  static pw.Widget _buildSummaryStatistics(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary Statistics',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('Total', stats['total'].toString(), PdfColors.blue700),
              _buildStatBox('Pending', stats['pending'].toString(), PdfColors.orange700),
              _buildStatBox('Confirmed', stats['confirmed'].toString(), PdfColors.purple700),
              _buildStatBox('Completed', stats['completed'].toString(), PdfColors.green700),
              _buildStatBox('Cancelled', stats['cancelled'].toString(), PdfColors.red700),
              _buildStatBox('Follow-up', stats['followUp'].toString(), PdfColors.indigo700),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildPercentageRow('Completion Rate', stats['completionRate']),
              _buildPercentageRow('Cancellation Rate', stats['cancellationRate']),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build stat box helper
  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
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
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
  
  /// Build percentage row helper
  static pw.Widget _buildPercentageRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
  
  /// Build section header for pet type groups
  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 16,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build appointments table with chunking to avoid "too many pages" error
  /// Splits large datasets into smaller tables
  static List<pw.Widget> _buildAppointmentsTableChunked(List<AppointmentModels.Appointment> appointments) {
    List<pw.Widget> widgets = [];
    
    if (appointments.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Text(
            'No appointments in this category',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
      return widgets;
    }
    
    // Split appointments into chunks of 15 to prevent too many pages error
    const chunkSize = 15;
    for (int i = 0; i < appointments.length; i += chunkSize) {
      final end = (i + chunkSize < appointments.length) ? i + chunkSize : appointments.length;
      final chunk = appointments.sublist(i, end);
      
      // Add spacing between chunks (except for the first one)
      if (i > 0) {
        widgets.add(pw.SizedBox(height: 10));
      }
      
      // Build table for this chunk
      widgets.add(_buildAppointmentsTableForChunk(chunk, i + 1, appointments.length));
    }
    
    return widgets;
  }
  
  /// Build appointments table for a specific chunk
  static pw.Widget _buildAppointmentsTableForChunk(
    List<AppointmentModels.Appointment> appointments,
    int startIndex,
    int totalCount,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // Date & Time
        1: const pw.FlexColumnWidth(1.2), // Pet
        2: const pw.FlexColumnWidth(1.2), // Owner
        3: const pw.FlexColumnWidth(1.5), // Reason
        4: const pw.FlexColumnWidth(1), // Status
        5: const pw.FlexColumnWidth(1.2), // Details
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Date & Time'),
            _buildTableHeader('Pet Info'),
            _buildTableHeader('Owner'),
            _buildTableHeader('Reason'),
            _buildTableHeader('Status'),
            _buildTableHeader('Additional Info'),
          ],
        ),
        
        // Data Rows
        ...appointments.map((appointment) => _buildAppointmentRow(appointment)),
      ],
    );
  }
  
  /// Build table header cell
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }
  
  /// Build appointment row
  static pw.TableRow _buildAppointmentRow(AppointmentModels.Appointment appointment) {
    return pw.TableRow(
      children: [
        // Date & Time
        _buildTableCell(
          '${appointment.date}\n${appointment.time}',
        ),
        
        // Pet Info
        _buildTableCell(
          '${appointment.pet.name}\n${appointment.pet.type}${appointment.pet.breed != null ? ' - ${appointment.pet.breed}' : ''}',
        ),
        
        // Owner
        _buildTableCell(
          '${appointment.owner.name}\n${appointment.owner.phone}',
        ),
        
        // Reason
        _buildTableCell(
          appointment.diseaseReason,
        ),
        
        // Status
        _buildTableCell(
          _formatStatus(appointment.status),
          color: _getStatusColor(appointment.status),
        ),
        
        // Additional Info
        _buildTableCell(
          _getAdditionalInfo(appointment),
        ),
      ],
    );
  }
  
  /// Build table cell
  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          color: color ?? PdfColors.grey900,
        ),
      ),
    );
  }
  
  /// Get additional info for appointment
  static String _getAdditionalInfo(AppointmentModels.Appointment appointment) {
    List<String> info = [];
    
    // Booked at
    info.add('Booked: ${DateFormat('MMM dd, HH:mm').format(appointment.createdAt)}');
    
    // For completed appointments
    if (appointment.status == AppointmentModels.AppointmentStatus.completed) {
      if (appointment.diagnosis != null && appointment.diagnosis!.isNotEmpty) {
        info.add('Diagnosis: ${appointment.diagnosis}');
      }
      if (appointment.needsFollowUp == true && appointment.followUpDate != null) {
        info.add('Follow-up: ${appointment.followUpDate}');
      }
      if (appointment.completedAt != null) {
        info.add('Done: ${DateFormat('MMM dd, HH:mm').format(appointment.completedAt!)}');
      }
    }
    
    // For cancelled appointments
    if (appointment.status == AppointmentModels.AppointmentStatus.cancelled) {
      if (appointment.cancelReason != null && appointment.cancelReason!.isNotEmpty) {
        info.add('Reason: ${appointment.cancelReason}');
      }
      if (appointment.cancelledAt != null) {
        info.add('Cancelled: ${DateFormat('MMM dd, HH:mm').format(appointment.cancelledAt!)}');
      }
    }
    
    return info.join('\n');
  }
  
  /// Build footer
  static pw.Widget _buildFooter({
    required int pageNumber,
    required int totalPages,
    String? generatedBy,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedBy != null ? 'Generated by: $generatedBy' : 'PawSense Appointment Report',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page $pageNumber of $totalPages',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Calculate statistics
  static Map<String, dynamic> _calculateStatistics(List<AppointmentModels.Appointment> appointments) {
    final total = appointments.length;
    final pending = appointments.where((a) => a.status == AppointmentModels.AppointmentStatus.pending).length;
    final confirmed = appointments.where((a) => a.status == AppointmentModels.AppointmentStatus.confirmed).length;
    final completed = appointments.where((a) => a.status == AppointmentModels.AppointmentStatus.completed).length;
    final cancelled = appointments.where((a) => a.status == AppointmentModels.AppointmentStatus.cancelled).length;
    final followUp = appointments.where((a) => a.isFollowUp == true).length;
    
    final completionRate = total > 0 ? ((completed / total) * 100).toStringAsFixed(1) + '%' : '0%';
    final cancellationRate = total > 0 ? ((cancelled / total) * 100).toStringAsFixed(1) + '%' : '0%';
    
    return {
      'total': total,
      'pending': pending,
      'confirmed': confirmed,
      'completed': completed,
      'cancelled': cancelled,
      'followUp': followUp,
      'completionRate': completionRate,
      'cancellationRate': cancellationRate,
    };
  }
  
  /// Format status for display
  static String _formatStatus(AppointmentModels.AppointmentStatus status) {
    return status.name.toUpperCase();
  }
  
  /// Get status color
  static PdfColor _getStatusColor(AppointmentModels.AppointmentStatus status) {
    switch (status) {
      case AppointmentModels.AppointmentStatus.pending:
        return PdfColors.orange700;
      case AppointmentModels.AppointmentStatus.confirmed:
        return PdfColors.purple700;
      case AppointmentModels.AppointmentStatus.completed:
        return PdfColors.green700;
      case AppointmentModels.AppointmentStatus.cancelled:
        return PdfColors.red700;
    }
  }
}
