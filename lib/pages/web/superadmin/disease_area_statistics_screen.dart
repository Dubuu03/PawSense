import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import '../../../core/services/super_admin/disease_area_statistics_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/shared/page_header.dart';

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
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  // Available options for dropdowns
  List<Map<String, String>> regions = [];
  List<String> provinces = [];
  List<String> municipalities = [];
  List<String> barangays = [];

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 20;
  int get totalPages => (filteredStatistics.length / itemsPerPage).ceil();

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
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: AppColors.error,
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
      startDate = null;
      endDate = null;
      searchQuery = '';
      municipalities = [];
      barangays = [];
    });
    _loadData();
  }

  Future<void> _exportToPDF() async {
    try {
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

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy');

      // Split data into pages (30 rows per page)
      final itemsPerPdfPage = 30;
      for (var i = 0; i < filteredStatistics.length; i += itemsPerPdfPage) {
        final pageData = filteredStatistics.skip(i).take(itemsPerPdfPage).toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(20),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Disease Statistics by Area',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${dateFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Filters info
                  if (selectedRegion != null || selectedProvince != null || 
                      selectedMunicipality != null || selectedBarangay != null || 
                      startDate != null || endDate != null)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Filters Applied:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          if (selectedRegion != null)
                            pw.Text('Region: ${regions.firstWhere((r) => r['code'] == selectedRegion)['name']}'),
                          if (selectedProvince != null)
                            pw.Text('Province: $selectedProvince'),
                          if (selectedMunicipality != null)
                            pw.Text('Municipality: $selectedMunicipality'),
                          if (selectedBarangay != null)
                            pw.Text('Barangay: $selectedBarangay'),
                          if (startDate != null && endDate != null)
                            pw.Text('Date Range: ${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}'),
                        ],
                      ),
                    ),
                  pw.SizedBox(height: 10),

                  // Table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                      5: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _buildTableHeader('Disease Name'),
                          _buildTableHeader('Cases'),
                          _buildTableHeader('Barangay'),
                          _buildTableHeader('Municipality'),
                          _buildTableHeader('Province'),
                          _buildTableHeader('Region'),
                        ],
                      ),
                      // Data rows
                      ...pageData.map((stat) => pw.TableRow(
                        children: [
                          _buildTableCell(stat.diseaseName),
                          _buildTableCell(stat.casesCount.toString()),
                          _buildTableCell(stat.barangay),
                          _buildTableCell(stat.municipality),
                          _buildTableCell(stat.province),
                          _buildTableCell(stat.region),
                        ],
                      )),
                    ],
                  ),

                  pw.Spacer(),

                  // Footer
                  pw.Text(
                    'Page ${(i ~/ itemsPerPdfPage) + 1} of ${(filteredStatistics.length / itemsPerPdfPage).ceil()} | Total Records: ${filteredStatistics.length}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await pdf.save();
      final fileName = 'disease_area_statistics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await file_downloader.downloadFile(fileName, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF exported successfully: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error exporting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  List<DiseaseAreaStatistic> get paginatedData {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return filteredStatistics.sublist(
      startIndex,
      endIndex > filteredStatistics.length ? filteredStatistics.length : endIndex,
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
                  // Filters and Actions
                  _buildFiltersAndActions(),

                  const SizedBox(height: kSpacingLarge),

                  // Summary Cards
                  _buildSummaryCards(),

                  const SizedBox(height: kSpacingLarge),

                  // Data Table
                  _buildDataTable(),

                  const SizedBox(height: kSpacingMedium),

                  // Pagination
                  if (filteredStatistics.length > itemsPerPage)
                    _buildPagination(),
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
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() => searchQuery = value);
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search by disease name or location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: kSpacingMedium),

          // Filter Dropdowns - Responsive Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // First Row: Region, Province, Municipality, Barangay
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRegion,
                          decoration: InputDecoration(
                            labelText: 'Region',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Regions')),
                            ...regions.map((r) => DropdownMenuItem(
                              value: r['code'],
                              child: Text(r['name']!, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedRegion = value;
                              _loadProvinces(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedProvince,
                          decoration: InputDecoration(
                            labelText: 'Province',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Provinces')),
                            ...provinces.map((p) => DropdownMenuItem(
                              value: p, 
                              child: Text(p, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedProvince = value;
                              if (value != null) {
                                _loadMunicipalities(value);
                              } else {
                                municipalities = [];
                                selectedMunicipality = null;
                              }
                            });
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMunicipality,
                          decoration: InputDecoration(
                            labelText: 'Municipality',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Municipalities')),
                            ...municipalities.map((m) => DropdownMenuItem(
                              value: m, 
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: selectedProvince == null
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedMunicipality = value;
                                    if (value != null && selectedProvince != null) {
                                      _loadBarangays(selectedProvince!, value);
                                    } else {
                                      barangays = [];
                                      selectedBarangay = null;
                                    }
                                  });
                                  _loadData();
                                },
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedBarangay,
                          decoration: InputDecoration(
                            labelText: 'Barangay',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Barangays')),
                            ...barangays.map((b) => DropdownMenuItem(
                              value: b, 
                              child: Text(b, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: selectedMunicipality == null
                              ? null
                              : (value) {
                                  setState(() => selectedBarangay = value);
                                  _loadData();
                                },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: kSpacingMedium),

                  // Second Row: Date Range Filter
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              helpText: 'Select Start Date',
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: startDate != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() => startDate = null);
                                      },
                                    )
                                  : const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              startDate != null
                                  ? DateFormat('MMM dd, yyyy').format(startDate!)
                                  : 'Select start date',
                              style: TextStyle(
                                color: startDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                              helpText: 'Select End Date',
                            );
                            if (picked != null) {
                              // Validate that end date is not before start date
                              if (startDate != null && picked.isBefore(startDate!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('End date cannot be before start date'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setState(() => endDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: endDate != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() => endDate = null);
                                      },
                                    )
                                  : const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(endDate!)
                                  : 'Select end date',
                              style: TextStyle(
                                color: endDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(flex: 2, child: Container()), // Spacer to match 4-column layout
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: kSpacingMedium),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: kSpacingSmall,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Validate date range before applying
                      if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End date cannot be before start date'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _loadData();
                    },
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (selectedRegion != null || selectedProvince != null || 
                      selectedMunicipality != null || selectedBarangay != null || 
                      startDate != null || endDate != null || searchQuery.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
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
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No data found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
          columns: const [
            DataColumn(label: Text('Disease Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cases', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Barangay', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Municipality', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Province', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Region', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: paginatedData.map((stat) {
            return DataRow(
              cells: [
                DataCell(Text(stat.diseaseName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stat.casesCount.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(stat.barangay)),
                DataCell(Text(stat.municipality)),
                DataCell(Text(stat.province)),
                DataCell(Text(stat.region)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => setState(() => currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Page $currentPage of $totalPages',
          style: const TextStyle(fontSize: 14),
        ),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => setState(() => currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
