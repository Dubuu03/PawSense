import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/clinic/clinic_registration_model.dart';

class ClinicPdfService {
  /// Generate a professional PDF report for clinics
  static Future<Uint8List> generateClinicReport({
    required List<ClinicRegistration> clinics,
    String? statusFilter,
    String? searchQuery,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    
    // Calculate summary statistics
    final stats = _calculateStatistics(clinics);
    
    // Build applied filters text
    List<String> appliedFilters = [];
    if (statusFilter != null && statusFilter != 'All Status' && statusFilter.isNotEmpty) {
      appliedFilters.add('Status: $statusFilter');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      appliedFilters.add('Search: "$searchQuery"');
    }
    
    String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');
    
    // Separate clinics by status
    final pendingClinics = clinics.where((c) => c.status == ClinicStatus.pending).toList();
    final approvedClinics = clinics.where((c) => c.status == ClinicStatus.approved).toList();
    final rejectedClinics = clinics.where((c) => c.status == ClinicStatus.rejected).toList();
    final suspendedClinics = clinics.where((c) => c.status == ClinicStatus.suspended).toList();
    
    // Build all widgets for the multi-page document
    List<pw.Widget> allWidgets = [];
    
    // Header Section
    allWidgets.add(_buildHeader());
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Report Info Section
    allWidgets.add(_buildReportInfo(
      filtersText: filtersText,
      generatedAt: DateTime.now(),
    ));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Summary Statistics Section
    allWidgets.add(_buildSummaryStatistics(stats));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Pending Clinics Section
    if (pendingClinics.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Pending Clinics (${pendingClinics.length})', PdfColors.orange700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildClinicsTableChunked(pendingClinics));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    // Approved Clinics Section
    if (approvedClinics.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Approved Clinics (${approvedClinics.length})', PdfColors.green700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildClinicsTableChunked(approvedClinics));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    // Rejected Clinics Section
    if (rejectedClinics.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Rejected Clinics (${rejectedClinics.length})', PdfColors.red700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildClinicsTableChunked(rejectedClinics));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    // Suspended Clinics Section
    if (suspendedClinics.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Suspended Clinics (${suspendedClinics.length})', PdfColors.grey700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildClinicsTableChunked(suspendedClinics));
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
  
  /// Build header section
  static pw.Widget _buildHeader() {
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
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PawSense - Clinic Management',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Super Admin Report',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build report info section
  static pw.Widget _buildReportInfo({
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
            'CLINIC REGISTRATION REPORT',
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
              _buildInfoRow('Generated:', DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)),
              _buildInfoRow('Report Type:', 'All Registrations'),
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
              _buildStatBox('Approved', stats['approved'].toString(), PdfColors.green700),
              _buildStatBox('Rejected', stats['rejected'].toString(), PdfColors.red700),
              _buildStatBox('Suspended', stats['suspended'].toString(), PdfColors.grey700),
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
  
  /// Build section header
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
  
  /// Build clinics table with chunking
  static List<pw.Widget> _buildClinicsTableChunked(List<ClinicRegistration> clinics) {
    List<pw.Widget> widgets = [];
    
    if (clinics.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Text(
            'No clinics in this category',
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
    
    // Add header only once at the beginning
    widgets.add(_buildClinicsTableHeaderRow());
    
    // Split into chunks of 15
    const chunkSize = 15;
    for (int i = 0; i < clinics.length; i += chunkSize) {
      final end = (i + chunkSize < clinics.length) ? i + chunkSize : clinics.length;
      final chunk = clinics.sublist(i, end);
      
      widgets.add(_buildClinicsTableForChunk(chunk));
    }
    
    return widgets;
  }
  
  /// Build table header row (shown only once per section)
  static pw.Widget _buildClinicsTableHeaderRow() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Clinic Name
        1: const pw.FlexColumnWidth(1.5), // Admin
        2: const pw.FlexColumnWidth(2), // Contact
        3: const pw.FlexColumnWidth(1.5), // License
        4: const pw.FlexColumnWidth(1.5), // Application Date
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Clinic Name'),
            _buildTableHeader('Admin Name'),
            _buildTableHeader('Contact'),
            _buildTableHeader('License Number'),
            _buildTableHeader('Applied'),
          ],
        ),
      ],
    );
  }
  
  /// Build clinics table for a specific chunk (data rows only)
  static pw.Widget _buildClinicsTableForChunk(List<ClinicRegistration> clinics) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: PdfColors.grey300),
        right: const pw.BorderSide(color: PdfColors.grey300),
        bottom: const pw.BorderSide(color: PdfColors.grey300),
        verticalInside: const pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Clinic Name
        1: const pw.FlexColumnWidth(1.5), // Admin
        2: const pw.FlexColumnWidth(2), // Contact
        3: const pw.FlexColumnWidth(1.5), // License
        4: const pw.FlexColumnWidth(1.5), // Application Date
      },
      children: clinics.map((clinic) => _buildClinicRow(clinic)).toList(),
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
  
  /// Build clinic row
  static pw.TableRow _buildClinicRow(ClinicRegistration clinic) {
    return pw.TableRow(
      children: [
        // Clinic Name
        _buildTableCell(clinic.clinicName),
        
        // Admin Name
        _buildTableCell(clinic.adminName ?? 'N/A'),
        
        // Contact
        _buildTableCell(
          '${clinic.email ?? 'N/A'}\n${clinic.phone ?? 'N/A'}',
        ),
        
        // License Number
        _buildTableCell(clinic.licenseNumber ?? 'N/A'),
        
        // Application Date
        _buildTableCell(
          DateFormat('MMM dd, yyyy').format(clinic.applicationDate),
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
            generatedBy != null ? 'Generated by: $generatedBy' : 'PawSense Clinic Report',
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
  static Map<String, dynamic> _calculateStatistics(List<ClinicRegistration> clinics) {
    final total = clinics.length;
    final pending = clinics.where((c) => c.status == ClinicStatus.pending).length;
    final approved = clinics.where((c) => c.status == ClinicStatus.approved).length;
    final rejected = clinics.where((c) => c.status == ClinicStatus.rejected).length;
    final suspended = clinics.where((c) => c.status == ClinicStatus.suspended).length;
    
    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'suspended': suspended,
    };
  }
}
