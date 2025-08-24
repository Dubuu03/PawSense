import 'package:flutter/material.dart';
import 'package:pawsense/core/models/patient_data.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_card.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_filters.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_header.dart';
import 'package:pawsense/core/widgets/admin/patient_records/add_patient_modal.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_status.dart';
import 'dart:math';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  final List<String> _types = ['All Types', 'Dog', 'Cat'];
  final List<String> _statuses = ['All Status', 'Healthy', 'Treatment'];

  // Helper function to get pet icon based on type
  String _getPetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐱';
      default:
        return '🐾';
    }
  }

  // Helper function to get random color
  Color _getRandomColor() {
    final colors = [
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.pink,
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.deepOrange,
      Colors.deepPurple,
    ];
    final random = Random();
    return colors[random.nextInt(colors.length)];
  }

  // Sample patient data
  List<PatientData> get _patients {
    final rawPatients = [
      {
        'name': 'Max',
        'breed': 'Golden Retriever',
        'age': '3 years',
        'weight': '28 kg',
        'lastVisit': '2024-01-15',
        'status': PatientStatus.treatment,
        'confidencePercentage': 92,
        'diseaseDetection': 'Skin Allergies',
        'type': 'Dog',
      },
      {
        'name': 'Luna',
        'breed': 'Persian',
        'age': '2 years',
        'weight': '4.5 kg',
        'lastVisit': '2024-01-10',
        'status': PatientStatus.healthy,
        'confidencePercentage': 98,
        'diseaseDetection': 'Healthy',
        'type': 'Cat',
      },
      {
        'name': 'Charlie',
        'breed': 'Siamese',
        'age': '1 year',
        'weight': '3.8 kg',
        'lastVisit': '2024-01-12',
        'status': PatientStatus.treatment,
        'confidencePercentage': 87,
        'diseaseDetection': 'Respiratory Issues',
        'type': 'Cat',
      },
      {
        'name': 'Bella',
        'breed': 'Bulldog',
        'age': '4 years',
        'weight': '24 kg',
        'lastVisit': '2024-02-01',
        'status': PatientStatus.healthy,
        'confidencePercentage': 95,
        'diseaseDetection': 'Healthy',
        'type': 'Dog',
      },
      {
        'name': 'Oliver',
        'breed': 'Maine Coon',
        'age': '3 years',
        'weight': '5 kg',
        'lastVisit': '2024-02-10',
        'status': PatientStatus.treatment,
        'confidencePercentage': 88,
        'diseaseDetection': 'Skin Infection',
        'type': 'Cat',
      },
      {
        'name': 'Rocky',
        'breed': 'Beagle',
        'age': '2 years',
        'weight': '20 kg',
        'lastVisit': '2024-02-05',
        'status': PatientStatus.healthy,
        'confidencePercentage': 97,
        'diseaseDetection': 'Healthy',
        'type': 'Dog',
      },
    ];

    return rawPatients
        .map(
          (data) => PatientData(
            name: data['name'] as String,
            breed: data['breed'] as String,
            petIcon: _getPetIcon(data['type'] as String),
            age: data['age'] as String,
            weight: data['weight'] as String,
            lastVisit: data['lastVisit'] as String,
            status: data['status'] as PatientStatus,
            confidencePercentage: data['confidencePercentage'] as int,
            diseaseDetection: data['diseaseDetection'] as String,
            cardColor: _getRandomColor(),
            type: data['type'] as String,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            PatientRecordsHeader(
              onAddPatient: () {
                showDialog(
                  context: context,
                  builder: (_) => AddPatientModal(
                    onCreate: (patient) {
                      // TODO: insert patient into data source
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created ${patient['petName']}')));
                    },
                  ),
                );
              },
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
              },
              onStatusChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              onSearchChanged: (value) {
                print('Search: $value');
              },
            ),

            // Patient Cards
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cardWidth = constraints.maxWidth < 900
                        ? constraints.maxWidth
                        : 500;

                    // Filter patients by type and optionally by status
                    List<PatientData> filteredPatients = _patients.where((p) {
                      final matchesType =
                          _selectedType == 'All Types' ||
                          p.type.toLowerCase() == _selectedType.toLowerCase();
                      final matchesStatus =
                          _selectedStatus == 'All Status' ||
                          (p.status == PatientStatus.healthy &&
                              _selectedStatus == 'Healthy') ||
                          (p.status == PatientStatus.treatment &&
                              _selectedStatus == 'Treatment');
                      return matchesType && matchesStatus;
                    }).toList();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 10, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;

                          const maxCardWidth = 400.0;
                          const spacing = 16.0;

                          // Ensure at least 1 card per row
                          int cardsPerRow =
                              (screenWidth / (maxCardWidth + spacing)).floor();
                          cardsPerRow = cardsPerRow < 1 ? 1 : cardsPerRow;

                          // Compute width for each card based on available space
                          final totalSpacing = (cardsPerRow - 1) * spacing;
                          final cardWidth =
                              (screenWidth - totalSpacing) / cardsPerRow;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: filteredPatients.map((patient) {
                              return SizedBox(
                                width: cardWidth,
                                child: PatientCard(
                                  name: patient.name,
                                  breed: patient.breed,
                                  petIcon: patient.petIcon,
                                  age: patient.age,
                                  weight: patient.weight,
                                  lastVisit: patient.lastVisit,
                                  status: patient.status,
                                  confidencePercentage:
                                      patient.confidencePercentage,
                                  diseaseDetection: patient.diseaseDetection,
                                  cardColor: patient.cardColor,
                                  onViewDetails: () {
                                    print('View details for ${patient.name}');
                                  },
                                  onEdit: () {
                                    print('Edit ${patient.name}');
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
