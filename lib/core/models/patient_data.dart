import 'package:flutter/widgets.dart';
import 'package:pawsense/core/widgets/admin/patient_records/patient_status.dart';

class PatientData {
  final String name;
  final String breed;
  final String petIcon;
  final String age;
  final String weight;
  final String lastVisit;
  final PatientStatus status;
  final int confidencePercentage;
  final String diseaseDetection;
  final Color cardColor;
  final String type;

  PatientData({
    required this.name,
    required this.breed,
    required this.petIcon,
    required this.age,
    required this.weight,
    required this.lastVisit,
    required this.status,
    required this.confidencePercentage,
    required this.diseaseDetection,
    required this.cardColor,
    required this.type,
  });
}