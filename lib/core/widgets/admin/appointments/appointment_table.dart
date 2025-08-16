// widgets/appointment_table.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../models/appointment_models.dart';
import 'appointment_table_header.dart';
import 'appointment_table_row.dart';

class AppointmentTable extends StatelessWidget {
  final List<Appointment> appointments;
  final Function(Appointment) onEdit;
  final Function(Appointment) onDelete;
  final Function(Appointment) onView;

  const AppointmentTable({
    super.key,
    required this.appointments,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const AppointmentTableHeader(),
          ...appointments.map((appointment) => AppointmentTableRow(
            appointment: appointment,
            onEdit: () => onEdit(appointment),
            onDelete: () => onDelete(appointment),
            onView: () => onView(appointment),
          )),
        ],
      ),
    );
  }
}