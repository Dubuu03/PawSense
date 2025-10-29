import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/skin_disease/skin_disease_model.dart';

class DiseasePdfService {
  static Future<Uint8List> generateDiseaseReport({
    required List<SkinDiseaseModel> diseases,
    String? detectionMethodFilter,
    String? speciesFilter,
    String? severityFilter,
    String? categoriesFilter,
    String? contagiousFilter,
    String? searchQuery,
    String? generatedBy,
    bool includeSummary = true, // New parameter to control summary display
  }) async {
    final pdf = pw.Document();
    final stats = _calculateStatistics(diseases);
    
    List<String> appliedFilters = [];
    if (detectionMethodFilter != null && detectionMethodFilter.isNotEmpty) appliedFilters.add('Detection: $detectionMethodFilter');
    if (speciesFilter != null && speciesFilter.isNotEmpty) appliedFilters.add('Species: $speciesFilter');
    if (severityFilter != null && severityFilter.isNotEmpty) appliedFilters.add('Severity: $severityFilter');
    if (categoriesFilter != null && categoriesFilter.isNotEmpty) appliedFilters.add('Categories: $categoriesFilter');
    if (contagiousFilter != null && contagiousFilter.isNotEmpty) appliedFilters.add('Contagious: $contagiousFilter');
    if (searchQuery != null && searchQuery.isNotEmpty) appliedFilters.add('Search: "$searchQuery"');
    String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');
    
    // Separate by detection method
    final aiDiseases = diseases.where((d) => d.detectionMethod.toLowerCase() == 'ai').toList();
    final infoDiseases = diseases.where((d) => d.detectionMethod.toLowerCase() == 'info').toList();
    final bothDiseases = diseases.where((d) => d.detectionMethod.toLowerCase() == 'both').toList();
    
    List<pw.Widget> allWidgets = [];
    
    allWidgets.add(_buildHeader());
    allWidgets.add(pw.SizedBox(height: 20));
    allWidgets.add(_buildReportInfo(filtersText: filtersText, generatedAt: DateTime.now()));
    allWidgets.add(pw.SizedBox(height: 20));
    
    // Summary Statistics Section (only if includeSummary is true)
    if (includeSummary) {
      allWidgets.add(_buildSummaryStatistics(stats));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    if (aiDiseases.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('AI Detection (${aiDiseases.length})', PdfColors.blue700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildDiseasesTableChunked(aiDiseases));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    if (infoDiseases.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Info Only (${infoDiseases.length})', PdfColors.green700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildDiseasesTableChunked(infoDiseases));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    if (bothDiseases.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Both Detection Methods (${bothDiseases.length})', PdfColors.purple700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildDiseasesTableChunked(bothDiseases));
    }
    
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
  
  static pw.Widget _buildHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PawSense - Disease Management', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          pw.Text('Super Admin Report', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildReportInfo({required String filtersText, required DateTime generatedAt}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DISEASE MANAGEMENT REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Generated:', DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)),
              _buildInfoRow('Report Type:', 'Disease Database'),
            ],
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow('Filters Applied:', filtersText),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        pw.SizedBox(width: 4),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }
  
  static pw.Widget _buildSummaryStatistics(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              _buildStatBox('Total', stats['total'].toString(), PdfColors.blue700),
              _buildStatBox('AI Detection', stats['aiDetection'].toString(), PdfColors.blue700),
              _buildStatBox('Info Only', stats['infoOnly'].toString(), PdfColors.green700),
              _buildStatBox('Mild', stats['mild'].toString(), PdfColors.green700),
              _buildStatBox('Moderate', stats['moderate'].toString(), PdfColors.orange),
              _buildStatBox('Severe', stats['severe'].toString(), PdfColors.red700),
              _buildStatBox('Contagious', stats['contagious'].toString(), PdfColors.red700),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }
  
  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: color, width: 1.5)),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 16, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2))),
          pw.SizedBox(width: 8),
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
  
  static List<pw.Widget> _buildDiseasesTableChunked(List<SkinDiseaseModel> diseases) {
    List<pw.Widget> widgets = [];
    
    // Add header only once at the beginning
    widgets.add(_buildDiseasesTableHeaderRow());
    
    const chunkSize = 15;
    for (int i = 0; i < diseases.length; i += chunkSize) {
      final end = (i + chunkSize < diseases.length) ? i + chunkSize : diseases.length;
      final chunk = diseases.sublist(i, end);
      widgets.add(_buildDiseasesTableForChunk(chunk));
    }
    return widgets;
  }
  
  static pw.Widget _buildDiseasesTableHeaderRow() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Disease Name'),
            _buildTableHeader('Species'),
            _buildTableHeader('Severity'),
            _buildTableHeader('Contagious'),
            _buildTableHeader('Categories'),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildDiseasesTableForChunk(List<SkinDiseaseModel> diseases) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: PdfColors.grey300),
        right: const pw.BorderSide(color: PdfColors.grey300),
        bottom: const pw.BorderSide(color: PdfColors.grey300),
        verticalInside: const pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: diseases.map((disease) => _buildDiseaseRow(disease)).toList(),
    );
  }
  
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }
  
  static pw.TableRow _buildDiseaseRow(SkinDiseaseModel disease) {
    PdfColor severityColor = PdfColors.grey700;
    if (disease.severity.toLowerCase() == 'low') severityColor = PdfColors.green700;
    else if (disease.severity.toLowerCase() == 'moderate') severityColor = PdfColors.orange;
    else if (disease.severity.toLowerCase() == 'high') severityColor = PdfColors.red700;
    
    String categories = disease.categories.take(2).join(', ');
    if (disease.categories.length > 2) {
      categories += ' +${disease.categories.length - 2}';
    }
    
    return pw.TableRow(
      children: [
        _buildTableCell(disease.name),
        _buildTableCell(disease.species.join(', ').toUpperCase()),
        _buildTableCell(disease.severity.toUpperCase(), color: severityColor),
        _buildTableCell(disease.isContagious ? 'YES' : 'NO', color: disease.isContagious ? PdfColors.red700 : PdfColors.green700),
        _buildTableCell(categories),
      ],
    );
  }
  
  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 7, color: color ?? PdfColors.grey900)),
    );
  }
  
  static pw.Widget _buildFooter({required int pageNumber, required int totalPages, String? generatedBy}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(generatedBy != null ? 'Generated by: $generatedBy' : 'PawSense Disease Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Page $pageNumber of $totalPages', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }
  
  static Map<String, dynamic> _calculateStatistics(List<SkinDiseaseModel> diseases) {
    return {
      'total': diseases.length,
      'aiDetection': diseases.where((d) => d.detectionMethod.toLowerCase() == 'ai').length,
      'infoOnly': diseases.where((d) => d.detectionMethod.toLowerCase() == 'info').length,
      'mild': diseases.where((d) => d.severity.toLowerCase() == 'low').length,
      'moderate': diseases.where((d) => d.severity.toLowerCase() == 'moderate').length,
      'severe': diseases.where((d) => d.severity.toLowerCase() == 'high').length,
      'contagious': diseases.where((d) => d.isContagious).length,
    };
  }
}
