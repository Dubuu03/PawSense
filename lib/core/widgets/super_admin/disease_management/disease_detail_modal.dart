import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';

class DiseaseDetailModal extends StatelessWidget {
  final SkinDiseaseModel disease;

  const DiseaseDetailModal({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease Image
                    _buildImageSection(),

                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildBasicInfoSection(),

                    const SizedBox(height: 24),

                    // Clinical Details Section
                    _buildClinicalDetailsSection(),

                    const SizedBox(height: 24),

                    // Initial Remedies Section
                    _buildInitialRemediesSection(),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge(
                      disease.detectionMethod == 'ai' ? '✨ AI-Detectable' : 'ℹ️ Info Only',
                      disease.detectionMethod == 'ai'
                          ? const Color(0xFF8B5CF6)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      _getSeverityText(disease.severity),
                      _getSeverityColor(disease.severity),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showFullImage(context),
        child: Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildDiseaseImage(),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Click to view full image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: _buildDiseaseImage(),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pinch to zoom • Drag to pan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseImage() {
    final isNetworkImage = disease.imageUrl.startsWith('http://') ||
        disease.imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        disease.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    } else {
      return Image.asset(
        'assets/img/skin_diseases/${disease.imageUrl}',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }
  }

  Widget _buildImageError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information', Icons.info_outline),
          const SizedBox(height: 16),

          // Description
          _buildInfoRow('Description', disease.description, isMultiline: true),
          const SizedBox(height: 12),

          // Species
          _buildSpeciesRow(),
          const SizedBox(height: 12),

          // Categories
          _buildInfoRow('Categories', disease.categories.join(', ')),
          const SizedBox(height: 12),

          // Duration
          _buildInfoRow('Duration', disease.duration),
          const SizedBox(height: 12),

          // Contagious
          _buildInfoRow(
            'Contagious',
            disease.isContagious ? '⚠️ Yes - Can spread to other animals' : '✓ No',
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Clinical Details', Icons.medical_information),
        const SizedBox(height: 16),

        // Symptoms
        _buildListCard(
          'Symptoms',
          disease.symptoms,
          const Color(0xFFEF4444),
          Icons.sick,
        ),

        const SizedBox(height: 16),

        // Causes
        _buildListCard(
          'Causes',
          disease.causes,
          const Color(0xFFFF9500),
          Icons.psychology,
        ),

        const SizedBox(height: 16),

        // Treatments
        _buildListCard(
          'Treatments',
          disease.treatments,
          const Color(0xFF10B981),
          Icons.healing,
        ),
      ],
    );
  }

  Widget _buildInitialRemediesSection() {
    if (disease.initialRemedies == null) return const SizedBox.shrink();

    final remedies = disease.initialRemedies!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Initial Remedies', Icons.emergency),
        const SizedBox(height: 16),

        // Immediate Care
        if (remedies['immediateCare'] != null)
          _buildRemedyCard(
            remedies['immediateCare'] as Map<String, dynamic>,
            const Color(0xFFEF4444),
            Icons.emergency,
          ),

        const SizedBox(height: 16),

        // Topical Treatment
        if (remedies['topicalTreatment'] != null)
          _buildRemedyCard(
            remedies['topicalTreatment'] as Map<String, dynamic>,
            const Color(0xFF10B981),
            Icons.medical_services,
          ),

        const SizedBox(height: 16),

        // Monitoring
        if (remedies['monitoring'] != null)
          _buildRemedyCard(
            remedies['monitoring'] as Map<String, dynamic>,
            const Color(0xFF007AFF),
            Icons.visibility,
          ),

        const SizedBox(height: 16),

        // When to Seek Help
        if (remedies['whenToSeekHelp'] != null)
          _buildSeekHelpCard(
            remedies['whenToSeekHelp'] as Map<String, dynamic>,
          ),
      ],
    );
  }



  Widget _buildSectionHeader(String title, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Affects',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: disease.species.map((s) {
            final speciesLower = s.toLowerCase().trim();
            final emoji = speciesLower.contains('cat') ? '🐱' : '🐶';
            final name = speciesLower.contains('cat') ? 'Cats' : 'Dogs';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$emoji $name',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard(String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(Map<String, dynamic> remedy, Color color, IconData icon) {
    final title = remedy['title'] as String;
    final actions = remedy['actions'] as List<dynamic>;
    final note = remedy['note'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeekHelpCard(Map<String, dynamic> seekHelp) {
    final title = seekHelp['title'] as String;
    final urgency = seekHelp['urgency'] as String;
    final actions = seekHelp['actions'] as List<dynamic>;

    final urgencyColor = _getUrgencyColor(urgency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgencyColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, size: 18, color: urgencyColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, size: 16, color: urgencyColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }



  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      case 'varies':
        return 'Varies';
      default:
        return severity;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'mild':
        return const Color(0xFF10B981);
      case 'moderate':
        return const Color(0xFFFF9500);
      case 'severe':
        return const Color(0xFFEF4444);
      case 'varies':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return const Color(0xFF10B981);
      case 'moderate':
        return const Color(0xFFFF9500);
      case 'high':
        return const Color(0xFFEF4444);
      case 'emergency':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFFF9500);
    }
  }
}
