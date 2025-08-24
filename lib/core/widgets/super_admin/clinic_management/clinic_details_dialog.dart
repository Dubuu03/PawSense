import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic_registration_model.dart';

class ClinicDetailsDialog extends StatelessWidget {
  final ClinicRegistration clinic;

  const ClinicDetailsDialog({
    Key? key,
    required this.clinic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  size: 32,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.clinicName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusChip(),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection('Clinic Information', [
              _buildInfoRow('Clinic Name', clinic.clinicName),
              _buildInfoRow('License Number', clinic.licenseNumber),
              _buildInfoRow('Address', clinic.address),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Contact Information', [
              _buildInfoRow('Email', clinic.email),
              _buildInfoRow('Phone', clinic.phone),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Administrator', [
              _buildInfoRow('Admin Name', clinic.adminName),
              _buildInfoRow('Admin ID', clinic.adminId),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Application Details', [
              _buildInfoRow('Application Date', _formatDate(clinic.applicationDate)),
              if (clinic.approvedDate != null)
                _buildInfoRow('Approved Date', _formatDate(clinic.approvedDate!)),
              if (clinic.rejectionReason != null && clinic.rejectionReason!.isNotEmpty)
                _buildInfoRow('Rejection Reason', clinic.rejectionReason!),
              if (clinic.suspensionReason != null && clinic.suspensionReason!.isNotEmpty)
                _buildInfoRow('Suspension Reason', clinic.suspensionReason!),
            ]),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                if (clinic.status == ClinicStatus.pending) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop('reject');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop('approve');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
                if (clinic.status == ClinicStatus.approved)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop('suspend');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Suspend'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (clinic.status) {
      case ClinicStatus.pending:
        return Colors.orange;
      case ClinicStatus.approved:
        return Colors.green;
      case ClinicStatus.rejected:
        return Colors.red;
      case ClinicStatus.suspended:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip() {
    final statusColor = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        clinic.status.displayName,
        style: TextStyle(
          color: statusColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
