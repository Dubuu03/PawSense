import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/services/clinic/patient_record_service.dart';

class ImprovedPatientCard extends StatelessWidget {
  final PatientRecord patient;
  final VoidCallback onViewDetails;

  const ImprovedPatientCard({
    super.key,
    required this.patient,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding to save space
          child: Column(
            mainAxisSize: MainAxisSize.min, // Let column size itself
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Header with Image/Icon
              Row(
                children: [
                  // Pet Avatar
                  _buildPetAvatar(),
                  const SizedBox(width: 16),
                  // Pet Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient.petName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildHealthStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${patient.petType} • ${patient.breed}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: AppColors.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 12),

              // Pet Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.cake_outlined,
                      'Age',
                      patient.ageString,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.monitor_weight_outlined,
                      'Weight',
                      patient.weightString,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Owner Info
              _buildInfoItem(
                Icons.person_outline,
                'Owner',
                patient.ownerName,
              ),

              const SizedBox(height: 12),

              // Last Visit
              _buildInfoItem(
                Icons.calendar_today_outlined,
                'Last Visit',
                _formatDate(patient.lastVisit),
              ),

              const SizedBox(height: 12),

              // Last Diagnosis
              _buildInfoItem(
                Icons.medical_information_outlined,
                'Last Diagnosis',
                patient.lastDiagnosis,
              ),

              const SizedBox(height: 16),
              Divider(color: AppColors.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 12),

              // Footer with Stats and Action
              Row(
                children: [
                  // Appointment Count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${patient.appointmentCount} ${patient.appointmentCount == 1 ? 'visit' : 'visits'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // View Details Button
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetAvatar() {
    if (patient.imageUrl != null && patient.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(patient.imageUrl!),
        onBackgroundImageError: (_, __) {
          // Fallback to emoji if image fails
        },
        child: patient.imageUrl == null || patient.imageUrl!.isEmpty
            ? Text(
                patient.petEmoji,
                style: const TextStyle(fontSize: 32),
              )
            : null,
      );
    } else {
      return CircleAvatar(
        radius: 32,
        backgroundColor: _getPetTypeColor().withOpacity(0.2),
        child: Text(
          patient.petEmoji,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }
  }

  Widget _buildHealthStatusBadge() {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (patient.healthStatus) {
      case PatientHealthStatus.healthy:
        badgeColor = Colors.green;
        badgeIcon = Icons.favorite;
        badgeText = 'Healthy';
        break;
      case PatientHealthStatus.treatment:
        badgeColor = Colors.orange;
        badgeIcon = Icons.medical_services;
        badgeText = 'Treatment';
        break;
      case PatientHealthStatus.scheduled:
        badgeColor = Colors.blue;
        badgeIcon = Icons.schedule;
        badgeText = 'Scheduled';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline;
        badgeText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPetTypeColor() {
    switch (patient.petType.toLowerCase()) {
      case 'dog':
        return Colors.brown;
      case 'cat':
        return Colors.orange;
      case 'bird':
        return Colors.blue;
      case 'rabbit':
        return Colors.pink;
      case 'hamster':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else {
      // Format as MMM d, yyyy (e.g., Jan 15, 2024)
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
