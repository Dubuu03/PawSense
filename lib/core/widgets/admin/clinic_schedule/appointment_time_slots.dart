import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/services/clinic/appointment_service.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart' as AppointmentModels;
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/models/clinic/time_slot.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/appointment_details_modal.dart';

class AppointmentTimeSlots extends StatefulWidget {
  final String selectedDay;
  final String? clinicId;
  final DateTime selectedDate;

  const AppointmentTimeSlots({
    super.key,
    required this.selectedDay,
    required this.clinicId,
    required this.selectedDate,
  });

  @override
  State<AppointmentTimeSlots> createState() => _AppointmentTimeSlotsState();
}

class _AppointmentTimeSlotsState extends State<AppointmentTimeSlots> {
  List<AppointmentModels.Appointment> _appointments = [];
  ClinicScheduleModel? _schedule;
  bool _isLoading = true;
  String? _error;
  String? _actualClinicId;

  @override
  void initState() {
    super.initState();
    _loadAppointmentsAndSchedule();
  }

  @override
  void didUpdateWidget(AppointmentTimeSlots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.clinicId != widget.clinicId) {
      _loadAppointmentsAndSchedule();
    }
  }

  Future<void> _loadAppointmentsAndSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get actual clinic ID using the same pattern as appointment management
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Find the clinic document for this user (same as appointment management)
      final clinicQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        setState(() {
          _error = 'No approved clinic found for this user';
          _isLoading = false;
        });
        return;
      }

      _actualClinicId = clinicQuery.docs.first.id;
      
      // Load clinic schedule for the selected day
      _schedule = await ClinicScheduleService.getScheduleForDay(
        _actualClinicId!,
        widget.selectedDay,
      );

      // Load appointments for the selected date (only confirmed status)
      final startOfDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      final endOfDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        23,
        59,
        59,
      );

      // Use the same pattern as appointment management but filter for confirmed
      final allAppointments = await AppointmentService.getClinicAppointments(
        _actualClinicId!,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Filter only confirmed appointments
      _appointments = allAppointments.where((appointment) => 
        appointment.status == AppointmentModels.AppointmentStatus.confirmed
      ).toList();

    } catch (e) {
      print('Error loading appointments and schedule: $e');
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TimeSlot> _generateTimeSlots() {
    if (_schedule == null || !_schedule!.isOpen) return [];

    final timeSlots = <TimeSlot>[];
    
    try {
      final openParts = _schedule!.openTime!.split(':');
      final closeParts = _schedule!.closeTime!.split(':');
      
      final openHour = int.parse(openParts[0]);
      final closeHour = int.parse(closeParts[0]);
      
      // Generate hourly slots
      for (int hour = openHour; hour < closeHour; hour++) {
        final startTime = '${hour.toString().padLeft(2, '0')}:00';
        final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';
        
        // Count appointments in this hour slot
        int appointmentsInSlot = 0;
        for (final appointment in _appointments) {
          try {
            final appointmentHour = int.parse(appointment.time.split(':')[0]);
            if (appointmentHour == hour) {
              appointmentsInSlot++;
            }
          } catch (e) {
            print('Error parsing appointment time: ${appointment.time}');
          }
        }
        
        // Calculate max slots based on clinic configuration
        final maxSlotsPerHour = _schedule!.slotsPerHour;
        
        // Calculate utilization percentage
        final utilization = maxSlotsPerHour > 0 
          ? (appointmentsInSlot / maxSlotsPerHour * 100).toDouble() 
          : 0.0;
        
        // Determine progress color based on utilization
        Color progressColor;
        if (utilization >= 90) {
          progressColor = AppColors.error;
        } else if (utilization >= 70) {
          progressColor = AppColors.warning;
        } else if (utilization >= 50) {
          progressColor = Colors.amber.shade600;
        } else {
          progressColor = AppColors.success;
        }
        
        timeSlots.add(TimeSlot(
          startTime: startTime,
          endTime: endTime,
          type: '', // Remove type text
          currentAppointments: appointmentsInSlot,
          maxAppointments: maxSlotsPerHour,
          utilizationPercentage: utilization,
          progressColor: progressColor,
        ));
      }
    } catch (e) {
      print('Error generating time slots: $e');
    }
    
    return timeSlots;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Loading appointments...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_schedule == null || !_schedule!.isOpen) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Clinic is closed on ${widget.selectedDay}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeSlots = _generateTimeSlots();

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (keeping the old design)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.selectedDay} Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(widget.selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Optional: Add time slot button if needed
              ],
            ),
            
            SizedBox(height: 16),
            Divider(color: AppColors.border),
            SizedBox(height: 16),

            // Time slots with old UI design
            if (timeSlots.isEmpty) ...[
              Center(
                child: Text(
                  'No time slots available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: timeSlots.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildTimeSlotItem(timeSlots[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotItem(TimeSlot timeSlot) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row with time, details, and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeColumn(timeSlot),
                SizedBox(width: 16),
                Expanded(child: _buildDetailsColumn(timeSlot)),
                SizedBox(width: 8),
                _buildStatusBadge(timeSlot),
              ],
            ),
            SizedBox(height: 16),
            // Appointments display
            ..._buildAppointmentsList(timeSlot),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(TimeSlot timeSlot) {
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeSlot.startTime,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            timeSlot.endTime,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsColumn(TimeSlot timeSlot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              timeSlot.type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6), // Blue color for type
              ),
            ),
            Text(
              timeSlot.appointmentText,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: timeSlot.utilizationPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: timeSlot.progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '${timeSlot.utilizationPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TimeSlot timeSlot) {
    final isAvailable = timeSlot.currentAppointments < timeSlot.maxAppointments;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable 
          ? AppColors.success.withOpacity(0.1)
          : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Full',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isAvailable ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  List<Widget> _buildAppointmentsList(TimeSlot timeSlot) {
    // Find appointments for this time slot
    final hourString = timeSlot.startTime.split(':')[0];
    final appointmentsInSlot = _appointments.where((appointment) {
      try {
        final appointmentHour = int.parse(appointment.time.split(':')[0]);
        return appointmentHour.toString().padLeft(2, '0') == hourString.padLeft(2, '0');
      } catch (e) {
        return false;
      }
    }).toList();

    if (appointmentsInSlot.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_available,
                color: AppColors.success,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'No appointments scheduled for this hour',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return appointmentsInSlot.map((appointment) => _buildDetailedAppointmentItem(appointment)).toList();
  }

  Widget _buildDetailedAppointmentItem(AppointmentModels.Appointment appointment) {
    return GestureDetector(
      onTap: () => AppointmentDetailsModal.show(context, appointment),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Pet image or emoji
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: appointment.pet.imageUrl != null && appointment.pet.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        appointment.pet.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              appointment.pet.emoji,
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        appointment.pet.emoji,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
            SizedBox(width: 12),
            
            // Pet name and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.pet.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    appointment.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Click indicator
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}