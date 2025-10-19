import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/user/user_model.dart';

class UserPdfService {
  /// Generate a professional PDF report for users
  static Future<Uint8List> generateUserReport({
    required List<Map<String, dynamic>> usersWithStatus,
    String? roleFilter,
    String? statusFilter,
    String? searchQuery,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    
    // Calculate summary statistics
    final stats = _calculateStatistics(usersWithStatus);
    
    // Build applied filters text
    List<String> appliedFilters = [];
    if (roleFilter != null && roleFilter != 'All Roles') {
      appliedFilters.add('Role: $roleFilter');
    }
    if (statusFilter != null && statusFilter != 'All Status') {
      appliedFilters.add('Status: $statusFilter');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      appliedFilters.add('Search: "$searchQuery"');
    }
    
    String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');
    
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
    
    // Users Table (chunked to prevent "too many pages" error)
    allWidgets.add(_buildSectionHeader('User Details (${usersWithStatus.length})', PdfColors.blue700));
    allWidgets.add(pw.SizedBox(height: 10));
    allWidgets.addAll(_buildUsersTableChunked(usersWithStatus));
    
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
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PawSense - User Management',
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
            'USER REPORT',
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
              _buildInfoRow('Report Type:', 'All Users'),
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
              _buildStatBox('Pet Owners', stats['petOwners'].toString(), PdfColors.green700),
              _buildStatBox('Clinic Admins', stats['clinicAdmins'].toString(), PdfColors.purple700),
              _buildStatBox('Super Admins', stats['superAdmins'].toString(), PdfColors.orange700),
              _buildStatBox('Active', stats['active'].toString(), PdfColors.teal700),
              _buildStatBox('Suspended', stats['suspended'].toString(), PdfColors.red700),
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
  
  /// Build users table with chunking
  static List<pw.Widget> _buildUsersTableChunked(List<Map<String, dynamic>> usersWithStatus) {
    List<pw.Widget> widgets = [];
    
    if (usersWithStatus.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Text(
            'No users found',
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
    widgets.add(_buildUsersTableHeaderRow());
    
    // Split into chunks of 15
    const chunkSize = 15;
    for (int i = 0; i < usersWithStatus.length; i += chunkSize) {
      final end = (i + chunkSize < usersWithStatus.length) ? i + chunkSize : usersWithStatus.length;
      final chunk = usersWithStatus.sublist(i, end);
      
      widgets.add(_buildUsersTableForChunk(chunk));
    }
    
    return widgets;
  }
  
  /// Build table header row (shown only once)
  static pw.Widget _buildUsersTableHeaderRow() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Name
        1: const pw.FlexColumnWidth(2), // Email
        2: const pw.FlexColumnWidth(1.5), // Role
        3: const pw.FlexColumnWidth(1), // Status
        4: const pw.FlexColumnWidth(1.5), // Created
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Name'),
            _buildTableHeader('Email & Contact'),
            _buildTableHeader('Role'),
            _buildTableHeader('Status'),
            _buildTableHeader('Created'),
          ],
        ),
      ],
    );
  }
  
  /// Build users table for a specific chunk (data rows only)
  static pw.Widget _buildUsersTableForChunk(List<Map<String, dynamic>> usersWithStatus) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: PdfColors.grey300),
        right: const pw.BorderSide(color: PdfColors.grey300),
        bottom: const pw.BorderSide(color: PdfColors.grey300),
        verticalInside: const pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Name
        1: const pw.FlexColumnWidth(2), // Email
        2: const pw.FlexColumnWidth(1.5), // Role
        3: const pw.FlexColumnWidth(1), // Status
        4: const pw.FlexColumnWidth(1.5), // Created
      },
      children: usersWithStatus.map((userMap) => _buildUserRow(userMap)).toList(),
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
  
  /// Build user row
  static pw.TableRow _buildUserRow(Map<String, dynamic> userMap) {
    final user = userMap['user'] as UserModel;
    final isActive = userMap['isActive'] as bool;
    // final suspensionReason = userMap['suspensionReason'] as String?; // Reserved for future use
    
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    
    return pw.TableRow(
      children: [
        // Name
        _buildTableCell(
          fullName.isNotEmpty ? fullName : user.username,
        ),
        
        // Email & Contact
        _buildTableCell(
          '${user.email}\n${user.contactNumber}',
        ),
        
        // Role
        _buildTableCell(
          _formatRole(user.role),
        ),
        
        // Status
        _buildTableCell(
          isActive ? 'ACTIVE' : 'SUSPENDED',
          color: isActive ? PdfColors.green700 : PdfColors.red700,
        ),
        
        // Created
        _buildTableCell(
          DateFormat('MMM dd, yyyy').format(user.createdAt),
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
            generatedBy != null ? 'Generated by: $generatedBy' : 'PawSense User Report',
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
  static Map<String, dynamic> _calculateStatistics(List<Map<String, dynamic>> usersWithStatus) {
    final total = usersWithStatus.length;
    final petOwners = usersWithStatus.where((u) => (u['user'] as UserModel).role == 'pet_owner').length;
    final clinicAdmins = usersWithStatus.where((u) => (u['user'] as UserModel).role == 'clinic_admin').length;
    final superAdmins = usersWithStatus.where((u) => (u['user'] as UserModel).role == 'super_admin').length;
    final active = usersWithStatus.where((u) => u['isActive'] as bool).length;
    final suspended = usersWithStatus.where((u) => !(u['isActive'] as bool)).length;
    
    return {
      'total': total,
      'petOwners': petOwners,
      'clinicAdmins': clinicAdmins,
      'superAdmins': superAdmins,
      'active': active,
      'suspended': suspended,
    };
  }
  
  /// Format role for display
  static String _formatRole(String role) {
    return role.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
