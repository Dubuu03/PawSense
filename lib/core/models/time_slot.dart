import 'package:flutter/material.dart';

class TimeSlot {
  final String startTime;
  final String endTime;
  final String type;
  final int currentAppointments;
  final int maxAppointments;
  final double utilizationPercentage;
  final Color progressColor;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.currentAppointments,
    required this.maxAppointments,
    required this.utilizationPercentage,
    required this.progressColor,
  });

  String get timeRange => '$startTime\n$endTime';
  String get appointmentText => '$currentAppointments / $maxAppointments appointments';
}