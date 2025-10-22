// pages/web/superadmin/model_training_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/shared/page_header.dart';
import '../../../core/widgets/superadmin/model_training/training_image_list_view.dart';
import '../../../core/widgets/superadmin/model_training/training_image_preview_panel.dart';
import '../../../core/services/superadmin/model_training_service.dart';

class ModelTrainingManagementScreen extends StatefulWidget {
  const ModelTrainingManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModelTrainingManagementScreen> createState() => _ModelTrainingManagementScreenState();
}

class _ModelTrainingManagementScreenState extends State<ModelTrainingManagementScreen> {
  final ModelTrainingService _trainingService = ModelTrainingService();
  
  // Data
  Map<String, List<TrainingImageData>> _groupedImages = {};
  List<String> _allLabels = [];
  
  // UI State
  TrainingImageData? _selectedImage;
  Set<String> _selectedImageIds = {};
  Set<String> _expandedLabels = {};
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  
  // Search & Filter
  String _searchQuery = '';
  String _filterPetType = 'All';
  String _filterValidationType = 'All'; // All, Validated, Corrected
  
  // Stats
  int _totalImages = 0;
  int _validatedImages = 0;
  int _correctedImages = 0;
  
  @override
  void initState() {
    super.initState();
    _loadTrainingData();
  }

  Future<void> _loadTrainingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _trainingService.fetchAllTrainingData();
      
      // Group images by disease label (cleaned)
      final grouped = <String, List<TrainingImageData>>{};
      int validated = 0;
      int corrected = 0;
      
      for (var imageData in data) {
        // Clean the disease label (remove parentheses if content matches)
        final label = _cleanDiseaseName(imageData.diseaseLabel);
        if (!grouped.containsKey(label)) {
          grouped[label] = [];
        }
        grouped[label]!.add(imageData);
        
        // Count stats
        if (imageData.overallCorrect == true) {
          validated++;
        } else if (imageData.overallCorrect == false) {
          corrected++;
        }
      }
      
      // Sort labels alphabetically
      final sortedLabels = grouped.keys.toList()..sort();
      
