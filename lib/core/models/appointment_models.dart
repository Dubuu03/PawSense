// models/appointment_models.dart

class Pet {
  final String name;
  final String type;
  final String emoji;

  Pet({required this.name, required this.type, required this.emoji});
}

class Owner {
  final String name;
  final String phone;

  Owner({required this.name, required this.phone});
}

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class Appointment {
  final String date;
  final String time;
  final Pet pet;
  final String diseaseReason;
  final Owner owner;
  final AppointmentStatus status;

  Appointment({
    required this.date,
    required this.time,
    required this.pet,
    required this.diseaseReason,
    required this.owner,
    required this.status,
  });
}