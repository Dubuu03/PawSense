import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../core/widgets/admin/vet_profile/vet_basic_info.dart';
import '../../../core/widgets/admin/vet_profile/specialization_badge.dart';
import '../../../core/widgets/admin/vet_profile/certification_card.dart';
import '../../../core/widgets/admin/vet_profile/vet_services_section.dart';
import '../../../core/widgets/admin/vet_profile/vet_profile_header.dart';
import '../../../core/widgets/admin/vet_profile/add_service_modal.dart';
import '../../../core/widgets/admin/vet_profile/edit_service_modal.dart';
import '../../../core/widgets/admin/vet_profile/add_specialization_modal.dart';
import '../../../core/services/vet_profile/vet_profile_service.dart';
import '../../../core/utils/firestore_sample_data_util.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Key _rebuildKey = UniqueKey(); // Add unique key for forcing rebuilds

  Map<String, dynamic> _vetProfile = {};
  List<Map<String, dynamic>> _specializations = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _certifications = [];

  @override
  void initState() {
    super.initState();
    _loadVetProfile();
  }

  Future<void> _loadVetProfile({bool forceRefresh = false}) async {
    print('DEBUG VetProfileScreen: _loadVetProfile called with forceRefresh: $forceRefresh');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileData = await VetProfileService.getVetProfile(forceRefresh: forceRefresh);
      print('DEBUG VetProfileScreen: profileData received, specializations: ${profileData?['specializations']}');
      print('DEBUG: Profile data received: $profileData');
      
      if (profileData != null) {
        setState(() {
          // Extract basic clinic info
          final clinic = profileData['clinic'] as Map<String, dynamic>?;
          final clinicDetails = profileData['clinicDetails'] as Map<String, dynamic>?;
          final user = profileData['user'] as Map<String, dynamic>?;
          
          _vetProfile = {
            'clinicName': clinic?['clinicName'] ?? 'Unknown Clinic',
            'doctorName': user?['username'] ?? 'Unknown Doctor',
            'email': clinic?['email'] ?? user?['email'] ?? 'No email',
            'phone': clinic?['phone'] ?? 'No phone',
            'address': clinic?['address'] ?? 'No address',
            'website': clinic?['website'] ?? clinicDetails?['website'],
          };

          // Extract services and map to UI format
          final servicesData = List<Map<String, dynamic>>.from(profileData['services'] ?? []);
          print('DEBUG: Raw services data: $servicesData');
          print('DEBUG: Services count: ${servicesData.length}');
          
          // Print each service individually to see the actual field names
          for (int i = 0; i < servicesData.length; i++) {
            print('DEBUG: Service $i fields: ${servicesData[i].keys.toList()}');
            print('DEBUG: Service $i serviceName: "${servicesData[i]['serviceName']}"');
            print('DEBUG: Service $i values: ${servicesData[i]}');
          }
          
          _services = servicesData.map((service) => {
            'id': service['id'],
            'title': service['serviceName'] ?? service['name'] ?? 'Unnamed Service',
            'description': service['serviceDescription'] ?? service['description'] ?? '',
            'duration': service['duration'] ?? '30 mins', // Keep as string for now
            'price': service['estimatedPrice'] ?? service['price'] ?? '0',
            'category': service['category'],
            'isActive': service['isActive'] ?? true,
            'clinicId': service['clinicId'],
            'createdAt': service['createdAt'],
            'createdBy': service['createdBy'],
            'updatedAt': service['updatedAt'],
            'updatedBy': service['updatedBy'],
          }).toList();
          
          print('DEBUG: Mapped services: $_services');

          // Check if we have basic data but no services
          if (_services.isEmpty) {
            print('DEBUG: No services found in profile data');
          }

          // Extract certifications
          _certifications = List<Map<String, dynamic>>.from(profileData['certifications'] ?? []);
          print('DEBUG: Raw certifications data: ${profileData['certifications']}');
          print('DEBUG: Mapped certifications: $_certifications');
          print('DEBUG: Certifications count: ${_certifications.length}');

          // Extract specializations with backwards compatibility
          final dynamic specializationsData = profileData['specializations'] ?? [];
          
          if (specializationsData is List<String>) {
            // Old format: convert strings to maps
            _specializations = specializationsData.map((specialty) => {
              'title': specialty.toString(),
              'level': 'Expert',
              'hasCertification': true,
            }).toList();
          } else {
            // New format: already maps
            _specializations = List<Map<String, dynamic>>.from(specializationsData).map((spec) => {
              'title': spec['title'] ?? '',
              'level': spec['level'] ?? 'Expert',
              'hasCertification': spec['hasCertification'] ?? true,
            }).toList();
          }
          
          print('DEBUG VetProfileScreen: Final specializations count: ${_specializations.length}');
          print('DEBUG VetProfileScreen: Specializations titles: ${_specializations.map((s) => s['title']).toList()}');


          _isLoading = false;

          print('DEBUG VetProfileScreen: setState completed, UI should refresh');
          print('DEBUG VetProfileScreen: Current state - _specializations: ${_specializations.length} items');

          // Force a rebuild to ensure UI updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                print('DEBUG VetProfileScreen: Force rebuild triggered');
              });
            }
          });
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data. This might mean you don\'t have clinic data set up yet.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error in _loadVetProfile: $e');
      setState(() {
        _errorMessage = 'Error loading profile: $e\n\nThis usually means you need to add sample data first.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleServiceStatus(String serviceId) async {
    // Find current status
    final serviceIndex = _services.indexWhere((s) => s['id'] == serviceId);
    if (serviceIndex == -1) return;
    
    final currentStatus = _services[serviceIndex]['isActive'] as bool;
    final newStatus = !currentStatus;
    
    final success = await VetProfileService.toggleServiceStatus(serviceId, newStatus);
    
    if (success) {
      setState(() {
        _services[serviceIndex]['isActive'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service ${newStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update service status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteService(String serviceId) async {
    final success = await VetProfileService.deleteService(serviceId);
    
    if (success) {
      setState(() {
        _services.removeWhere((s) => s['id'] == serviceId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete service'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddServiceModal() {
    showDialog(
      context: context,
      builder: (context) => AddServiceModal(
        onServiceAdded: () {
          // Reload the profile data to show the new service
          _loadVetProfile();
        },
      ),
    );
  }

  void _showEditServiceModal(String serviceId) {
    // Find the service by ID
    final service = _services.firstWhere(
      (s) => s['id'] == serviceId,
      orElse: () => {},
    );

    if (service.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EditServiceModal(
        service: service,
        onServiceUpdated: () {
          // Reload the profile data to show the updated service
          _loadVetProfile();
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String serviceId) async {
    // Find the service by ID to get its name
    final service = _services.firstWhere(
      (s) => s['id'] == serviceId,
      orElse: () => {},
    );

    final serviceName = service['title'] ?? 'this service';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Service',
          style: TextStyle(
            fontSize: kFontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$serviceName"? This action cannot be undone.',
          style: TextStyle(
            fontSize: kFontSizeRegular,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteService(serviceId);
    }
  }

  Future<void> _addSampleData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await FirestoreSampleDataUtil.addSampleVetProfileData();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sample data added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reload the profile data
      await _loadVetProfile(forceRefresh: true);
    } else {
      setState(() {
        _errorMessage = 'Failed to add sample data';
        _isLoading = false;
      });
    }
  }

  Future<void> _fixExistingServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await VetProfileService.fixExistingServices();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Services fixed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reload the profile data
      await _loadVetProfile(forceRefresh: true);
    } else {
      setState(() {
        _errorMessage = 'Failed to fix services';
        _isLoading = false;
      });
    }
  }

  /// Show Add Specialization Modal
  Future<void> _showAddSpecializationModal() async {
    showDialog(
      context: context,
      builder: (context) => AddSpecializationModal(
        onSpecializationAdded: () async {
          print('DEBUG VetProfileScreen: Modal callback - specialization added, refreshing data...');

          // Clear all existing state completely
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _vetProfile.clear();
              _specializations.clear();
              _services.clear();
              _certifications.clear();
              _rebuildKey = UniqueKey();
              print('DEBUG VetProfileScreen: State cleared, new rebuild key: $_rebuildKey');
            });
          }

          // Small delay to ensure modal is fully closed
          await Future.delayed(Duration(milliseconds: 200));

          // Reload the profile data with force refresh
          await _loadVetProfile(forceRefresh: true);
          print('DEBUG VetProfileScreen: Modal callback - data refresh completed');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Specialization added successfully'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  /// Delete specialization
  Future<void> _deleteSpecialization(String specialization) async {
    print('DEBUG VetProfileScreen: Delete specialization called for: $specialization');

    // Clear all existing state completely
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _vetProfile.clear();
        _specializations.clear();
        _services.clear();
        _certifications.clear();
        _rebuildKey = UniqueKey();
        print('DEBUG VetProfileScreen: State cleared for deletion, new rebuild key: $_rebuildKey');
      });
    }

    final success = await VetProfileService.deleteSpecialization(specialization);
    print('DEBUG VetProfileScreen: Delete specialization result: $success');

    if (success) {
      // Small delay to ensure backend operation is complete
      await Future.delayed(Duration(milliseconds: 300));

      // Reload with force refresh to get updated data
      await _loadVetProfile(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specialization deleted successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete specialization'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show delete confirmation for specialization
  Future<void> _showDeleteSpecializationConfirmation(String specialization) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Specialization',
          style: TextStyle(
            fontSize: kFontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$specialization" from your specializations?',
          style: TextStyle(
            fontSize: kFontSizeRegular,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteSpecialization(specialization);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: kIconSizeLarge,
                        color: AppColors.error,
                      ),
                      SizedBox(height: kSpacingMedium),
                      Text(
                        'Error loading profile',
                        style: TextStyle(
                          fontSize: kFontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: kSpacingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _loadVetProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                          SizedBox(width: kSpacingMedium),
                          ElevatedButton(
                            onPressed: _fixExistingServices,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Fix Services'),
                          ),
                          SizedBox(width: kSpacingMedium),
                          ElevatedButton(
                            onPressed: _addSampleData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Add Sample Data'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                             : Container(
                   key: _rebuildKey, // Force rebuild when key changes
                   child: SingleChildScrollView(
                     padding: EdgeInsets.all(kSpacingLarge),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                      // Header
                      VetProfileHeader(
                        onEditProfile: () {
                          // Handle edit profile
                        },
                      ),
                      SizedBox(height: kSpacingLarge),

                      // Profile + Services
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT COLUMN
                          Flexible(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Basic Info
                                VetProfileBasicInfo(
                                  clinicName: _vetProfile['clinicName'] ?? 'Unknown Clinic',
                                  doctorName: _vetProfile['doctorName'] ?? 'Unknown Doctor',
                                  email: _vetProfile['email'] ?? 'No email',
                                  phone: _vetProfile['phone'] ?? 'No phone',
                                  address: _vetProfile['address'] ?? 'No address',
                                  website: _vetProfile['website'],
                                ),
                                SizedBox(height: kSpacingMedium),

                                // Specializations
                                Container(
                                  padding: EdgeInsets.all(kSpacingMedium),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(kBorderRadius),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Specializations',
                                            style: TextStyle(
                                              fontSize: kFontSizeLarge,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _showAddSpecializationModal,
                                            icon: const Icon(Icons.add),
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: kSpacingMedium),

                                      if (_specializations.isEmpty)
                                        Center(
                                          child: Text(
                                            'No specializations added yet',
                                            style: TextStyle(
                                              fontSize: kFontSizeRegular,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        )
                                      else
                                        ..._specializations.map((spec) => SpecializationBadge(
                                          title: spec['title'] ?? '',
                                          level: spec['level'] ?? 'Basic',
                                          hasCertification: spec['hasCertification'] ?? false,
                                          onDelete: () => _showDeleteSpecializationConfirmation(spec['title'] ?? ''),
                                        )),
                                    ],
                                  ),
                                ),
                                SizedBox(height: kSpacingLarge),

                                // Certifications
                                Container(
                                  padding: EdgeInsets.all(kSpacingMedium),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(kBorderRadius),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Certifications & Licenses',
                                            style: TextStyle(
                                              fontSize: kFontSizeLarge,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              // Handle upload certification
                                            },
                                            icon: const Icon(Icons.upload_file),
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: kSpacingMedium),
                                      
                                      if (_certifications.isEmpty)
                                        Center(
                                          child: Text(
                                            'No certifications added yet',
                                            style: TextStyle(
                                              fontSize: kFontSizeRegular,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: kSpacingMedium,
                                          runSpacing: kSpacingMedium,
                                          children: _certifications.map((cert) {
                                            return CertificationCard(
                                              title: cert['name'] ?? cert['title'] ?? 'Unknown Certificate',
                                              organization: cert['issuer'] ?? cert['organization'] ?? 'Unknown Organization',
                                              issueDate: _formatDate(cert['dateIssued'] ?? cert['issueDate']),
                                              expiryDate: _formatDate(cert['dateExpiry'] ?? cert['expiryDate']),
                                              onDownload: () {},
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: kSpacingLarge),

                          // RIGHT COLUMN
                          Flexible(
                            flex: 2,
                            child: VetServicesSection(
                              services: _services,
                              onAddService: _showAddServiceModal,
                              onServiceToggle: (String id) => _toggleServiceStatus(id),
                              onServiceEdit: (String id) => _showEditServiceModal(id),
                              onServiceDelete: (String id) => _showDeleteConfirmation(id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
               ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No expiry';
    
    DateTime? actualDate;
    
    if (date is String) {
      // Try to parse if it's a string
      actualDate = DateTime.tryParse(date);
    } else if (date is DateTime) {
      actualDate = date;
    } else if (date is Timestamp) {
      // Handle Firestore Timestamp
      try {
        actualDate = date.toDate();
      } catch (e) {
        print('Error converting Timestamp: $e');
        return date.toString();
      }
    }
    
    if (actualDate != null) {
      // Format as YYYY-MM-DD
      return '${actualDate.year.toString().padLeft(4, '0')}-${actualDate.month.toString().padLeft(2, '0')}-${actualDate.day.toString().padLeft(2, '0')}';
    }
    
    return date.toString();
  }
}
