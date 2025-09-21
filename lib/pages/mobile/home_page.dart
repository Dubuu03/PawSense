import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/tab_toggle.dart';
import 'package:pawsense/core/widgets/user/home/profile_header.dart';
import 'package:pawsense/core/widgets/user/home/pet_info_card.dart';
import 'package:pawsense/core/widgets/user/home/health_snapshot.dart';
import 'package:pawsense/core/widgets/user/home/nearby_clinics.dart';
import 'package:pawsense/core/widgets/user/home/services_grid.dart';
import 'package:pawsense/core/widgets/user/home/history_section.dart';
import 'package:pawsense/core/widgets/user/home/ai_history_list.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_list.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  UserModel? _userModel;
  bool _loading = true;
  int _currentNavIndex = 0;
  int _currentTabIndex = 0;
  Key _petCardKey = UniqueKey(); // Add this to force refresh
  bool _hasInitiallyLoaded = false; // Track if initial load is complete

  // Sample data - in a real app, this would come from your backend
  final List<HealthData> _healthData = [
    HealthData(condition: 'Mange', count: 1, color: const Color(0xFFFF9500)),
    HealthData(condition: 'Ringworm', count: 3, color: const Color(0xFF007AFF)),
    HealthData(condition: 'Flea Allergy', count: 2, color: const Color(0xFF8E44AD)),
    HealthData(condition: 'Pyoderma', count: 1, color: const Color(0xFFE74C3C)),
  ];

  // Sample AI history data
  final List<AIHistoryData> _aiHistory = [
    AIHistoryData(
      id: 'ai_001',
      title: 'Localized mange detected',
      subtitle: 'Today • 10:34 AM',
      type: AIDetectionType.mange,
      timestamp: DateTime.now(),
      confidence: 0.85,
    ),
    AIHistoryData(
      id: 'ai_002',
      title: 'Possible ringworm lesion',
      subtitle: 'Tue • 2:05 PM',
      type: AIDetectionType.ringworm,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      confidence: 0.73,
    ),
    AIHistoryData(
      id: 'ai_003',
      title: 'Severe hot spot indicative of ...',
      subtitle: 'Mon • 6:10 AM',
      type: AIDetectionType.pyoderma,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      confidence: 0.91,
    ),
  ];

  // Sample appointment history data
  final List<AppointmentHistoryData> _appointmentHistory = [
    AppointmentHistoryData(
      id: 'apt_001',
      title: 'Confirmed',
      subtitle: 'Sep 20 • 11:00 AM',
      status: AppointmentStatus.confirmed,
      timestamp: DateTime.now().add(const Duration(days: 14)),
      clinicName: 'Happy Paws Vet',
    ),
    AppointmentHistoryData(
      id: 'apt_002',
      title: 'Pending',
      subtitle: 'Oct 02 • 2:30 PM',
      status: AppointmentStatus.pending,
      timestamp: DateTime.now().add(const Duration(days: 26)),
      clinicName: 'Downtown Animal Care',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for query parameters to set initial tab
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];
    final refreshParam = uri.queryParameters['refresh'];
    
    if (tabParam == 'history') {
      setState(() {
        _currentTabIndex = 1; // History tab index
      });
    }
    
    // Refresh pet card on initial load or when explicitly requested
    final shouldRefresh = !_hasInitiallyLoaded || refreshParam == 'pets';
    
    if (shouldRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshPetCard();
          if (!_hasInitiallyLoaded) {
            setState(() {
              _hasInitiallyLoaded = true;
            });
          }
        }
      });
    }
  }

  void _refreshPetCard() {
    print('DEBUG: Refreshing pet card');
    setState(() {
      _petCardKey = UniqueKey();
    });
  }

  // Public method to refresh pets (can be called when returning from pets page)
  void refreshPets() {
    _refreshPetCard();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        // Initialize mobile messaging preferences for the user
        try {
          final preferencesService = MobileMessagingPreferencesService.instance;
          if (!preferencesService.isInitialized) {
            await preferencesService.initializeForUser(userModel.uid);
          }
        } catch (e) {
          print('Error initializing mobile messaging preferences: $e');
          // Don't block the UI for preferences initialization error
        }
        
        setState(() {
          _userModel = userModel;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: (updatedUser) {
          setState(() {
            _userModel = updatedUser;
          });
        },
      ),
      body: _loading 
          ? _buildLoadingState()
          : _userModel != null 
              ? _buildHomeContent()
              : _buildErrorState(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          if (index == 2) {
            // Navigate to alerts page
            context.push('/alerts');
          } else {
            setState(() {
              _currentNavIndex = index;
            });
            // Refresh pet card when home tab is selected
            if (index == 0) {
              _refreshPetCard();
            }
          }
        },
        onCameraPressed: _showCameraDialog,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to load user data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchUser,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Tab Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal, vertical: kMobileSizedBoxXLarge),
              child: TabToggle(
                selectedIndex: _currentTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                tabs: const ['Dashboard', 'History'],
              ),
            ),
            
            // Content based on selected tab
            if (_currentTabIndex == 0) ...[
              // Dashboard Tab
                Transform.translate(
                  offset: Offset(0, -kMobileSizedBoxXLarge),
                  child: Column(
                    children: [
                      ProfileHeader(
                        user: _userModel!,
                        onManagePressed: () async {
                          // Navigate to edit profile page
                          final updatedUser = await context.push('/edit-profile', extra: {
                            'user': _userModel!,
                          });
                          
                          // If user data was updated, refresh the page
                          if (updatedUser != null && updatedUser is UserModel) {
                            setState(() {
                              _userModel = updatedUser;
                            });
                          } else {
                            // Fallback: refresh user data from server
                            _fetchUser();
                          }
                        },
                      ),

                      PetInfoCard(
                        key: _petCardKey,
                        nextAppointmentDate: null, // No appointment
                        nextAppointmentTime: null, // No appointment
                        refreshKey: _petCardKey,
                      ),

                      // Add space between pets and health snapshot
                      const SizedBox(height: kMobileSizedBoxHuge),

                      HealthSnapshot(
                        healthData: _healthData,
                      ),

                      NearbyClinicsWidget(
                        onViewAllPressed: () {
                          // Handle view all clinics
                          print('View all clinics pressed');
                        },
                        onMessageClinic: (clinic) {
                          // Handle message clinic
                          print('Message clinic: ${clinic.name}');
                          // TODO: Navigate to messaging or contact page
                        },
                      ),

                      // Services moved below nearby clinics
                      ServicesGrid(
                        services: _getServices(),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // History Tab
              _buildHistoryContent(),
            ],
            
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return HistorySection(
      aiHistory: _aiHistory,
      appointmentHistory: _appointmentHistory,
      onViewAllPressed: () {
        // Handle view all history
      },
    );
  }

  List<ServiceItem> _getServices() {
    return [
      ServiceItem(
        title: 'Book Appointment',
        subtitle: 'Schedule visit',
        icon: Icons.calendar_today,
        backgroundColor: const Color(0xFF8E44AD).withValues(alpha: 0.1),
        onTap: () {
          context.push('/book-appointment');
        },
      ),
      ServiceItem(
        title: 'Emergency Hotline',
        subtitle: '24/7 support',
        icon: Icons.phone,
        backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
        onTap: () {
          context.push('/emergency-hotline');
        },
      ),
      ServiceItem(
        title: 'First Aid Guide',
        subtitle: 'Emergency tips',
        icon: Icons.medical_services,
        backgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.1),
        onTap: () {
          context.push('/first-aid-guide');
        },
      ),
      ServiceItem(
        title: 'Pet Care Tips',
        subtitle: 'Daily care',
        icon: Icons.lightbulb_outline,
        backgroundColor: const Color(0xFF34C759).withValues(alpha: 0.1),
        onTap: () {
          context.push('/pet-care-tips');
        },
      ),
    ];
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
