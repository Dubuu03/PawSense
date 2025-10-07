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

  final List<String> _types = ['All Types', 'Dog', 'Cat',];
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

  // Flag to prevent duplicate loading
  bool _isLoadingInitialData = false;

  // Preloading optimization
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    print('📌 initState called - PatientRecordsScreen');
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    
    // Start loading immediately with high priority
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    
    // Preload next page after initial load
    _preloadTimer = Timer(const Duration(seconds: 2), () {
      if (!_isLoadingMore && _hasMore) {
        _preloadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _preloadTimer?.cancel();
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

  PatientStatistics _calculateStatistics(List<PatientRecord> patients) {
    final totalPatients = patients.length;
    final healthyCount = patients
        .where((p) => p.healthStatus == PatientHealthStatus.healthy)
        .length;
    final treatmentCount = patients
        .where((p) => p.healthStatus == PatientHealthStatus.treatment)
        .length;
    final scheduledCount = patients
        .where((p) => p.healthStatus == PatientHealthStatus.scheduled)
        .length;

    return PatientStatistics(
      totalPatients: totalPatients,
      healthyCount: healthyCount,
      treatmentCount: treatmentCount,
      scheduledCount: scheduledCount,
    );
  }

  Future<void> _loadInitialData() async {
    // Prevent duplicate loading
    if (_isLoadingInitialData) {
      print('⚠️ Already loading initial data, skipping duplicate request');
      return;
    }

    print('🚀 Starting optimized initial data load...');
    _isLoadingInitialData = true;

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
        _isLoadingInitialData = false;
        return;
      }

      // Use cached clinic ID if available
      if (_cachedClinicId == null) {
        print('🏥 Getting clinic info...');
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
          _isLoadingInitialData = false;
          return;
        }

        _cachedClinicId = clinicQuery.docs.first.id;
        print('✅ Loaded clinic info: ${clinicQuery.docs.first.data()['clinicName'] ?? 'Unknown'}');
      } else {
        print('✅ Using cached clinic ID');
      }

      // Load patients with optimized service (single batched call)
      print('🔄 Loading patients with batch optimization...');
      final result = await PatientRecordService.getClinicPatients(
        clinicId: _cachedClinicId!,
      );

      // Calculate statistics from loaded patients (no additional network call)
      final stats = _calculateStatistics(result.patients);

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
    } finally {
      _isLoadingInitialData = false;
      print('✅ Initial data load completed, flag reset');
    }
  }

  /// Preload next page in background for better UX
  void _preloadNextPage() {
    if (_isLoadingMore || !_hasMore || _cachedClinicId == null) return;
    
    // Load more patients silently in background
    _loadMorePatients();
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
            const PatientRecordsHeader(),

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
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                const spacing = 16.0;
                const cardsPerRow = 3;

                return SliverMainAxisGroup(
                  slivers: [
                    // Patient cards grid
                    SliverGrid.count(
                      crossAxisCount: cardsPerRow,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.78, // Reduced to give more height
                      children: _filteredPatients.map((patient) {
                        return ImprovedPatientCard(
                          patient: patient,
                          onViewDetails: () {
                            _showPatientDetails(patient);
                          },
                        );
                      }).toList(),
                    ),
                    
                    // Loading indicator
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    
                    // End message
                    if (!_hasMore && _filteredPatients.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No more patients to load',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
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
