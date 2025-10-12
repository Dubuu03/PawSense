import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class DiseaseCard extends StatefulWidget {
  final SkinDiseaseModel disease;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const DiseaseCard({
    super.key,
    required this.disease,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<DiseaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (hovering) {
        setState(() {
          _isHovered = hovering;
        });
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Image - Fixed 60px
            _buildImage(),

            const SizedBox(width: 16),

            // Name - Flex 2
            Expanded(
              flex: 2,
              child: _buildName(),
            ),

            const SizedBox(width: 16),

            // Detection Badge - Fixed 120px
            SizedBox(
              width: 120,
              child: _buildDetectionBadge(),
            ),

            const SizedBox(width: 16),

            // Species - Flex 1
            Expanded(
              flex: 1,
              child: _buildSpeciesChips(),
            ),

            const SizedBox(width: 16),

            // Severity - Fixed 100px
            SizedBox(
              width: 100,
              child: _buildSeverityBadge(),
            ),

            const SizedBox(width: 16),

            // Categories - Flex 2
            Expanded(
              flex: 2,
              child: _buildCategories(),
            ),

            const SizedBox(width: 16),

            // Contagious - Fixed 80px
            SizedBox(
              width: 80,
              child: _buildContagiousIndicator(),
            ),

            const SizedBox(width: 16),

            // Actions - Fixed 48px
            SizedBox(
              width: 48,
              child: _buildActionsMenu(),
            ),

            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: widget.disease.imageUrl.isNotEmpty
            ? _buildDiseaseImage()
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildDiseaseImage() {
    // Check if imageUrl is a network URL or a local asset filename
    final isNetworkImage = widget.disease.imageUrl.startsWith('http://') || 
                           widget.disease.imageUrl.startsWith('https://');
    
    if (isNetworkImage) {
      // Use network image
      return Image.network(
        widget.disease.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderIcon();
        },
      );
    } else {
      // Use asset image - construct path from filename
      final assetPath = 'assets/img/skin_diseases/${widget.disease.imageUrl}';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If asset fails, try as network image
          if (widget.disease.imageUrl.contains('.')) {
            return Image.network(
              widget.disease.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderIcon();
              },
            );
          }
          return _buildPlaceholderIcon();
        },
      );
    }
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.medical_services_outlined,
      color: Colors.grey.shade400,
      size: 28,
    );
  }

  Widget _buildName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.disease.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.disease.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetectionBadge() {
    final isAI = widget.disease.detectionMethod == 'ai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAI
            ? const Color(0xFF8B5CF6).withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAI ? '✨' : 'ℹ️',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isAI ? 'AI' : 'Info',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAI ? const Color(0xFF8B5CF6) : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesChips() {
    // Check for species in case-insensitive manner and handle various formats
    final speciesLower = widget.disease.species.map((s) => s.toLowerCase()).toList();
    final supportsCats = speciesLower.any((s) => s.contains('cat'));
    final supportsDogs = speciesLower.any((s) => s.contains('dog'));
    final supportsBoth = speciesLower.contains('both');

    // If no specific species found, show empty state
    if (!supportsCats && !supportsDogs && !supportsBoth) {
      return Text(
        'Not specified',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Use Row to keep chips in a single line
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supportsCats || supportsBoth)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withOpacity(0.1),
              border: Border.all(color: const Color(0xFFFF9500), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐱', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  'Cats',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        if ((supportsCats || supportsBoth) && (supportsDogs || supportsBoth))
          const SizedBox(width: 6),
        if (supportsDogs || supportsBoth)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF007AFF), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐶', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  'Dogs',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeverityBadge() {
    final severity = widget.disease.severity.toLowerCase();
    Color bgColor;
    Color textColor;

    switch (severity) {
      case 'mild':
        bgColor = const Color(0xFF10B981).withOpacity(0.1);
        textColor = const Color(0xFF10B981);
        break;
      case 'moderate':
        bgColor = const Color(0xFFFF9500).withOpacity(0.1);
        textColor = const Color(0xFFFF9500);
        break;
      case 'severe':
        bgColor = const Color(0xFFEF4444).withOpacity(0.1);
        textColor = const Color(0xFFEF4444);
        break;
      default: // varies
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.disease.severity,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCategories() {
    if (widget.disease.categories.isEmpty) {
      return Text(
        'No categories',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Show all categories separated by commas
    final categoriesText = widget.disease.categories.join(', ');

    return Tooltip(
      message: categoriesText,
      child: Text(
        categoriesText,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildContagiousIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.disease.isContagious ? '⚠️' : '✓',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.disease.isContagious ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.disease.isContagious
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_outlined,
        color: Colors.grey.shade600,
        size: 20,
      ),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              const Text('View Details'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(
                Icons.content_copy_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              const Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            widget.onTap();
            break;
          case 'edit':
            widget.onEdit();
            break;
          case 'duplicate':
            widget.onDuplicate();
            break;
          case 'delete':
            widget.onDelete();
            break;
        }
      },
    );
  }
}
