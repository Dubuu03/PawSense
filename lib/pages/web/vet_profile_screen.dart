import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../core/widgets/vet_profile/vet_basic_info.dart';
import '../../core/widgets/vet_profile/specialization_badge.dart';
import '../../core/widgets/vet_profile/certification_card.dart';
import '../../core/widgets/vet_profile/vet_services_section.dart';
import '../../core/widgets/vet_profile/vet_profile_header.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  bool _isEmergencyAvailable = true;
  bool _isTelemedicineEnabled = true;

  final Map<String, dynamic> _vetProfile = {
    'clinicName': 'PawSense Veterinary Clinic',
    'doctorName': 'Dr. Sarah Johnson',
    'email': 'dr.sarah@pawsense.com',
    'phone': '+1 (555) 123-4567',
    'address': '123 Pet Care Lane, Animal City, AC 12345',
    'website': 'www.pawsense.com',
  };

  final List<Map<String, dynamic>> _specializations = [
    {
      'title': 'Small Animal Care',
      'level': 'Expert',
      'hasCertification': true,
    },
    {
      'title': 'Dermatology',
      'level': 'Intermediate',
      'hasCertification': true,
    },
    {
      'title': 'Dentistry',
      'level': 'Basic',
      'hasCertification': false,
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'title': 'General Consultation',
      'description': 'Comprehensive health examination and consultation',
      'duration': 30,
      'price': 'PHP 75.00',
      'category': 'Consultation',
      'isActive': true,
    },
    {
      'id': '2',
      'title': 'Skin Scraping & Analysis',
      'description': 'Microscopic examination for skin conditions and parasites',
      'duration': 45,
      'price': 'PHP 120.00',
      'category': 'Diagnostics',
      'isActive': true,
    },
    {
      'id': '3',
      'title': 'Vaccination Package',
      'description': 'Complete vaccination schedule for puppies and kittens',
      'duration': 20,
      'price': 'PHP 95.00',
      'category': 'Preventive',
      'isActive': true,
    },
    {
      'id': '4',
      'title': 'Dental Cleaning',
      'description': 'Professional dental cleaning and oral health assessment',
      'duration': 90,
      'price': 'PHP 250.00',
      'category': 'Dental',
      'isActive': true,
    },
  ];

  final List<Map<String, dynamic>> _certifications = [
    {
      'title': 'DVM - Doctor of Veterinary Medicine',
      'organization': 'Animal Care University',
      'issueDate': 'Jan 2015',
      'expiryDate': null,
    },
    {
      'title': 'Certified Animal Dermatologist',
      'organization': 'Veterinary Dermatology Assoc.',
      'issueDate': 'May 2018',
      'expiryDate': 'May 2023',
    },
    {
      'title': 'Licensed Veterinary Dentist',
      'organization': 'Dental Vets International',
      'issueDate': 'Sep 2020',
      'expiryDate': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
                          clinicName: _vetProfile['clinicName'],
                          doctorName: _vetProfile['doctorName'],
                          email: _vetProfile['email'],
                          phone: _vetProfile['phone'],
                          address: _vetProfile['address'],
                          website: _vetProfile['website'],
                          isEmergencyAvailable: _isEmergencyAvailable,
                          isTelemedicineEnabled: _isTelemedicineEnabled,
                          onEmergencyToggle: () {
                            setState(() {
                              _isEmergencyAvailable = !_isEmergencyAvailable;
                            });
                          },
                          onTelemedicineToggle: () {
                            setState(() {
                              _isTelemedicineEnabled = !_isTelemedicineEnabled;
                            });
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
                                  const Text(
                                    'Specializations',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Handle add specialization
                                    },
                                    icon: const Icon(Icons.add),
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              ..._specializations.map((spec) => SpecializationBadge(
                                title: spec['title'],
                                level: spec['level'],
                                hasCertification: spec['hasCertification'],
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
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: _certifications.map((cert) {
                                  return CertificationCard(
                                    title: cert['title'],
                                    organization: cert['organization'],
                                    issueDate: cert['issueDate'],
                                    expiryDate: cert['expiryDate'],
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
                      onAddService: () {},
                      onServiceToggle: (String id) {
                        setState(() {
                          final index = _services.indexWhere((s) => s['id'] == id);
                          if (index != -1) {
                            _services[index]['isActive'] = !_services[index]['isActive'];
                          }
                        });
                      },
                      onServiceEdit: (String id) {},
                      onServiceDelete: (String id) {
                        setState(() {
                          _services.removeWhere((s) => s['id'] == id);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}
