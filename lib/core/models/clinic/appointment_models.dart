// models/appointment_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String type;
  final String emoji;
  final String? breed;
  final int? age;
  final String? imageUrl;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    this.breed,
    this.age,
    this.imageUrl,
  });

  factory Pet.fromMap(Map<String, dynamic> data) {
    return Pet(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      emoji: data['emoji'] ?? '🐕',
      breed: data['breed'],
      age: data['age'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'emoji': emoji,
      'breed': breed,
      'age': age,
      'imageUrl': imageUrl,
    };
  }
}

class Owner {
  final String id;
  final String name;
  final String phone;
  final String? email;

  Owner({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory Owner.fromMap(Map<String, dynamic> data) {
    return Owner(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow }

class Appointment {
  final String id;
  final String clinicId;
  final String date; // YYYY-MM-DD format
  final String time; // HH:MM format
  final String timeSlot; // e.g., "09:00-09:20"
  final Pet pet;
  final String diseaseReason;
  final Owner owner;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? veterinarianId;
  final double? estimatedDuration; // in minutes
  final String? serviceType;
  final String? cancelReason; // Reason for cancellation
  final DateTime? cancelledAt; // Timestamp when appointment was cancelled
  final String? assessmentResultId; // Reference to assessment_results collection

  Appointment({
    required this.id,
    required this.clinicId,
    required this.date,
    required this.time,
    required this.timeSlot,
    required this.pet,
    required this.diseaseReason,
    required this.owner,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.veterinarianId,
    this.estimatedDuration = 20.0,
    this.serviceType,
    this.cancelReason,
    this.cancelledAt,
    this.assessmentResultId,
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      clinicId: data['clinicId'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      pet: Pet.fromMap(data['pet'] ?? {}),
      diseaseReason: data['diseaseReason'] ?? '',
      owner: Owner.fromMap(data['owner'] ?? {}),
      status: AppointmentStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      veterinarianId: data['veterinarianId'],
      estimatedDuration: (data['estimatedDuration'] as num?)?.toDouble() ?? 20.0,
      serviceType: data['serviceType'],
      cancelReason: data['cancelReason'],
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      assessmentResultId: data['assessmentResultId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'date': date,
      'time': time,
      'timeSlot': timeSlot,
      'pet': pet.toMap(),
      'diseaseReason': diseaseReason,
      'owner': owner.toMap(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'veterinarianId': veterinarianId,
      'estimatedDuration': estimatedDuration,
      'serviceType': serviceType,
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'assessmentResultId': assessmentResultId,
    };
  }

  Appointment copyWith({
    String? id,
    String? clinicId,
    String? date,
    String? time,
    String? timeSlot,
    Pet? pet,
    String? diseaseReason,
    Owner? owner,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? veterinarianId,
    double? estimatedDuration,
    String? serviceType,
    String? cancelReason,
    DateTime? cancelledAt,
    String? assessmentResultId,
  }) {
    return Appointment(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      date: date ?? this.date,
      time: time ?? this.time,
      timeSlot: timeSlot ?? this.timeSlot,
      pet: pet ?? this.pet,
      diseaseReason: diseaseReason ?? this.diseaseReason,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      serviceType: serviceType ?? this.serviceType,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      assessmentResultId: assessmentResultId ?? this.assessmentResultId,
    );
  }
}

// Analytics model for tracking appointment statistics
class AppointmentAnalytics {
  final String clinicId;
  final String date; // YYYY-MM-DD
  final String dayOfWeek;
  final int totalAppointments;
  final int maxCapacity;
  final double utilizationRate; // percentage (0-100)
  final int confirmedAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int noShowAppointments;
  final Map<String, int> hourlyDistribution; // hour -> appointment count
  final DateTime lastUpdated;

  AppointmentAnalytics({
    required this.clinicId,
    required this.date,
    required this.dayOfWeek,
    required this.totalAppointments,
    required this.maxCapacity,
    required this.utilizationRate,
    required this.confirmedAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.noShowAppointments,
    required this.hourlyDistribution,
    required this.lastUpdated,
  });

  factory AppointmentAnalytics.fromFirestore(Map<String, dynamic> data, String id) {
    return AppointmentAnalytics(
      clinicId: data['clinicId'] ?? '',
      date: data['date'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? '',
      totalAppointments: data['totalAppointments'] ?? 0,
      maxCapacity: data['maxCapacity'] ?? 0,
      utilizationRate: (data['utilizationRate'] as num?)?.toDouble() ?? 0.0,
      confirmedAppointments: data['confirmedAppointments'] ?? 0,
      pendingAppointments: data['pendingAppointments'] ?? 0,
      completedAppointments: data['completedAppointments'] ?? 0,
      cancelledAppointments: data['cancelledAppointments'] ?? 0,
      noShowAppointments: data['noShowAppointments'] ?? 0,
      hourlyDistribution: Map<String, int>.from(data['hourlyDistribution'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'date': date,
      'dayOfWeek': dayOfWeek,
      'totalAppointments': totalAppointments,
      'maxCapacity': maxCapacity,
      'utilizationRate': utilizationRate,
      'confirmedAppointments': confirmedAppointments,
      'pendingAppointments': pendingAppointments,
      'completedAppointments': completedAppointments,
      'cancelledAppointments': cancelledAppointments,
      'noShowAppointments': noShowAppointments,
      'hourlyDistribution': hourlyDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Calculate analytics from a list of appointments
  factory AppointmentAnalytics.fromAppointmentList({
    required String clinicId,
    required String date,
    required String dayOfWeek,
    required List<Appointment> appointments,
    required int maxCapacity,
  }) {
    final confirmedCount = appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
    final pendingCount = appointments.where((a) => a.status == AppointmentStatus.pending).length;
    final completedCount = appointments.where((a) => a.status == AppointmentStatus.completed).length;
    final cancelledCount = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;
    final noShowCount = appointments.where((a) => a.status == AppointmentStatus.noShow).length;

    final totalAppointments = appointments.length;
    final utilizationRate = maxCapacity > 0 ? (totalAppointments / maxCapacity * 100) : 0.0;

    // Calculate hourly distribution
    final hourlyDistribution = <String, int>{};
    for (final appointment in appointments) {
      final hour = appointment.time.split(':')[0];
      hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
    }

    return AppointmentAnalytics(
      clinicId: clinicId,
      date: date,
      dayOfWeek: dayOfWeek,
      totalAppointments: totalAppointments,
      maxCapacity: maxCapacity,
      utilizationRate: utilizationRate,
      confirmedAppointments: confirmedCount,
      pendingAppointments: pendingCount,
      completedAppointments: completedCount,
      cancelledAppointments: cancelledCount,
      noShowAppointments: noShowCount,
      hourlyDistribution: hourlyDistribution,
      lastUpdated: DateTime.now(),
    );
  }
}