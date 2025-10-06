import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/user/pdf_generation_service.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';

class AppointmentDetailsModal extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onAcceptAppointment;
  final bool showAcceptButton;

  const AppointmentDetailsModal({
    super.key,
    required this.appointment,
    this.onAcceptAppointment,
    this.showAcceptButton = false,
  });

  static void show(
    BuildContext context, 
    Appointment appointment, {
    VoidCallback? onAcceptAppointment,
    bool showAcceptButton = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AppointmentDetailsModal(
        appointment: appointment,
        onAcceptAppointment: onAcceptAppointment,
        showAcceptButton: showAcceptButton,
      ),
    );
  }

  @override
  State<AppointmentDetailsModal> createState() => _AppointmentDetailsModalState();
}

class _AppointmentDetailsModalState extends State<AppointmentDetailsModal> {
  Map<String, dynamic>? _assessmentData;
  bool _isLoadingAssessment = false;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    _loadAssessmentData();
  }

  Future<void> _loadAssessmentData() async {
    if (widget.appointment.assessmentResultId == null || 
        widget.appointment.assessmentResultId!.isEmpty) {
      return;
    }

    setState(() => _isLoadingAssessment = true);

    try {
      final assessmentDoc = await FirebaseFirestore.instance
          .collection('assessment_results')
          .doc(widget.appointment.assessmentResultId)
          .get();
      
      if (assessmentDoc.exists && mounted) {
        setState(() {
          _assessmentData = assessmentDoc.data();
          _isLoadingAssessment = false;
        });
      }
    } catch (e) {
      print('Error loading assessment data: $e');
      if (mounted) {
        setState(() => _isLoadingAssessment = false);
      }
    }
  }

  Future<void> _generatePDF() async {
    if (_isGeneratingPDF) return;
    
    setState(() => _isGeneratingPDF = true);
    
    try {
      if (widget.appointment.assessmentResultId == null || 
          widget.appointment.assessmentResultId!.isEmpty) {
        throw Exception('No assessment data available for this appointment');
      }

      final assessmentService = AssessmentResultService();
      final assessmentResult = await assessmentService.getAssessmentResultById(
        widget.appointment.assessmentResultId!
      );
      
      if (assessmentResult == null) {
        throw Exception('Assessment data not found');
      }

      final userModel = UserModel(
        uid: widget.appointment.owner.id,
        username: widget.appointment.owner.name,
        email: widget.appointment.owner.email ?? '',
        contactNumber: widget.appointment.owner.phone,
        createdAt: DateTime.now(),
        role: 'user',
      );

      final pdfBytes = await PDFGenerationService.generateAssessmentPDF(
        user: userModel,
        assessmentResult: assessmentResult,
      );

      final fileName = 'PawSense_Assessment_${widget.appointment.pet.name}_${DateTime.now().millisecondsSinceEpoch}';
      await PDFGenerationService.saveWithSystemDialog(pdfBytes, fileName);

      if (mounted) {
        setState(() => _isGeneratingPDF = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF downloaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(widget.appointment.status),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(widget.appointment.status),
        style: TextStyle(
          color: _getStatusColor(widget.appointment.status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPetImage() {
    if (widget.appointment.pet.imageUrl != null && widget.appointment.pet.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.appointment.pet.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.appointment.pet.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.appointment.pet.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  List<Widget> _buildAssessmentResults() {
    final analysisResults = _assessmentData!['analysisResults'] as List?;
    
    if (analysisResults == null || analysisResults.isEmpty) {
      return [
        const Text(
          'No analysis results available',
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }
    
    return analysisResults.map<Widget>((result) {
      if (result is! Map<String, dynamic>) return const SizedBox.shrink();
      
      final condition = result['condition'] as String?;
      final percentage = result['percentage'] as num?;
      final colorHex = result['colorHex'] as String?;
      
      if (condition == null || percentage == null) return const SizedBox.shrink();
      
      Color conditionColor = const Color(0xFF7C3AED);
      if (colorHex != null && colorHex.startsWith('#')) {
        try {
          conditionColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
        } catch (e) {
          // Use default color if parsing fails
        }
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: conditionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                condition,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: conditionColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.parse('${widget.appointment.date} ${widget.appointment.time}:00');
    final formattedDate = '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    final formattedTime = _formatTime(widget.appointment.time);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pet Information
            Row(
              children: [
                _buildPetImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.pet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.appointment.pet.type}${widget.appointment.pet.breed != null ? ' • ${widget.appointment.pet.breed}' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.appointment.pet.age != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.appointment.pet.age} years old',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 24),

            // Appointment Information
            _buildInfoSection('Date & Time', '$formattedDate at $formattedTime'),
            const SizedBox(height: 16),
            _buildInfoSection('Reason for Visit', widget.appointment.diseaseReason),
            const SizedBox(height: 16),

            // Owner Information
            _buildInfoSection(
              'Owner',
              '${widget.appointment.owner.name}\n${widget.appointment.owner.phone}${widget.appointment.owner.email != null && widget.appointment.owner.email!.isNotEmpty ? '\n${widget.appointment.owner.email}' : ''}',
            ),

            // Notes (if available)
            if (widget.appointment.notes != null && widget.appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Notes', widget.appointment.notes!),
            ],

            // AI Assessment Results
            if (_isLoadingAssessment)
              ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ]
            else if (_assessmentData != null)
              ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'AI Assessment Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildAssessmentResults(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPDF ? null : _generatePDF,
                    icon: _isGeneratingPDF
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(_isGeneratingPDF ? 'Generating PDF...' : 'Download Assessment PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],

            // Accept Button (if needed)
            if (widget.showAcceptButton && widget.onAcceptAppointment != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onAcceptAppointment!();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}