      setState(() {
        _groupedImages = grouped;
        _allLabels = sortedLabels;
        _totalImages = data.length;
        _validatedImages = validated;
        _correctedImages = corrected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load training data: $e';
        _isLoading = false;
      });
      print('Error loading training data: $e');
    }
  }
  
  /// Clean disease name by removing parentheses if the content inside matches
  /// E.g., "Alopecia (Alopecia)" -> "Alopecia"
  /// E.g., "Alopecia (Hair Loss)" -> "Alopecia (Hair Loss)" (keeps it if different)
  String _cleanDiseaseName(String name) {
    final regex = RegExp(r'^(.+?)\s*\((.+?)\)$');
    final match = regex.firstMatch(name);
    
    if (match != null) {
      final mainName = match.group(1)?.trim() ?? '';
      final parenthesesContent = match.group(2)?.trim() ?? '';
      
      // If the content in parentheses is the same as the main name, remove it
      if (mainName.toLowerCase() == parenthesesContent.toLowerCase()) {
        return mainName;
      }
    }
    
    return name;
  }

  List<String> _getFilteredLabels() {
    return _allLabels.where((label) {
      // Search filter
      if (_searchQuery.isNotEmpty && !label.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      // Pet type filter
      if (_filterPetType != 'All') {
        final images = _groupedImages[label] ?? [];
        if (images.isEmpty || !images.any((img) => img.petType == _filterPetType)) {
          return false;
        }
      }
      
      // Validation type filter
      if (_filterValidationType != 'All') {
        final images = _groupedImages[label] ?? [];
        if (_filterValidationType == 'Validated') {
          if (!images.any((img) => img.canUseForTraining == true)) {
            return false;
          }
        } else if (_filterValidationType == 'Corrected') {
          if (!images.any((img) => img.canUseForRetraining == true)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }

  List<TrainingImageData> _getImagesForLabel(String label) {
    final images = _groupedImages[label] ?? [];
    
    // Apply pet type filter
    if (_filterPetType != 'All') {
      return images.where((img) => img.petType == _filterPetType).toList();
    }
    
    return images;
  }

  void _selectImage(TrainingImageData image) {
    setState(() {
      _selectedImage = image;
    });
  }

  void _toggleImageSelection(String imageId) {
    setState(() {
      if (_selectedImageIds.contains(imageId)) {
        _selectedImageIds.remove(imageId);
      } else {
        _selectedImageIds.add(imageId);
      }
    });
  }

  void _toggleLabelExpansion(String label) {
    setState(() {
      if (_expandedLabels.contains(label)) {
        _expandedLabels.remove(label);
      } else {
        _expandedLabels.add(label);
      }
    });
  }

  void _selectAllInLabel(String label, bool select) {
    setState(() {
      final images = _getImagesForLabel(label);
      for (var image in images) {
        if (select) {
          _selectedImageIds.add(image.id);
        } else {
          _selectedImageIds.remove(image.id);
        }
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedImageIds.clear();
      final filteredLabels = _getFilteredLabels();
      for (var label in filteredLabels) {
        final images = _getImagesForLabel(label);
        for (var image in images) {
          _selectedImageIds.add(image.id);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedImageIds.clear();
    });
  }

  Future<void> _exportSelected() async {
    if (_selectedImageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Collect selected images grouped by label
      final Map<String, List<TrainingImageData>> selectedByLabel = {};
      
      for (var label in _allLabels) {
        final images = _groupedImages[label] ?? [];
        final selectedInLabel = images.where((img) => _selectedImageIds.contains(img.id)).toList();
        
        if (selectedInLabel.isNotEmpty) {
          selectedByLabel[label] = selectedInLabel;
        }
      }
      
      // Export the images
      await _trainingService.exportTrainingImages(selectedByLabel);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Successfully exported ${_selectedImageIds.length} images grouped by disease label',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Clear selection after export
      setState(() {
        _selectedImageIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          // Stats Bar
          _buildStatsBar(),
          
          // Toolbar
          _buildToolbar(),
          
          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: PageHeader(
              title: 'Model Training Data Management',
              subtitle: 'View, manage, and export validated training images for AI model improvement',
            ),
          ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportSelected,
              icon: const Icon(Icons.download, size: 20),
              label: Text(_isExporting ? 'Exporting...' : 'Export Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Images',
              _totalImages.toString(),
              Icons.image,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Disease Labels',
              _allLabels.length.toString(),
              Icons.label,
              const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Validated',
              _validatedImages.toString(),
              Icons.check_circle,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Corrected',
              _correctedImages.toString(),
              Icons.edit,
              const Color(0xFFF59E0B),
            ),
          ),
          if (_selectedImageIds.isNotEmpty) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Selected',
                _selectedImageIds.length.toString(),
                Icons.check_box,
                const Color(0xFF3B82F6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search disease labels...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Pet Type Filter
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterPetType,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  items: ['All', 'Dog', 'Cat'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _filterPetType = value ?? 'All');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Validation Type Filter
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterValidationType,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  items: ['All', 'Validated', 'Corrected'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _filterValidationType = value ?? 'All');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Select All / Deselect All
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _selectedImageIds.isEmpty ? _selectAll : _deselectAll,
              icon: Icon(
                _selectedImageIds.isEmpty ? Icons.check_box_outline_blank : Icons.check_box,
                size: 18,
                color: AppColors.textSecondary,
              ),
              label: Text(
                _selectedImageIds.isEmpty ? 'Select All' : 'Deselect All',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          
          // Refresh
          const SizedBox(width: 8),
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _loadTrainingData,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh data',
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    final filteredLabels = _getFilteredLabels();
    
    if (filteredLabels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No training data found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search query',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return Row(
      children: [
        // List View (Left Side)
        Expanded(
          flex: 3,
          child: TrainingImageListView(
            labels: filteredLabels,
            groupedImages: _groupedImages,
            expandedLabels: _expandedLabels,
            selectedImageIds: _selectedImageIds,
            selectedImage: _selectedImage,
            onLabelToggle: _toggleLabelExpansion,
            onImageSelect: _selectImage,
            onImageToggleSelection: _toggleImageSelection,
            onSelectAllInLabel: _selectAllInLabel,
            getImagesForLabel: _getImagesForLabel,
          ),
        ),
        
        // Preview Panel (Right Side)
        if (_selectedImage != null)
          Expanded(
            flex: 2,
            child: TrainingImagePreviewPanel(
              image: _selectedImage!,
              onClose: () {
                setState(() => _selectedImage = null);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTrainingData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
