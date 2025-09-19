import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rescheduled
}

enum AppointmentType {
  general,
  emergency,
  followUp,
  vaccination,
  surgery,
  consultation
}

class AppointmentBooking {
  final String? id;
  final String userId;
  final String petId;
  final String clinicId;
  final String serviceName;
  final String serviceId;
  final DateTime appointmentDate;
  final String appointmentTime; // Store as string (e.g., "14:30")
  final String notes;
  final AppointmentStatus status;
  final AppointmentType type;
  final double? estimatedPrice;
  final String? duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final String? rescheduleReason;
  final DateTime? rescheduledAt;

  AppointmentBooking({
    this.id,
    required this.userId,
    required this.petId,
    required this.clinicId,
    required this.serviceName,
    required this.serviceId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.notes = '',
    this.status = AppointmentStatus.pending,
    this.type = AppointmentType.general,
    this.estimatedPrice,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.cancelReason,
    this.cancelledAt,
    this.rescheduleReason,
    this.rescheduledAt,
  });

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petId': petId,
      'clinicId': clinicId,
      'serviceName': serviceName,
      'serviceId': serviceId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'notes': notes,
      'status': status.name,
      'type': type.name,
      'estimatedPrice': estimatedPrice,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'rescheduleReason': rescheduleReason,
      'rescheduledAt': rescheduledAt != null ? Timestamp.fromDate(rescheduledAt!) : null,
    };
  }

  /// Create from Firestore document
  factory AppointmentBooking.fromMap(Map<String, dynamic> map, String documentId) {
    return AppointmentBooking(
      id: documentId,
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      appointmentTime: map['appointmentTime'] ?? '',
      notes: map['notes'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      type: AppointmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AppointmentType.general,
      ),
      estimatedPrice: map['estimatedPrice']?.toDouble(),
      duration: map['duration'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      cancelReason: map['cancelReason'],
      cancelledAt: map['cancelledAt'] != null 
          ? (map['cancelledAt'] as Timestamp).toDate() 
          : null,
      rescheduleReason: map['rescheduleReason'],
      rescheduledAt: map['rescheduledAt'] != null 
          ? (map['rescheduledAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Create copy with updated fields
  AppointmentBooking copyWith({
    String? id,
    String? userId,
    String? petId,
    String? clinicId,
    String? serviceName,
    String? serviceId,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? notes,
    AppointmentStatus? status,
    AppointmentType? type,
    double? estimatedPrice,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancelReason,
    DateTime? cancelledAt,
    String? rescheduleReason,
    DateTime? rescheduledAt,
  }) {
    return AppointmentBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      serviceName: serviceName ?? this.serviceName,
      serviceId: serviceId ?? this.serviceId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      type: type ?? this.type,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
    );
  }

  /// Get formatted appointment date and time
  String get formattedDateTime {
    final dateStr = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
    return '$dateStr at $appointmentTime';
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(appointmentTime.split(':')[0]),
      int.parse(appointmentTime.split(':')[1]),
    );
    return appointmentDateTime.isAfter(now) && 
           (status == AppointmentStatus.pending || status == AppointmentStatus.confirmed);
  }

  /// Check if appointment can be cancelled
  bool get canBeCancelled {
    return status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  }

  /// Check if appointment can be rescheduled
  bool get canBeRescheduled {
    return status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  }

  @override
  String toString() {
    return 'AppointmentBooking(id: $id, serviceName: $serviceName, appointmentDate: $appointmentDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentBooking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}