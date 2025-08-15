import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../core/widgets/vet_profile/vet_basic_info.dart';
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
    return Padding(
      padding: EdgeInsets.all(24.0),
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
                  Text(
                    'Vet Profile & Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
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
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Profile and Services Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left Column (Basic Info)
                Expanded(
                  flex: 1,
                  child: VetProfileBasicInfo(
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
                ),
                const SizedBox(width: 24),

                // Right Column (Services)
                Expanded(
                  flex: 2,
                  child: VetServicesSection(
                    services: _services,
                    onAddService: () {
                      // TODO: Implement add service
                    },
                    onServiceToggle: (String id) {
                      setState(() {
                        final index = _services.indexWhere((s) => s['id'] == id);
                        if (index != -1) {
                          _services[index]['isActive'] = !_services[index]['isActive'];
                        }
                      });
                    },
                    onServiceEdit: (String id) {
                      // TODO: Implement edit service
                    },
                    onServiceDelete: (String id) {
                      setState(() {
                        _services.removeWhere((s) => s['id'] == id);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}