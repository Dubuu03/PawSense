class ScheduleStats {
  final int totalAppointments;
  final int maxCapacity;
  final double utilization;
  final int timeSlots;

  ScheduleStats({
    required this.totalAppointments,
    required this.maxCapacity,
    required this.utilization,
    required this.timeSlots,
  });
}