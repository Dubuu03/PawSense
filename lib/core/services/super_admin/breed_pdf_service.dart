import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/breeds/pet_breed_model.dart';

class BreedPdfService {
  static Future<Uint8List> generateBreedReport({
    required List<PetBreed> breeds,
    String? speciesFilter,
    String? statusFilter,
    String? searchQuery,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    final stats = _calculateStatistics(breeds);
    
    List<String> appliedFilters = [];
    if (speciesFilter != null && speciesFilter != 'all') appliedFilters.add('Species: $speciesFilter');
    if (statusFilter != null && statusFilter != 'all') appliedFilters.add('Status: $statusFilter');
    if (searchQuery != null && searchQuery.isNotEmpty) appliedFilters.add('Search: "$searchQuery"');
    String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');
    
    // Separate by species
    final dogBreeds = breeds.where((b) => b.species == 'dog').toList();
    final catBreeds = breeds.where((b) => b.species == 'cat').toList();
    
    List<pw.Widget> allWidgets = [];
    
    allWidgets.add(_buildHeader());
    allWidgets.add(pw.SizedBox(height: 20));
    allWidgets.add(_buildReportInfo(filtersText: filtersText, generatedAt: DateTime.now()));
    allWidgets.add(pw.SizedBox(height: 20));
    allWidgets.add(_buildSummaryStatistics(stats));
    allWidgets.add(pw.SizedBox(height: 20));
    
    if (dogBreeds.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Dog Breeds (${dogBreeds.length})', PdfColors.blue700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildBreedsTableChunked(dogBreeds));
      allWidgets.add(pw.SizedBox(height: 20));
    }
    
    if (catBreeds.isNotEmpty) {
      allWidgets.add(_buildSectionHeader('Cat Breeds (${catBreeds.length})', PdfColors.purple700));
      allWidgets.add(pw.SizedBox(height: 10));
      allWidgets.addAll(_buildBreedsTableChunked(catBreeds));
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
          pw.Text('PawSense - Breed Management', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
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
          pw.Text('BREED MANAGEMENT REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Generated:', DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)),
              _buildInfoRow('Report Type:', 'Pet Breeds'),
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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Total', stats['total'].toString(), PdfColors.blue700),
              _buildStatBox('Dogs', stats['dogs'].toString(), PdfColors.blue700),
              _buildStatBox('Cats', stats['cats'].toString(), PdfColors.purple700),
              _buildStatBox('Active', stats['active'].toString(), PdfColors.green700),
              _buildStatBox('Inactive', stats['inactive'].toString(), PdfColors.red700),
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
  
  static List<pw.Widget> _buildBreedsTableChunked(List<PetBreed> breeds) {
    List<pw.Widget> widgets = [];
    const chunkSize = 15;
    
    // Add header only once at the beginning
    widgets.add(_buildTableHeaderRow());
    
    for (int i = 0; i < breeds.length; i += chunkSize) {
      final end = (i + chunkSize < breeds.length) ? i + chunkSize : breeds.length;
      final chunk = breeds.sublist(i, end);
      widgets.add(_buildBreedsTableForChunk(chunk, isFirstChunk: i == 0));
    }
    return widgets;
  }
  
  static pw.Widget _buildTableHeaderRow() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Breed Name'),
            _buildTableHeader('Species'),
            _buildTableHeader('Status'),
            _buildTableHeader('Created'),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildBreedsTableForChunk(List<PetBreed> breeds, {required bool isFirstChunk}) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: PdfColors.grey300),
        right: const pw.BorderSide(color: PdfColors.grey300),
        bottom: const pw.BorderSide(color: PdfColors.grey300),
        verticalInside: const pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: breeds.map((breed) => _buildBreedRow(breed)).toList(),
    );
  }
  
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }
  
  static pw.TableRow _buildBreedRow(PetBreed breed) {
    return pw.TableRow(
      children: [
        _buildTableCell(breed.name),
        _buildTableCell(breed.species.toUpperCase()),
        _buildTableCell(breed.isActive ? 'ACTIVE' : 'INACTIVE', color: breed.isActive ? PdfColors.green700 : PdfColors.red700),
        _buildTableCell(DateFormat('MMM dd, yyyy').format(breed.createdAt)),
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
          pw.Text(generatedBy != null ? 'Generated by: $generatedBy' : 'PawSense Breed Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Page $pageNumber of $totalPages', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }
  
  static Map<String, dynamic> _calculateStatistics(List<PetBreed> breeds) {
    return {
      'total': breeds.length,
      'dogs': breeds.where((b) => b.species == 'dog').length,
      'cats': breeds.where((b) => b.species == 'cat').length,
      'active': breeds.where((b) => b.isActive).length,
      'inactive': breeds.where((b) => !b.isActive).length,
    };
  }
}
