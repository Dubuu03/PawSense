// screens/appointment_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/models/appointment_models.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/new_appointment_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_table.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  String searchQuery = '';
  String selectedStatus = 'All Status';

  // Sample data
  final List<Appointment> appointments = [
    Appointment(
      date: '2025-01-20',
      time: '09:00 AM',
      pet: Pet(name: 'Max', type: 'Dog', emoji: '🐕'),
      diseaseReason: 'Skin Allergies',
      owner: Owner(name: 'John Smith', phone: '+1 (555) 123-4567'),
      status: AppointmentStatus.pending,
    ),
    Appointment(
      date: '2025-01-20',
      time: '10:30 AM',
      pet: Pet(name: 'Luna', type: 'Cat', emoji: '🐱'),
      diseaseReason: 'Routine Checkup',
      owner: Owner(name: 'Sarah Johnson', phone: '+1 (555) 987-6543'),
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      date: '2025-01-21',
      time: '02:00 PM',
      pet: Pet(name: 'Buddy', type: 'Dog', emoji: '🐕'),
      diseaseReason: 'Dental Cleaning',
      owner: Owner(name: 'Mike Wilson', phone: '+1 (555) 456-7890'),
      status: AppointmentStatus.completed,
    ),
    Appointment(
      date: '2025-01-21',
      time: '03:30 PM',
      pet: Pet(name: 'Whiskers', type: 'Cat', emoji: '🐱'),
      diseaseReason: 'Digestive Issues',
      owner: Owner(name: 'Emily Davis', phone: '+1 (555) 234-5678'),
      status: AppointmentStatus.pending,
    ),
    Appointment(
      date: '2025-01-22',
      time: '04:45 PM',
      pet: Pet(name: 'Rocky', type: 'Dog', emoji: '🐕'),
      diseaseReason: 'Emergency Visit',
      owner: Owner(name: 'David Brown', phone: '+1 (555) 345-6789'),
      status: AppointmentStatus.cancelled,
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    // Filter appointments for the table only
    List<Appointment> filteredAppointments = appointments.where((appointment) {
      if (selectedStatus == 'All Status') return true;
      return appointment.status.name.toLowerCase() ==
            selectedStatus.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header uses full list
            AppointmentHeader(
              onNewAppointment: () {
                showDialog(
                  context: context,
                  builder: (_) => NewAppointmentModal(
                    onSchedule: (appointment) {
                      // for now, just show a confirmation snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scheduled ${appointment['petName']} on ${appointment['date']}')),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Summary uses full list
            AppointmentSummary(appointments: appointments),
            const SizedBox(height: 24),

            AppointmentFilters(
              searchQuery: searchQuery,
              selectedStatus: selectedStatus,
              onSearchChanged: (query) => setState(() => searchQuery = query),
              onStatusChanged: (status) => setState(() => selectedStatus = status),
            ),

            const SizedBox(height: 16),

            // Table uses filtered list
            AppointmentTable(
              appointments: filteredAppointments,
              onEdit: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit ${appointment.pet.name}')),
                );
              },
              onDelete: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete ${appointment.pet.name}')),
                );
              },
              onView: (appointment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View ${appointment.pet.name}')),
                );
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}