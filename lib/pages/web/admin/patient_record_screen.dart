import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/services/clinic/patient_record_service.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_header.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_filters.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_card.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_details_modal.dart';
import 'dart:async';

class ImprovedPatientRecordsScreen extends StatefulWidget {
  const ImprovedPatientRecordsScreen({super.key});

  @override
  State<ImprovedPatientRecordsScreen> createState() => _ImprovedPatientRecordsScreenState();
}

class _ImprovedPatientRecordsScreenState extends State<ImprovedPatientRecordsScreen> 
    with AutomaticKeepAliveClientMixin {
  
  // Filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  final List<String> _types = ['All Types', 'Dog', 'Cat', 'Bird', 'Rabbit', 'Hamster'];
  final List<String> _statuses = ['All Status', 'Healthy', 'Treatment', 'Scheduled'];

  // Patient data
  List<PatientRecord> _patients = [];
  List<PatientRecord> _filteredPatients = [];

  // Loading state
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Clinic data
  String? _cachedClinicId;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Debounce timer for search
  Timer? _debounceTimer;

  // Statistics
  PatientStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePatients();
      }
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isInitialLoading = false;
        });
        return;
      }

      // Get clinic ID
      final clinicQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        setState(() {
          _error = 'No approved clinic found';
          _isInitialLoading = false;
        });
        return;
      }

      _cachedClinicId = clinicQuery.docs.first.id;

      // Load statistics
      final stats = await PatientRecordService.getPatientStatistics(_cachedClinicId!);
      
      // Load first page
      final result = await PatientRecordService.getClinicPatients(
        clinicId: _cachedClinicId!,
      );

      if (mounted) {
        setState(() {
          _statistics = stats;
          _patients = result.patients;
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _isInitialLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('❌ Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading patients: $e';
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePatients() async {
    if (_isLoadingMore || !_hasMore || _cachedClinicId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await PatientRecordService.getClinicPatients(
        clinicId: _cachedClinicId!,
        lastDocument: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _patients.addAll(result.patients);
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('❌ Error loading more patients: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Apply type filter
        if (_selectedType != 'All Types' && 
            patient.petType.toLowerCase() != _selectedType.toLowerCase()) {
          return false;
        }

        // Apply status filter
        if (_selectedStatus != 'All Status') {
          if (_selectedStatus == 'Healthy' && 
              patient.healthStatus != PatientHealthStatus.healthy) {
            return false;
          }
          if (_selectedStatus == 'Treatment' && 
              patient.healthStatus != PatientHealthStatus.treatment) {
            return false;
          }
          if (_selectedStatus == 'Scheduled' && 
              patient.healthStatus != PatientHealthStatus.scheduled) {
            return false;
          }
        }

        // Apply search filter
        if (query.isNotEmpty) {
          return patient.petName.toLowerCase().contains(query) ||
                 patient.breed.toLowerCase().contains(query) ||
                 patient.ownerName.toLowerCase().contains(query);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _patients.clear();
      _filteredPatients.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Statistics
            PatientRecordsHeader(
              onAddPatient: () {
                // TODO: Implement add patient functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add patient feature coming soon'),
                  ),
                );
              },
            ),

            // Statistics Cards
            if (_statistics != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Patients',
                        _statistics!.totalPatients.toString(),
                        Icons.pets,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Healthy',
                        _statistics!.healthyCount.toString(),
                        Icons.favorite,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Treatment',
                        _statistics!.treatmentCount.toString(),
                        Icons.medical_services,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Scheduled',
                        _statistics!.scheduledCount.toString(),
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Bar
            PatientFilterBar(
              searchController: _searchController,
              selectedType: _selectedType,
              selectedStatus: _selectedStatus,
              types: _types,
              statuses: _statuses,
              onTypeChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
                _applyFilters();
              },
              onStatusChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                _applyFilters();
              },
              onSearchChanged: (value) {
                // Handled by listener
              },
            ),

            // Patient Cards
            Expanded(
              child: _buildPatientList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search query',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              const maxCardWidth = 400.0;
              const spacing = 16.0;

              int cardsPerRow = (screenWidth / (maxCardWidth + spacing)).floor();
              cardsPerRow = cardsPerRow < 1 ? 1 : cardsPerRow;

              final totalSpacing = (cardsPerRow - 1) * spacing;
              final cardWidth = (screenWidth - totalSpacing) / cardsPerRow;

              return Column(
                children: [
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _filteredPatients.map((patient) {
                      return SizedBox(
                        width: cardWidth,
                        child: ImprovedPatientCard(
                          patient: patient,
                          onViewDetails: () {
                            _showPatientDetails(patient);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (!_hasMore && _filteredPatients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No more patients to load',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(PatientRecord patient) {
    showDialog(
      context: context,
      builder: (context) => ImprovedPatientDetailsModal(
        patient: patient,
        clinicId: _cachedClinicId!,
      ),
    );
  }
}
