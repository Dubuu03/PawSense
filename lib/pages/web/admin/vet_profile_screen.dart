import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../core/widgets/admin/vet_profile/vet_basic_info.dart';
import '../../../core/widgets/admin/vet_profile/specialization_badge.dart';
import '../../../core/widgets/admin/vet_profile/certification_card.dart';
import '../../../core/widgets/admin/vet_profile/certification_preview_modal.dart';
import '../../../core/widgets/admin/vet_profile/add_certification_modal.dart';
import '../../../core/widgets/admin/vet_profile/vet_services_section.dart';
import '../../../core/widgets/admin/vet_profile/vet_profile_header.dart';
import '../../../core/widgets/admin/vet_profile/add_service_modal.dart';
import '../../../core/widgets/admin/vet_profile/edit_service_modal.dart';
import '../../../core/widgets/admin/vet_profile/add_specialization_modal.dart';
import '../../../core/widgets/admin/vet_profile/specialization_preview_modal.dart';
import '../../../core/services/vet_profile/vet_profile_service.dart';
import '../../../core/utils/firestore_sample_data_util.dart';
import '../../../core/utils/file_downloader.dart' as file_downloader;

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Key _rebuildKey = UniqueKey(); // Add unique key for forcing rebuilds
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;

  Map<String, dynamic> _vetProfile = {};
  List<Map<String, dynamic>> _specializations = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _certifications = [];

  @override
  void initState() {
    super.initState();
    _loadVetProfile();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVetProfile({bool forceRefresh = false}) async {
    print('DEBUG VetProfileScreen: _loadVetProfile called with forceRefresh: $forceRefresh');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cancel existing subscription if any
      _profileSubscription?.cancel();
      
      // Use stream for real-time updates
      _profileSubscription = VetProfileService.streamVetProfile().listen(
        (profileData) {
          if (!mounted) return;
          
          print('🔄 VetProfileScreen: Received profile update from stream');
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
                'logoUrl': clinic?['logoUrl'] ?? clinicDetails?['logoUrl'],
              };

              // Extract services and map to UI format
              final servicesData = List<Map<String, dynamic>>.from(profileData['services'] ?? []);
              print('🔄 Services count from stream: ${servicesData.length}');
              
              _services = servicesData.map((service) => {
                'id': service['id'],
                'title': service['serviceName'] ?? service['name'] ?? 'Unnamed Service',
                'description': service['serviceDescription'] ?? service['description'] ?? '',
                'duration': service['duration'] ?? '30 mins',
                'price': service['estimatedPrice'] ?? service['price'] ?? '0',
                'category': service['category'],
                'isActive': service['isActive'] ?? true,
                'clinicId': service['clinicId'],
                'createdAt': service['createdAt'],
                'createdBy': service['createdBy'],
                'updatedAt': service['updatedAt'],
                'updatedBy': service['updatedBy'],
              }).toList();
              
              print('🔄 Mapped services: ${_services.length} items');

              // Extract certifications
              _certifications = List<Map<String, dynamic>>.from(profileData['certifications'] ?? []);
              print('🔄 Certifications: ${_certifications.length} items');

              // Extract specializations with backwards compatibility
              final dynamic specializationsData = profileData['specializations'] ?? [];
              
              if (specializationsData is List<String>) {
                // Old format: convert strings to maps
                _specializations = specializationsData.map((specialty) => {
                  'title': specialty.toString(),
                  'level': 'Expert',
                  'hasCertification': true,
                  'certificateUrl': null, // No certificate for old format
                }).toList();
              } else {
                // New format: already maps
                _specializations = List<Map<String, dynamic>>.from(specializationsData).map((spec) => {
                  'title': spec['title'] ?? '',
                  'level': spec['level'] ?? 'Expert',
                  'hasCertification': spec['hasCertification'] ?? true,
                  'certificateUrl': spec['certificateUrl'], // Include certificate URL
                }).toList();
              }
              
              print('🔄 Specializations: ${_specializations.length} items');

              _isLoading = false;
              _errorMessage = null;
              
              print('✅ VetProfileScreen: State updated successfully');
            });
          } else {
            setState(() {
              _errorMessage = 'Failed to load profile data. This might mean you don\'t have clinic data set up yet.';
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          print('❌ VetProfileScreen stream error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = 'Error loading profile: $error\n\nThis usually means you need to add sample data first.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('❌ Error in _loadVetProfile: $e');
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
          // Stream will automatically update the UI
          print('🔄 Service added, stream will update UI automatically');
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
          // Stream will automatically update the UI
          print('🔄 Service updated, stream will update UI automatically');
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

  /// Show Add Certification Modal
  Future<void> _showAddCertificationModal() async {
    showDialog(
      context: context,
      builder: (context) => AddCertificationModal(
        onCertificationAdded: () async {
          print('🔄 Certification added, stream will update UI automatically');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Certification added successfully'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  /// Show Certification Preview Modal
  void _showCertificationPreview(
    String title,
    String organization,
    String issueDate,
    String? expiryDate,
    String documentUrl,
  ) {
    showDialog(
      context: context,
      builder: (context) => CertificationPreviewModal(
        title: title,
        organization: organization,
        issueDate: issueDate,
        expiryDate: expiryDate,
        documentUrl: documentUrl,
        onDownload: () => _downloadCertification(documentUrl),
      ),
    );
  }

  /// Download Certification Document
  void _downloadCertification(String documentUrl) {
    // Only save the file locally (no external URL opening).
    final uri = Uri.tryParse(documentUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid document URL'), backgroundColor: AppColors.error),
      );
      return;
    }

    () async {
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'certificate_${DateTime.now().millisecondsSinceEpoch}';
          final savedPath = await file_downloader.downloadFile(fileName, response.bodyBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savedPath != null ? 'Saved to $savedPath' : 'Download started'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download document'), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        print('Error downloading document: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document'), backgroundColor: AppColors.error),
        );
      }
    }();
  }

  /// Show Specialization Certificate Preview
  void _showSpecializationPreview(Map<String, dynamic> specialization) {
    final certificateUrl = specialization['certificateUrl'] as String?;
    if (certificateUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => SpecializationPreviewModal(
        title: specialization['title'] ?? 'Specialization',
        level: specialization['level'] ?? 'Basic',
        certificateUrl: certificateUrl,
        onDownload: () => _downloadSpecializationCertificate(certificateUrl),
      ),
    );
  }

  /// Download Specialization Certificate
  void _downloadSpecializationCertificate(String certificateUrl) {
    final uri = Uri.tryParse(certificateUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid certificate URL'), backgroundColor: AppColors.error),
      );
      return;
    }

    () async {
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final fileName = uri.pathSegments.isNotEmpty 
              ? uri.pathSegments.last 
              : 'specialization_certificate_${DateTime.now().millisecondsSinceEpoch}';
          final savedPath = await file_downloader.downloadFile(fileName, response.bodyBytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(savedPath != null ? 'Saved to $savedPath' : 'Download started'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download certificate'), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        print('Error downloading certificate: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading certificate'), backgroundColor: AppColors.error),
        );
      }
    }();
  }

  /// Show Delete Certification Confirmation
  Future<void> _showDeleteCertificationConfirmation(String certificationId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Certification'),
        content: Text('Are you sure you want to delete this certification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      // TODO: Implement certification deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certification deletion will be implemented'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  /// Show Add Specialization Modal
  Future<void> _showAddSpecializationModal() async {
    showDialog(
      context: context,
      builder: (context) => AddSpecializationModal(
        onSpecializationAdded: () async {
          print('🔄 Specialization added, stream will update UI automatically');

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
    print('🔄 VetProfileScreen: Delete specialization called for: $specialization');

    final success = await VetProfileService.deleteSpecialization(specialization);
    print('🔄 VetProfileScreen: Delete specialization result: $success');

    if (success) {
      // Stream will automatically update the UI
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
      body: _errorMessage != null
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
                                  website: _vetProfile['website'] ?? '',
                                  logoUrl: _vetProfile['logoUrl'],
                                  onLogoUpdated: () {
                                    // Stream will automatically update the UI
                                    print('🔄 Logo updated, stream will update UI automatically');
                                  },
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
                                            tooltip: 'Add Specialization',
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: kSpacingMedium),

                                      if (_isLoading)
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(kSpacingMedium),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else if (_specializations.isEmpty)
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
                                          certificateUrl: spec['certificateUrl'],
                                          onPreview: spec['certificateUrl'] != null
                                              ? () => _showSpecializationPreview(spec)
                                              : null,
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
                                            onPressed: _showAddCertificationModal,
                                            icon: const Icon(Icons.upload_file),
                                            color: AppColors.primary,
                                            tooltip: 'Add Certificate',
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: kSpacingMedium),
                                      
                                      if (_isLoading)
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(kSpacingMedium),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      else if (_certifications.isEmpty)
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
                                        Column(
                                          children: _certifications.map((cert) {
                                            final certTitle = cert['name'] ?? cert['title'] ?? 'Unknown Certificate';
                                            final certOrg = cert['issuer'] ?? cert['organization'] ?? 'Unknown Organization';
                                            final documentUrl = cert['documentUrl'];
                                            final documentFileId = cert['documentFileId'];
                                            
                                            return CertificationCard(
                                              title: certTitle,
                                              organization: certOrg,
                                              issueDate: _formatDate(cert['dateIssued'] ?? cert['issueDate']),
                                              expiryDate: _formatDate(cert['dateExpiry'] ?? cert['expiryDate']),
                                              documentUrl: documentUrl,
                                              documentFileId: documentFileId,
                                              onPreview: documentUrl != null 
                                                ? () => _showCertificationPreview(
                                                    certTitle,
                                                    certOrg,
                                                    _formatDate(cert['dateIssued'] ?? cert['issueDate']),
                                                    _formatDate(cert['dateExpiry'] ?? cert['expiryDate']),
                                                    documentUrl,
                                                  )
                                                : null,
                                              onDelete: () => _showDeleteCertificationConfirmation(cert['id'] ?? ''),
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
                              isLoading: _isLoading,
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
