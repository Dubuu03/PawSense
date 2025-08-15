import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../core/widgets/vet_profile/vet_basic_info.dart';
import '../../core/widgets/vet_profile/specialization_badge.dart';
import '../../core/widgets/vet_profile/certification_card.dart';
import '../../core/widgets/vet_profile/vet_services_section.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  bool _isEmergencyAvailable = true;
  bool _isTelemedicineEnabled = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
                      'Vet Profile & Services',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your professional profile and service offerings',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle edit profile
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                        clinicName: 'PawSense Veterinary Clinic',
                        doctorName: 'Dr. Sarah Johnson',
                        email: 'dr.sarah@pawsense.com',
                        phone: '+1 (555) 123-4567',
                        address: '123 Pet Care Lane, Animal City, AC 12345',
                        website: 'www.pawsense.com',
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
                      const SizedBox(height: 16),

                      // Specializations
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
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
                            const SpecializationBadge(
                              title: 'Small Animal Care',
                              level: 'Expert',
                              hasCertification: true,
                            ),
                            const SpecializationBadge(
                              title: 'Dermatology',
                              level: 'Intermediate',
                              hasCertification: true,
                            ),
                            const SpecializationBadge(
                              title: 'Dentistry',
                              level: 'Basic',
                              hasCertification: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Certifications
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Certifications & Licenses',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                CertificationCard(
                                  title: 'DVM - Doctor of Veterinary Medicine',
                                  organization: 'Animal Care University',
                                  issueDate: 'Jan 2015',
                                  expiryDate: null,
                                  onDownload: () {},
                                ),
                                CertificationCard(
                                  title: 'Certified Animal Dermatologist',
                                  organization: 'Veterinary Dermatology Assoc.',
                                  issueDate: 'May 2018',
                                  expiryDate: 'May 2023',
                                  onDownload: () {},
                                ),
                                CertificationCard(
                                  title: 'Licensed Veterinary Dentist',
                                  organization: 'Dental Vets International',
                                  issueDate: 'Sep 2020',
                                  expiryDate: null,
                                  onDownload: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

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
