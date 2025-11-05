import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import '../../../core/services/super_admin/disease_area_statistics_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/shared/page_header.dart';
import '../../../core/widgets/shared/pagination_widget.dart';

class DiseaseAreaStatisticsScreen extends StatefulWidget {
  const DiseaseAreaStatisticsScreen({super.key});

  @override
  State<DiseaseAreaStatisticsScreen> createState() => _DiseaseAreaStatisticsScreenState();
}

class _DiseaseAreaStatisticsScreenState extends State<DiseaseAreaStatisticsScreen> {
  bool isLoading = true;
  List<DiseaseAreaStatistic> statistics = [];
  List<DiseaseAreaStatistic> filteredStatistics = [];

  // Filters
  String? selectedRegion;
  String? selectedProvince;
  String? selectedMunicipality;
  String? selectedBarangay;
  String? selectedPetType; // null means 'All'
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  // Available options for dropdowns
  List<Map<String, String>> regions = [];
  List<String> provinces = [];
  List<String> municipalities = [];
  List<String> barangays = [];

  // View mode: 'disease' or 'location'
  String viewMode = 'disease'; // Group by disease by default
  Set<String> expandedGroups = {}; // Track which groups are expanded
  
  // Advanced filters toggle
  bool _showAdvancedFilters = false;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  int get totalPages {
    if (_getDisplayData().isEmpty) return 1;
    return (_getDisplayData().length / itemsPerPage).ceil();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        DiseaseAreaStatisticsService.getDiseaseStatisticsByArea(
          filterProvince: selectedProvince,
          filterMunicipality: selectedMunicipality,
          filterBarangay: selectedBarangay,
          startDate: startDate,
          endDate: endDate,
        ),
        DiseaseAreaStatisticsService.getRegions(),
        DiseaseAreaStatisticsService.getProvinces(),
      ]);

      if (mounted) {
        setState(() {
          statistics = results[0] as List<DiseaseAreaStatistic>;
          filteredStatistics = statistics;
          regions = results[1] as List<Map<String, String>>;
          provinces = results[2] as List<String>;
          isLoading = false;
          currentPage = 1;
        });

        _applyFilters();
      }
    } catch (e) {
      print('Error loading disease statistics: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadProvinces(String? regionCode) async {
    try {
      final provs = await DiseaseAreaStatisticsService.getProvinces(
        regionCode: regionCode,
      );
      if (mounted) {
        setState(() {
          provinces = provs;
          selectedProvince = null;
          municipalities = [];
          selectedMunicipality = null;
        });
      }
    } catch (e) {
      print('Error loading provinces: $e');
    }
  }

  Future<void> _loadMunicipalities(String province) async {
    try {
      final muns = await DiseaseAreaStatisticsService.getMunicipalities(province);
      if (mounted) {
        setState(() {
          municipalities = muns;
          selectedMunicipality = null;
          barangays = [];
          selectedBarangay = null;
        });
      }
    } catch (e) {
      print('Error loading municipalities: $e');
    }
  }

  Future<void> _loadBarangays(String province, String municipality) async {
    try {
      final brgs = await DiseaseAreaStatisticsService.getBarangays(province, municipality);
      if (mounted) {
        setState(() {
          barangays = brgs;
          selectedBarangay = null;
        });
      }
    } catch (e) {
      print('Error loading barangays: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredStatistics = statistics.where((stat) {
        // Pet type filter
        if (selectedPetType != null && stat.petType != selectedPetType) {
          return false;
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final matchesDisease = stat.diseaseName.toLowerCase().contains(query);
          final matchesLocation = stat.fullAddress.toLowerCase().contains(query);
          if (!matchesDisease && !matchesLocation) return false;
        }

        return true;
      }).toList();

      currentPage = 1;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedRegion = null;
      selectedProvince = null;
      selectedMunicipality = null;
      selectedBarangay = null;
      selectedPetType = null;
      startDate = null;
      endDate = null;
      searchQuery = '';
      municipalities = [];
      barangays = [];
    });
    _loadData();
  }

  // Format disease name with proper capitalization
  String _formatDiseaseName(String name) {
    if (name.isEmpty) return name;
    
    // Split by common separators (space, hyphen, underscore)
    final words = name.split(RegExp(r'[\s\-_]+'));
    
    // Capitalize first letter of each word
    final formatted = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return formatted;
  }

  Future<void> _exportToPDF() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generating PDF report...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      // Use filteredStatistics which already has all filters applied
      if (filteredStatistics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();

      // Check if any filters are applied
      final hasFilters = selectedRegion != null || 
          selectedProvince != null || 
          selectedMunicipality != null || 
          selectedBarangay != null || 
          selectedPetType != null ||
          searchQuery.isNotEmpty;

      // Build applied filters text
      List<String> appliedFilters = [];
      if (selectedRegion != null) {
        final regionName = regions.firstWhere((r) => r['code'] == selectedRegion, orElse: () => {'name': selectedRegion!})['name'];
        appliedFilters.add('Region: $regionName');
      }
      if (selectedProvince != null) appliedFilters.add('Province: $selectedProvince');
      if (selectedMunicipality != null) appliedFilters.add('Municipality: $selectedMunicipality');
      if (selectedBarangay != null) appliedFilters.add('Barangay: $selectedBarangay');
      if (selectedPetType != null) appliedFilters.add('Pet Type: ${selectedPetType == 'dog' ? 'Dogs' : 'Cats'}');
      if (searchQuery.isNotEmpty) appliedFilters.add('Search: "$searchQuery"');
      String filtersText = appliedFilters.isEmpty ? 'None' : appliedFilters.join(', ');

      // Calculate summary statistics
      final totalCases = filteredStatistics.fold<int>(0, (sum, stat) => sum + stat.casesCount);
      final uniqueDiseases = filteredStatistics.map((s) => s.diseaseName).toSet().length;
      final uniqueLocations = filteredStatistics.map((s) => s.fullAddress).toSet().length;
      final dogCases = filteredStatistics.where((s) => s.petType == 'dog').fold<int>(0, (sum, stat) => sum + stat.casesCount);
      final catCases = filteredStatistics.where((s) => s.petType == 'cat').fold<int>(0, (sum, stat) => sum + stat.casesCount);

      List<pw.Widget> allWidgets = [];

      // Header
      allWidgets.add(_buildPdfHeader());
      allWidgets.add(pw.SizedBox(height: 20));

      // Report Info
      allWidgets.add(_buildPdfReportInfo(filtersText: filtersText, generatedAt: DateTime.now()));
      allWidgets.add(pw.SizedBox(height: 20));

      // Summary Statistics (only when no filters applied)
      if (!hasFilters) {
        allWidgets.add(_buildPdfSummaryStatistics(
          totalCases: totalCases,
          uniqueDiseases: uniqueDiseases,
          uniqueLocations: uniqueLocations,
          dogCases: dogCases,
          catCases: catCases,
        ));
        allWidgets.add(pw.SizedBox(height: 20));
      }

      // Separate data by pet type if not filtered by pet type
      if (selectedPetType == null) {
        // Show both dogs and cats separately
        final dogStats = filteredStatistics.where((s) => s.petType == 'dog').toList();
        final catStats = filteredStatistics.where((s) => s.petType == 'cat').toList();

        if (dogStats.isNotEmpty) {
          allWidgets.add(_buildPdfSectionHeader('Dog Cases (${dogStats.length} records)', PdfColors.blue700));
          allWidgets.add(pw.SizedBox(height: 10));
          allWidgets.addAll(_buildPdfDataTableChunked(dogStats));
          allWidgets.add(pw.SizedBox(height: 20));
        }

        if (catStats.isNotEmpty) {
          allWidgets.add(_buildPdfSectionHeader('Cat Cases (${catStats.length} records)', PdfColors.orange));
          allWidgets.add(pw.SizedBox(height: 10));
          allWidgets.addAll(_buildPdfDataTableChunked(catStats));
        }
      } else {
        // Show filtered pet type only
        final petTypeLabel = selectedPetType == 'dog' ? 'Dog' : 'Cat';
        final petTypeColor = selectedPetType == 'dog' ? PdfColors.blue700 : PdfColors.orange;
        allWidgets.add(_buildPdfSectionHeader('$petTypeLabel Cases (${filteredStatistics.length} records)', petTypeColor));
        allWidgets.add(pw.SizedBox(height: 10));
        allWidgets.addAll(_buildPdfDataTableChunked(filteredStatistics));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => allWidgets,
          footer: (context) => _buildPdfFooter(
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'disease_area_statistics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      file_downloader.downloadFile(fileName, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF report generated with ${filteredStatistics.length} records'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${filteredStatistics.length} disease area statistics to PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error generating PDF: $e');
    }
  }

  // PDF Helper Methods
  pw.Widget _buildPdfHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PawSense - Disease Area Statistics',
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

  pw.Widget _buildPdfReportInfo({required String filtersText, required DateTime generatedAt}) {
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
            'DISEASE AREA STATISTICS REPORT',
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
              _buildPdfInfoRow('Generated:', DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)),
              _buildPdfInfoRow('Report Type:', 'Geographic Disease Distribution'),
            ],
          ),
          pw.SizedBox(height: 4),
          _buildPdfInfoRow('Filters Applied:', filtersText),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
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

  pw.Widget _buildPdfSummaryStatistics({
    required int totalCases,
    required int uniqueDiseases,
    required int uniqueLocations,
    required int dogCases,
    required int catCases,
  }) {
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
          pw.Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              _buildPdfStatBox('Total Cases', totalCases.toString(), PdfColors.red700),
              _buildPdfStatBox('Unique Diseases', uniqueDiseases.toString(), PdfColors.orange),
              _buildPdfStatBox('Affected Areas', uniqueLocations.toString(), PdfColors.blue700),
              _buildPdfStatBox('Dog Cases', dogCases.toString(), PdfColors.blue700),
              _buildPdfStatBox('Cat Cases', catCases.toString(), PdfColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfStatBox(String label, String value, PdfColor color) {
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

  pw.Widget _buildPdfSectionHeader(String title, PdfColor color) {
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

  List<pw.Widget> _buildPdfDataTableChunked(List<DiseaseAreaStatistic> data) {
    List<pw.Widget> widgets = [];
    
    // Add header only once at the beginning
    widgets.add(_buildPdfTableHeaderRow());
    
    const chunkSize = 20; // Reduced for better pagination
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);
      widgets.add(_buildPdfTableForChunk(chunk));
    }
    return widgets;
  }

  pw.Widget _buildPdfTableHeaderRow() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5), // Disease Name
        1: const pw.FlexColumnWidth(0.8), // Cases
        2: const pw.FlexColumnWidth(1.5), // Barangay
        3: const pw.FlexColumnWidth(1.5), // Municipality
        4: const pw.FlexColumnWidth(1.5), // Province
        5: const pw.FlexColumnWidth(1.2), // Region
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildPdfTableHeader('Disease Name'),
            _buildPdfTableHeader('Cases'),
            _buildPdfTableHeader('Barangay'),
            _buildPdfTableHeader('Municipality'),
            _buildPdfTableHeader('Province'),
            _buildPdfTableHeader('Region'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableForChunk(List<DiseaseAreaStatistic> data) {
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
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.2),
      },
      children: data.map((stat) => _buildPdfDataRow(stat)).toList(),
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
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

  pw.TableRow _buildPdfDataRow(DiseaseAreaStatistic stat) {
    return pw.TableRow(
      children: [
        _buildPdfTableCell(_formatDiseaseName(stat.diseaseName)),
        _buildPdfTableCell(stat.casesCount.toString(), color: PdfColors.blue700),
        _buildPdfTableCell(stat.barangay),
        _buildPdfTableCell(stat.municipality),
        _buildPdfTableCell(stat.province),
        _buildPdfTableCell(stat.region),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {PdfColor? color}) {
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

  pw.Widget _buildPdfFooter({required int pageNumber, required int totalPages}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'PawSense Disease Area Statistics Report',
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



  // Group statistics by disease or location
  List<Map<String, dynamic>> _getGroupedData() {
    if (viewMode == 'disease') {
      // Group by disease name
      final Map<String, List<DiseaseAreaStatistic>> grouped = {};
      for (var stat in filteredStatistics) {
        if (!grouped.containsKey(stat.diseaseName)) {
          grouped[stat.diseaseName] = [];
        }
        grouped[stat.diseaseName]!.add(stat);
      }

      // Convert to list with totals
      return grouped.entries.map((entry) {
        final totalCases = entry.value.fold<int>(0, (sum, stat) => sum + stat.casesCount);
        final affectedAreas = entry.value.length;
        return {
          'groupName': entry.key,
          'totalCases': totalCases,
          'itemCount': affectedAreas,
          'items': entry.value,
          'type': 'disease',
        };
      }).toList()
        ..sort((a, b) => (b['totalCases'] as int).compareTo(a['totalCases'] as int));
    } else {
      // Group by location (Province > Municipality > Barangay)
      final Map<String, List<DiseaseAreaStatistic>> grouped = {};
      for (var stat in filteredStatistics) {
        final locationKey = '${stat.province}, ${stat.region}';
        if (!grouped.containsKey(locationKey)) {
          grouped[locationKey] = [];
        }
        grouped[locationKey]!.add(stat);
      }

      // Convert to list with totals
      return grouped.entries.map((entry) {
        final totalCases = entry.value.fold<int>(0, (sum, stat) => sum + stat.casesCount);
        final uniqueDiseases = entry.value.map((s) => s.diseaseName).toSet().length;
        return {
          'groupName': entry.key,
          'totalCases': totalCases,
          'itemCount': uniqueDiseases,
          'items': entry.value,
          'type': 'location',
        };
      }).toList()
        ..sort((a, b) => (b['totalCases'] as int).compareTo(a['totalCases'] as int));
    }
  }

  List<Map<String, dynamic>> _getDisplayData() {
    return _getGroupedData();
  }

  List<Map<String, dynamic>> get paginatedData {
    final data = _getDisplayData();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return data.sublist(
      startIndex,
      endIndex > data.length ? data.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                kSpacingLarge, kSpacingLarge, kSpacingLarge, 0),
            child: const PageHeader(
              title: 'Disease Statistics by Area',
              subtitle: 'Comprehensive disease data analysis by geographic location',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards (moved to top)
                  _buildSummaryCards(),

                  const SizedBox(height: kSpacingLarge),

                  // Filters and Actions
                  _buildFiltersAndActions(),

                  const SizedBox(height: kSpacingLarge),

                  // Data Table
                  _buildDataTable(),

                  // Pagination - always show if there are results
                  if (!isLoading && filteredStatistics.isNotEmpty) ...[
                    const SizedBox(height: kSpacingLarge),
                    _buildPagination(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndActions() {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Row: Search + Dropdowns + Export
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by disease name or location...',
                    hintStyle: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: kIconSizeMedium),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: kIconSizeSmall),
                            onPressed: () {
                              setState(() => searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Region Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Region',
                  value: selectedRegion ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Regions'},
                    ...regions.map((r) => {'value': r['code']!, 'label': r['name']!}),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRegion = value == 'all' ? null : value;
                      _loadProvinces(selectedRegion);
                    });
                  },
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Province Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Province',
                  value: selectedProvince ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Provinces'},
                    ...provinces.map((p) => {'value': p, 'label': p}),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedProvince = value == 'all' ? null : value;
                      if (selectedProvince != null) {
                        _loadMunicipalities(selectedProvince!);
                      } else {
                        municipalities = [];
                        selectedMunicipality = null;
                      }
                    });
                    _loadData();
                  },
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Pet Type Dropdown
              Expanded(
                child: _buildDropdownFilter(
                  label: 'Pet Type',
                  value: selectedPetType ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Pets'},
                    {'value': 'dog', 'label': 'Dogs'},
                    {'value': 'cat', 'label': 'Cats'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPetType = value == 'all' ? null : value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Advanced Filters Toggle
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  _showAdvancedFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: kIconSizeMedium,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Filters', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.w500)),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _showAdvancedFilters ? AppColors.primary : AppColors.textSecondary,
                  side: BorderSide(
                    color: _showAdvancedFilters ? AppColors.primary : AppColors.border,
                    width: _showAdvancedFilters ? 1.5 : 1,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: kSpacingLarge, vertical: kSpacingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                ),
              ),
              SizedBox(width: kSpacingMedium),

              // Export Button
              ElevatedButton.icon(
                onPressed: isLoading ? null : _exportToPDF,
                icon: Icon(Icons.download_outlined, size: kIconSizeMedium),
                label: Text('Export', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: kSpacingLarge,
                    vertical: kSpacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),

          // Advanced Filters Panel
          if (_showAdvancedFilters) ...[
            SizedBox(height: kSpacingLarge),
            Divider(color: AppColors.border),
            SizedBox(height: kSpacingLarge),
            _buildAdvancedFilters(),
          ],
        ],
      ),
    );
  }
  
  int get _activeFilterCount {
    int count = 0;
    if (selectedMunicipality != null) count++;
    if (selectedBarangay != null) count++;
    if (selectedPetType != null) count++;
    return count;
  }
  
  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
        filled: true,
        fillColor: AppColors.white,
      ),
      style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value']!,
          child: Text(
            item['label']!,
            style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) => onChanged(val!),
    );
  }
  
  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Advanced Location Filters',
              style: kTextStyleRegular.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_activeFilterCount > 0)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all, size: kIconSizeSmall),
                label: Text('Clear All', style: kTextStyleSmall),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
                ),
              ),
          ],
        ),
        SizedBox(height: kSpacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildFilterGroup(
                'Municipality',
                _buildDropdownFilter(
                  label: 'Select Municipality',
                  value: selectedMunicipality ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Municipalities'},
                    ...municipalities.map((m) => {'value': m, 'label': m}),
                  ],
                  onChanged: selectedProvince == null
                      ? (value) {}
                      : (value) {
                          setState(() {
                            selectedMunicipality = value == 'all' ? null : value;
                            if (selectedMunicipality != null && selectedProvince != null) {
                              _loadBarangays(selectedProvince!, selectedMunicipality!);
                            } else {
                              barangays = [];
                              selectedBarangay = null;
                            }
                          });
                          _loadData();
                        },
                ),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildFilterGroup(
                'Barangay',
                _buildDropdownFilter(
                  label: 'Select Barangay',
                  value: selectedBarangay ?? 'all',
                  items: [
                    {'value': 'all', 'label': 'All Barangays'},
                    ...barangays.map((b) => {'value': b, 'label': b}),
                  ],
                  onChanged: selectedMunicipality == null
                      ? (value) {}
                      : (value) {
                          setState(() {
                            selectedBarangay = value == 'all' ? null : value;
                          });
                          _loadData();
                        },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFilterGroup(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: kTextStyleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: kSpacingSmall),
        child,
      ],
    );
  }

  Widget _buildSummaryCards() {
    final totalCases = filteredStatistics.fold<int>(0, (sum, stat) => sum + stat.casesCount);
    final uniqueDiseases = filteredStatistics.map((s) => s.diseaseName).toSet().length;
    final uniqueLocations = filteredStatistics.map((s) => s.fullAddress).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Cases',
            totalCases.toString(),
            Icons.medical_services,
            Colors.red,
          ),
        ),
        const SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            'Unique Diseases',
            uniqueDiseases.toString(),
            Icons.coronavirus,
            Colors.orange,
          ),
        ),
        const SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            'Affected Areas',
            uniqueLocations.toString(),
            Icons.location_on,
            Colors.blue,
          ),
        ),
        const SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            'Data Points',
            filteredStatistics.length.toString(),
            Icons.analytics,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: kSpacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredStatistics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statistics.isEmpty ? Icons.bar_chart_rounded : Icons.search_off_rounded,
                    size: 80,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  statistics.isEmpty ? 'No Data Available' : 'No Results Found',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    statistics.isEmpty 
                        ? 'No assessment results with complete address information found.\nPlease ensure users have completed their address details in their profiles.'
                        : 'No data matches your current filter criteria.\nTry adjusting your filters or clearing them to see all results.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!statistics.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // View mode toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.view_module_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Group by:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'disease',
                      label: const Text('Disease', style: TextStyle(fontWeight: FontWeight.w600)),
                      icon: const Icon(Icons.coronavirus_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 'location',
                      label: const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                      icon: const Icon(Icons.location_on_rounded, size: 18),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      viewMode = newSelection.first;
                      expandedGroups.clear();
                      currentPage = 1;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.textPrimary;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide(color: AppColors.primary, width: 1.5);
                      }
                      return BorderSide(color: AppColors.border.withValues(alpha: 0.3));
                    }),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const Spacer(),
                // Summary info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_list_numbered_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getDisplayData().length} ${viewMode == 'disease' ? 'diseases' : 'locations'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Grouped Data List
          ...paginatedData.map((group) {
            final groupName = group['groupName'] as String;
            final formattedGroupName = viewMode == 'disease' 
                ? _formatDiseaseName(groupName) 
                : groupName;
            final totalCases = group['totalCases'] as int;
            final itemCount = group['itemCount'] as int;
            final items = group['items'] as List<DiseaseAreaStatistic>;
            final isExpanded = expandedGroups.contains(groupName);
            
            return Column(
              children: [
                // Group Header (Clickable)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedGroups.remove(groupName);
                        } else {
                          expandedGroups.add(groupName);
                        }
                      });
                    },
                    hoverColor: AppColors.primary.withValues(alpha: 0.08),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.06),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Expand/Collapse Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Group Name and Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      viewMode == 'disease' ? Icons.coronavirus : Icons.location_city,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        formattedGroupName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      viewMode == 'disease'
                                          ? '$itemCount affected location${itemCount > 1 ? 's' : ''}'
                                          : '$itemCount disease type${itemCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Total Cases Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.medical_services_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$totalCases',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  totalCases > 1 ? 'cases' : 'case',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Expanded Details
                if (isExpanded)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 4,
                        ),
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.only(left: 52, bottom: 12),
                          child: Text(
                            viewMode == 'disease' ? 'Affected Locations' : 'Detected Diseases',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Data List
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isLast = index == items.length - 1;
                          
                          return Container(
                            margin: EdgeInsets.only(
                              left: 52,
                              bottom: isLast ? 0 : 8,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    viewMode == 'disease' 
                                        ? Icons.location_on 
                                        : Icons.coronavirus,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewMode == 'disease'
                                            ? '${item.barangay}, ${item.municipality}'
                                            : _formatDiseaseName(item.diseaseName),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              viewMode == 'disease'
                                                  ? '${item.province}, ${item.region}'
                                                  : '${item.barangay}, ${item.municipality}, ${item.province}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cases Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.15),
                                        AppColors.primary.withValues(alpha: 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.casesCount.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.casesCount > 1 ? 'cases' : 'case',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return PaginationWidget(
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: _getDisplayData().length,
      onPageChanged: (page) {
        setState(() {
          currentPage = page;
        });
      },
      isLoading: false,
    );
  }
}
