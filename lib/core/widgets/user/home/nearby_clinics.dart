import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/pages/mobile/clinic/clinic_details_page.dart';
import 'package:pawsense/pages/mobile/clinic/clinic_list_page.dart';
import 'package:pawsense/pages/mobile/messaging/conversation_page.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/data_cache.dart';

class ClinicInfo {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? website;
  final String? logoUrl;
  final String? operatingHours;
  final List<String> specialties;
  final bool isVerified;
  final double rating;

  ClinicInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
    this.logoUrl,
    this.operatingHours,
    this.specialties = const [],
    this.isVerified = false,
    this.rating = 4.5,
  });

  /// Factory constructor to create from database map
  factory ClinicInfo.fromMap(Map<String, dynamic> map) {
    return ClinicInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
      logoUrl: map['logoUrl'],
      operatingHours: map['operatingHours'],
      specialties: List<String>.from(map['specialties'] ?? []),
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] ?? 4.5).toDouble(),
    );
  }
}

class NearbyClinicsWidget extends StatefulWidget {
  final VoidCallback? onViewAllPressed;
  final Function(ClinicInfo)? onMessageClinic;
  final int displayLimit;

  const NearbyClinicsWidget({
    super.key,
    this.onViewAllPressed,
    this.onMessageClinic,
    this.displayLimit = 3,
  });

  @override
  State<NearbyClinicsWidget> createState() => _NearbyClinicsWidgetState();
}

class _NearbyClinicsWidgetState extends State<NearbyClinicsWidget> {
  List<ClinicInfo> _clinics = [];
  bool _isLoading = true;
  String? _errorMessage;
  final DataCache _cache = DataCache();

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    // Clean up any resources here if needed
    super.dispose();
  }

  // Public method to refresh clinics
  void refreshClinics({bool forceRefresh = false}) {
    if (mounted) {
      print('DEBUG: refreshClinics called - forceRefresh: $forceRefresh');
      _loadClinics(forceRefresh: forceRefresh);
    }
  }

  Future<void> _loadClinics({bool forceRefresh = false}) async {
    print('DEBUG: NearbyClinics _loadClinics called - current clinics: ${_clinics.length}, forceRefresh: $forceRefresh');
    
    final cacheKey = CacheKeys.clinics();
    
    // Try to get cached data first (unless forcing refresh)
    if (!forceRefresh) {
      final cachedClinics = _cache.get<List<ClinicInfo>>(cacheKey);
      if (cachedClinics != null) {
        print('DEBUG: NearbyClinics - Using cached clinics (${cachedClinics.length} clinics)');
        if (mounted) {
          setState(() {
            _clinics = cachedClinics;
            _isLoading = false;
            _errorMessage = null;
          });
        }
        return;
      }
    }
    
    // Don't show loading spinner if we already have data and are just refreshing
    final showLoading = _clinics.isEmpty;
    print('DEBUG: NearbyClinics - showLoading: $showLoading');
    
    try {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Get all available clinics to show accurate count
      print('DEBUG: NearbyClinics - Fetching clinics from API');
      final clinicsData = await ClinicListService.getAllActiveClinics();
      
      final List<ClinicInfo> clinics = [];
      for (int i = 0; i < clinicsData.length; i++) {
        try {
          final clinic = ClinicInfo.fromMap(clinicsData[i]);
          clinics.add(clinic);
        } catch (e) {
          // Skip invalid clinic data
          continue;
        }
      }
      
      print('DEBUG: NearbyClinics loaded ${clinics.length} clinics from API');
      
      // Cache the fresh data (10 minutes TTL since clinics don't change often)
      _cache.put(cacheKey, clinics, ttl: const Duration(minutes: 10));

      if (mounted) {
        setState(() {
          _clinics = clinics;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error loading clinics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load clinics. Please try again.';
        });
      }
    }
  }

  Future<void> _messageClinic(ClinicInfo clinic) async {
    try {
      // Get current user
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        _showSnackBar('Please log in to send messages');
        return;
      }

      // Check if conversation already exists with this clinic
      final conversationsStream = MessagingService.getUserConversations();
      await for (final conversations in conversationsStream.take(1)) {
        // Look for existing conversation with this clinic
        Conversation? existingConversation;
        try {
          existingConversation = conversations.firstWhere(
            (conv) => conv.clinicId == clinic.id,
          );
        } catch (e) {
          // No existing conversation found
          existingConversation = null;
        }

        if (existingConversation != null) {
          // Navigate to existing conversation (like clicking from messages menu)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: existingConversation!,
              ),
            ),
          );
        } else {
          // Create a temporary conversation for new conversation
          final tempConversation = Conversation(
            id: 'temp_${clinic.id}_${DateTime.now().millisecondsSinceEpoch}',
            userId: currentUser.uid,
            userName: '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
            clinicId: clinic.id,
            clinicName: clinic.name,
            lastMessageTime: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to conversation page with temporary conversation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: tempConversation,
              ),
            ),
          );
        }
        break; // Exit the stream after first result
      }
    } catch (e) {
      print('Error in _messageClinic: $e');
      _showSnackBar('Error loading conversation');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kMobileMarginContainer,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Vet Clinics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoading 
                      ? 'Loading clinics...'
                      : _clinics.isEmpty 
                        ? 'No clinics available'
                        : 'Find quality veterinary care',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            _buildLoadingIndicator()
          else if (_errorMessage != null)
            _buildErrorMessage()
          else if (_clinics.isEmpty)
            _buildEmptyState()
          else
            _buildClinicsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (mounted) {
                  _loadClinics(forceRefresh: true);
                }
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.local_hospital_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'No clinics available at the moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicsList() {
    final displayClinics = _clinics.take(widget.displayLimit).toList();
    
    return Column(
      children: [
        // Clinics list
        ...displayClinics.map((clinic) => _buildClinicItem(clinic)),

        // View all button
        if (_clinics.length > widget.displayLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClinicListPage(),
                    ),
                  );
                },
                child: Text(
                  'View All Clinics (${_clinics.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClinicItem(ClinicInfo clinic) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClinicDetailsPage(clinicId: clinic.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Clinic logo/icon (circular)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4), // Add padding to make image smaller inside circle
              child: ClipOval(
                child: clinic.logoUrl != null && clinic.logoUrl!.isNotEmpty
                    ? Image.network(
                        clinic.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            clinic.isVerified ? Icons.verified : Icons.local_hospital,
                            size: 20,
                            color: clinic.isVerified ? AppColors.success : AppColors.primary,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Icon(
                        clinic.isVerified ? Icons.verified : Icons.local_hospital,
                        size: 20,
                        color: clinic.isVerified ? AppColors.success : AppColors.primary,
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Clinic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clinic.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (clinic.isVerified)
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic.address,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          clinic.phone,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Action button
            _buildActionButton(
              icon: Icons.message,
              onPressed: () => _messageClinic(clinic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 14,
          color: AppColors.white,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
