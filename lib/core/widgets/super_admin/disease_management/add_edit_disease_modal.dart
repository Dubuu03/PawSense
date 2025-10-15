import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/services/super_admin/skin_diseases_service.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';

class AddEditDiseaseModal extends StatefulWidget {
  final SkinDiseaseModel? disease;
  final VoidCallback onSuccess;

  const AddEditDiseaseModal({
    super.key,
    this.disease,
    required this.onSuccess,
  });

  @override
  State<AddEditDiseaseModal> createState() => _AddEditDiseaseModalState();
}

class _AddEditDiseaseModalState extends State<AddEditDiseaseModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage; // Error message to display in modal
  
  // Cloudinary service
  final _cloudinaryService = CloudinaryService();

  // Tab 1: Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String _detectionMethod = 'ai';
  final Set<String> _selectedSpecies = {};
  String _severity = 'mild';
  final Set<String> _selectedCategories = {};
  bool _isContagious = false;

  // Tab 2: Clinical Details
  final List<TextEditingController> _symptomsControllers = [];
  final List<TextEditingController> _causesControllers = [];
  final List<TextEditingController> _treatmentsControllers = [];

  // Tab 3: Initial Remedies
  final _immediateCareTitle = TextEditingController();
  final List<TextEditingController> _immediateCareActions = [];
  final _topicalTreatmentTitle = TextEditingController();
  final List<TextEditingController> _topicalTreatmentActions = [];
  final _topicalTreatmentNote = TextEditingController();
  final _monitoringTitle = TextEditingController();
  final List<TextEditingController> _monitoringActions = [];
  final _seekHelpTitle = TextEditingController();
  String _seekHelpUrgency = 'moderate';
  final List<TextEditingController> _seekHelpActions = [];

  // Tab 4: Media
  final _imageUrlController = TextEditingController();
  File? _selectedImageFile;
  bool _isUploadingImage = false;

  // Available options
  final List<String> _availableCategories = [
    'Parasitic',
    'Bacterial',
    'Fungal',
    'Allergic',
    'Autoimmune',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDiseaseData();
  }

  void _loadDiseaseData() {
    if (widget.disease != null) {
      final disease = widget.disease!;

      // Tab 1: Basic Info
      _nameController.text = disease.name;
      _descriptionController.text = disease.description;
      _durationController.text = disease.duration;
      _detectionMethod = disease.detectionMethod;
      _selectedSpecies.addAll(disease.species);
      _severity = disease.severity;
      _selectedCategories.addAll(disease.categories);
      _isContagious = disease.isContagious;

      // Tab 2: Clinical Details
      for (var symptom in disease.symptoms) {
        _symptomsControllers.add(TextEditingController(text: symptom));
      }
      for (var cause in disease.causes) {
        _causesControllers.add(TextEditingController(text: cause));
      }
      for (var treatment in disease.treatments) {
        _treatmentsControllers.add(TextEditingController(text: treatment));
      }

      // Tab 3: Initial Remedies
      if (disease.initialRemedies != null) {
        final remedies = disease.initialRemedies!;

        // Immediate Care
        final immediateCare = remedies['immediateCare'] as Map<String, dynamic>?;
        if (immediateCare != null) {
          _immediateCareTitle.text = immediateCare['title'] ?? 'Immediate Care';
          final actions = immediateCare['actions'] as List<dynamic>?;
          if (actions != null) {
            for (var action in actions) {
              _immediateCareActions.add(TextEditingController(text: action.toString()));
            }
          }
        }

        // Topical Treatment
        final topicalTreatment = remedies['topicalTreatment'] as Map<String, dynamic>?;
        if (topicalTreatment != null) {
          _topicalTreatmentTitle.text = topicalTreatment['title'] ?? 'Topical Treatment';
          final actions = topicalTreatment['actions'] as List<dynamic>?;
          if (actions != null) {
            for (var action in actions) {
              _topicalTreatmentActions.add(TextEditingController(text: action.toString()));
            }
          }
          _topicalTreatmentNote.text = topicalTreatment['note']?.toString() ?? '';
        }

        // Monitoring
        final monitoring = remedies['monitoring'] as Map<String, dynamic>?;
        if (monitoring != null) {
          _monitoringTitle.text = monitoring['title'] ?? 'Monitoring';
          final actions = monitoring['actions'] as List<dynamic>?;
          if (actions != null) {
            for (var action in actions) {
              _monitoringActions.add(TextEditingController(text: action.toString()));
            }
          }
        }

        // When to Seek Help
        final whenToSeekHelp = remedies['whenToSeekHelp'] as Map<String, dynamic>?;
        if (whenToSeekHelp != null) {
          _seekHelpTitle.text = whenToSeekHelp['title'] ?? 'When to Seek Veterinary Help';
          
          // Validate and normalize urgency value
          final rawUrgency = whenToSeekHelp['urgency']?.toString() ?? 'moderate';
          const validUrgencies = ['low', 'moderate', 'high', 'emergency'];
          _seekHelpUrgency = validUrgencies.contains(rawUrgency) ? rawUrgency : 'moderate';
          
          final actions = whenToSeekHelp['actions'] as List<dynamic>?;
          if (actions != null) {
            for (var action in actions) {
              _seekHelpActions.add(TextEditingController(text: action.toString()));
            }
          }
        }

        // Ensure minimum fields are present
        if (_immediateCareActions.isEmpty) {
          _addFieldToList(_immediateCareActions, '');
          _addFieldToList(_immediateCareActions, '');
        }
        if (_topicalTreatmentActions.isEmpty) {
          _addFieldToList(_topicalTreatmentActions, '');
          _addFieldToList(_topicalTreatmentActions, '');
        }
        if (_monitoringActions.isEmpty) {
          _addFieldToList(_monitoringActions, '');
          _addFieldToList(_monitoringActions, '');
        }
        if (_seekHelpActions.isEmpty) {
          _addFieldToList(_seekHelpActions, '');
          _addFieldToList(_seekHelpActions, '');
        }
      } else {
        _initializeDefaultRemedies();
      }

      // Tab 4: Media
      _imageUrlController.text = disease.imageUrl;
    } else {
      // Initialize with empty values for new disease
      _initializeEmptyFields();
    }
  }

  void _initializeDefaultRemedies() {
    _immediateCareTitle.text = 'Immediate Care';
    _addFieldToList(_immediateCareActions, '');
    _addFieldToList(_immediateCareActions, '');

    _topicalTreatmentTitle.text = 'Topical Treatment';
    _addFieldToList(_topicalTreatmentActions, '');
    _addFieldToList(_topicalTreatmentActions, '');

    _monitoringTitle.text = 'Monitoring';
    _addFieldToList(_monitoringActions, '');
    _addFieldToList(_monitoringActions, '');

    _seekHelpTitle.text = 'When to Seek Veterinary Help';
    _seekHelpUrgency = 'moderate';
    _addFieldToList(_seekHelpActions, '');
    _addFieldToList(_seekHelpActions, '');
  }

  void _initializeEmptyFields() {
    // Tab 2: Clinical Details - minimum required fields
    _addFieldToList(_symptomsControllers, '');
    _addFieldToList(_symptomsControllers, '');
    _addFieldToList(_symptomsControllers, '');

    _addFieldToList(_causesControllers, '');
    _addFieldToList(_causesControllers, '');

    _addFieldToList(_treatmentsControllers, '');
    _addFieldToList(_treatmentsControllers, '');
    _addFieldToList(_treatmentsControllers, '');

    // Tab 3: Initialize default remedies
    _initializeDefaultRemedies();
  }

  void _addFieldToList(List<TextEditingController> list, String text) {
    list.add(TextEditingController(text: text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();

    for (var controller in _symptomsControllers) {
      controller.dispose();
    }
    for (var controller in _causesControllers) {
      controller.dispose();
    }
    for (var controller in _treatmentsControllers) {
      controller.dispose();
    }

    _immediateCareTitle.dispose();
    for (var controller in _immediateCareActions) {
      controller.dispose();
    }
    _topicalTreatmentTitle.dispose();
    for (var controller in _topicalTreatmentActions) {
      controller.dispose();
    }
    _topicalTreatmentNote.dispose();
    _monitoringTitle.dispose();
    for (var controller in _monitoringActions) {
      controller.dispose();
    }
    _seekHelpTitle.dispose();
    for (var controller in _seekHelpActions) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _saveDisease() async {
    if (!_formKey.currentState!.validate()) {
      // Find which tab has errors and switch to it
      _findAndSwitchToErrorTab();
      return;
    }

    // Additional validation
    if (_selectedSpecies.isEmpty) {
      _showError('Please select at least one species');
      _tabController.animateTo(0);
      return;
    }

    if (_selectedCategories.isEmpty) {
      _showError('Please select at least one category');
      _tabController.animateTo(0);
      return;
    }

    final symptoms = _getControllerValues(_symptomsControllers);
    if (symptoms.length < 3) {
      _showError('Please add at least 3 symptoms');
      _tabController.animateTo(1);
      return;
    }

    final causes = _getControllerValues(_causesControllers);
    if (causes.length < 2) {
      _showError('Please add at least 2 causes');
      _tabController.animateTo(1);
      return;
    }

    final treatments = _getControllerValues(_treatmentsControllers);
    if (treatments.length < 3) {
      _showError('Please add at least 3 treatments');
      _tabController.animateTo(1);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final diseaseModel = SkinDiseaseModel(
        id: widget.disease?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        detectionMethod: _detectionMethod,
        species: _selectedSpecies.toList(),
        severity: _severity,
        categories: _selectedCategories.toList(),
        isContagious: _isContagious,
        duration: _durationController.text.trim().isEmpty
            ? 'Varies'
            : _durationController.text.trim(),
        symptoms: symptoms,
        causes: causes,
        treatments: treatments,
        initialRemedies: {
          'immediateCare': {
            'title': _immediateCareTitle.text.trim(),
            'actions': _getControllerValues(_immediateCareActions),
          },
          'topicalTreatment': {
            'title': _topicalTreatmentTitle.text.trim(),
            'actions': _getControllerValues(_topicalTreatmentActions),
            'note': _topicalTreatmentNote.text.trim().isEmpty
                ? null
                : _topicalTreatmentNote.text.trim(),
          },
          'monitoring': {
            'title': _monitoringTitle.text.trim(),
            'actions': _getControllerValues(_monitoringActions),
          },
          'whenToSeekHelp': {
            'title': _seekHelpTitle.text.trim(),
            'urgency': _seekHelpUrgency,
            'actions': _getControllerValues(_seekHelpActions),
          },
        },
        imageUrl: _imageUrlController.text.trim(),
        viewCount: widget.disease?.viewCount ?? 0,
        createdAt: widget.disease?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.disease != null) {
        // Update existing disease
        await SkinDiseasesService.updateDisease(
          widget.disease!.id,
          diseaseModel,
        );
        _showSuccess('Disease updated successfully');
      } else {
        // Create new disease
        await SkinDiseasesService.createDisease(diseaseModel);
        _showSuccess('Disease created successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      _showError('Error saving disease: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<String> _getControllerValues(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  void _findAndSwitchToErrorTab() {
    // Check Tab 1
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _tabController.animateTo(0);
      return;
    }

    // Check Tab 2
    final symptoms = _getControllerValues(_symptomsControllers);
    final causes = _getControllerValues(_causesControllers);
    final treatments = _getControllerValues(_treatmentsControllers);
    if (symptoms.length < 3 || causes.length < 2 || treatments.length < 3) {
      _tabController.animateTo(1);
      return;
    }

    // Check Tab 3
    final immediateCare = _getControllerValues(_immediateCareActions);
    final topical = _getControllerValues(_topicalTreatmentActions);
    final monitoring = _getControllerValues(_monitoringActions);
    final seekHelp = _getControllerValues(_seekHelpActions);
    if (immediateCare.length < 2 ||
        topical.length < 2 ||
        monitoring.length < 2 ||
        seekHelp.length < 2) {
      _tabController.animateTo(2);
      return;
    }

    // Check Tab 4
    if (_imageUrlController.text.trim().isEmpty) {
      _tabController.animateTo(3);
      return;
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
      // Auto-hide error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Error Banner (displayed inside modal)
            if (_errorMessage != null) _buildErrorBanner(),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildClinicalDetailsTab(),
                    _buildInitialRemediesTab(),
                    _buildMediaTab(),
                  ],
                ),
              ),
            ),

            // Footer Actions
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: _clearError,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.red.shade700,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  widget.disease != null ? 'Edit Disease' : 'Add New Disease',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.disease != null
                      ? 'Update disease information and clinical details'
                      : 'Add a new skin disease to the database',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF8B5CF6),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Basic Info'),
          Tab(text: 'Clinical Details'),
          Tab(text: 'Initial Remedies'),
          Tab(text: 'Media'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          _buildSectionTitle('Disease Name', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter disease name',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Disease name is required';
              }
              if (value.trim().length < 5) {
                return 'Disease name must be at least 5 characters';
              }
              if (value.trim().length > 100) {
                return 'Disease name must not exceed 100 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Description Field
          _buildSectionTitle('Description', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Enter a brief description of the disease',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              if (value.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              if (value.trim().length > 500) {
                return 'Description must not exceed 500 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Detection Method
          _buildSectionTitle('Detection Method', required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: 'ai',
                  groupValue: _detectionMethod,
                  onChanged: (value) {
                    setState(() {
                      _detectionMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Text('✨', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('AI-Detectable'),
                    ],
                  ),
                  subtitle: const Text('Can be detected by AI model'),
                  activeColor: const Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'info',
                  groupValue: _detectionMethod,
                  onChanged: (value) {
                    setState(() {
                      _detectionMethod = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Text('ℹ️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Info Only'),
                    ],
                  ),
                  subtitle: const Text('Information/reference only'),
                  activeColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Species Selection
          _buildSectionTitle('Species', required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _selectedSpecies.contains('cats'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedSpecies.add('cats');
                      } else {
                        _selectedSpecies.remove('cats');
                      }
                    });
                  },
                  title: const Row(
                    children: [
                      Text('🐱', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Cats'),
                    ],
                  ),
                  activeColor: const Color(0xFFFF9500),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: _selectedSpecies.contains('dogs'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedSpecies.add('dogs');
                      } else {
                        _selectedSpecies.remove('dogs');
                      }
                    });
                  },
                  title: const Row(
                    children: [
                      Text('🐶', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Dogs'),
                    ],
                  ),
                  activeColor: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          if (_selectedSpecies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Please select at least one species',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Severity Dropdown
          _buildSectionTitle('Severity', required: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.warning_amber_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'mild', child: Text('Mild')),
              DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
              DropdownMenuItem(value: 'severe', child: Text('Severe')),
              DropdownMenuItem(value: 'varies', child: Text('Varies')),
            ],
            onChanged: (value) {
              setState(() {
                _severity = value!;
              });
            },
          ),

          const SizedBox(height: 24),

          // Categories Selection
          _buildSectionTitle('Categories', required: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                checkmarkColor: const Color(0xFF8B5CF6),
              );
            }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one category',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Duration Field (Optional)
          _buildSectionTitle('Duration'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _durationController,
            decoration: InputDecoration(
              hintText: 'e.g., 1-2 weeks, varies, chronic',
              prefixIcon: const Icon(Icons.schedule_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contagious Switch
          _buildSectionTitle('Contagious'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Is this disease contagious?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Can be transmitted between animals',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isContagious,
                  onChanged: (value) {
                    setState(() {
                      _isContagious = value;
                    });
                  },
                  activeColor: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symptoms Section
          _buildDynamicListSection(
            title: 'Symptoms',
            subtitle: 'Minimum 3 required',
            controllers: _symptomsControllers,
            hintText: 'Enter a symptom',
            minRequired: 3,
          ),

          const SizedBox(height: 32),

          // Causes Section
          _buildDynamicListSection(
            title: 'Causes',
            subtitle: 'Minimum 2 required',
            controllers: _causesControllers,
            hintText: 'Enter a cause',
            minRequired: 2,
          ),

          const SizedBox(height: 32),

          // Treatments Section
          _buildDynamicListSection(
            title: 'Treatments',
            subtitle: 'Minimum 3 required',
            controllers: _treatmentsControllers,
            hintText: 'Enter a treatment',
            minRequired: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialRemediesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immediate Care Section
          _buildRemedySection(
            titleController: _immediateCareTitle,
            actionsControllers: _immediateCareActions,
            noteController: null,
            urgencyValue: null,
            onUrgencyChanged: null,
            icon: Icons.emergency,
            color: const Color(0xFFEF4444),
          ),

          const SizedBox(height: 32),

          // Topical Treatment Section
          _buildRemedySection(
            titleController: _topicalTreatmentTitle,
            actionsControllers: _topicalTreatmentActions,
            noteController: _topicalTreatmentNote,
            urgencyValue: null,
            onUrgencyChanged: null,
            icon: Icons.medical_services,
            color: const Color(0xFF10B981),
          ),

          const SizedBox(height: 32),

          // Monitoring Section
          _buildRemedySection(
            titleController: _monitoringTitle,
            actionsControllers: _monitoringActions,
            noteController: null,
            urgencyValue: null,
            onUrgencyChanged: null,
            icon: Icons.visibility,
            color: const Color(0xFF007AFF),
          ),

          const SizedBox(height: 32),

          // When to Seek Help Section
          _buildRemedySection(
            titleController: _seekHelpTitle,
            actionsControllers: _seekHelpActions,
            noteController: null,
            urgencyValue: _seekHelpUrgency,
            onUrgencyChanged: (value) {
              setState(() {
                _seekHelpUrgency = value!;
              });
            },
            icon: Icons.local_hospital,
            color: const Color(0xFFFF9500),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSaveImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });

      // Validate that disease name is filled first
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _isUploadingImage = false;
        });
        _showError('⚠️ Please enter a disease name first before uploading an image');
        return;
      }

      // Pick image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        try {
          String cloudinaryUrl;

          // Upload to Cloudinary based on platform
          if (kIsWeb && result.files.single.bytes != null) {
            // Web platform - use bytes
            final bytes = result.files.single.bytes!;
            final fileName = result.files.single.name;
            
            cloudinaryUrl = await _cloudinaryService.uploadImageFromBytes(
              bytes,
              fileName,
              folder: 'skin_diseases',
            );
          } else if (result.files.single.path != null) {
            // Mobile/Desktop - use file path
            final filePath = result.files.single.path!;
            
            cloudinaryUrl = await _cloudinaryService.uploadImageFromFile(
              filePath,
              folder: 'skin_diseases',
            );
          } else {
            throw Exception('Unable to access file data');
          }

          // Update image URL in controller
          setState(() {
            _imageUrlController.text = cloudinaryUrl;
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Image uploaded successfully to Cloudinary'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          print('✅ Image uploaded to Cloudinary: $cloudinaryUrl');
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
          });
          _showError('Failed to upload image to Cloudinary: ${e.toString()}');
          print('❌ Cloudinary upload error: $e');
        }
      } else {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _showError('Error: ${e.toString()}');
      print('❌ Image picker error: $e');
    }
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Image', required: true),
          const SizedBox(height: 8),
          Text(
            'Upload an image file to Cloudinary or provide a URL',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Upload Image Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndSaveImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploadingImage ? 'Uploading to Cloudinary...' : 'Upload Image to Cloudinary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider with "OR"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 16),

          // Image URL Input
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              hintText: 'Enter Cloudinary URL or other image URL',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Full URL required (e.g., https://res.cloudinary.com/...)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Image URL is required';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedImageFile = null; // Clear selected file when typing
              });
            },
          ),

          const SizedBox(height: 24),

          // Image Preview
          if (_imageUrlController.text.trim().isNotEmpty || _selectedImageFile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Preview'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImagePreview(),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Image Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Image Guidelines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGuideline('Use clear, high-quality images showing the disease clearly'),
                _buildGuideline('Click "Upload Image" to automatically upload to Cloudinary'),
                _buildGuideline('Images are stored securely in the cloud with automatic optimization'),
                _buildGuideline('Alternatively, paste any HTTPS image URL'),
                _buildGuideline('Recommended size: 800x600 pixels or larger'),
                _buildGuideline('Supported formats: JPG, PNG, WebP'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // If there's a selected file (just uploaded), show it
    if (_selectedImageFile != null && _selectedImageFile!.existsSync()) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image file',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          );
        },
      );
    }

    // Try to load from URL (Cloudinary or other)
    final imageUrl = _imageUrlController.text.trim();
    
    if (imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 8),
            Text(
              'No image uploaded',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Check if it's a network URL
    final isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image from URL',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    imageUrl,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Legacy support: Try loading as local asset
      final assetPath = 'assets/img/skin_diseases/$imageUrl';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined,
                    color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Asset not found',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    assetPath,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required String subtitle,
    required List<TextEditingController> controllers,
    required String hintText,
    required int minRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(title, required: true),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '$hintText ${index + 1}',
                      prefixIcon: const Icon(Icons.circle, size: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: controllers.length > minRequired
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  controller.dispose();
                                  controllers.removeAt(index);
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              controllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add $title'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildRemedySection({
    required TextEditingController titleController,
    required List<TextEditingController> actionsControllers,
    TextEditingController? noteController,
    String? urgencyValue,
    ValueChanged<String?>? onUrgencyChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Section title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Urgency Dropdown (for When to Seek Help section)
          if (urgencyValue != null && onUrgencyChanged != null) ...[
            DropdownButtonFormField<String>(
              value: urgencyValue,
              decoration: InputDecoration(
                labelText: 'Urgency Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: onUrgencyChanged,
            ),
            const SizedBox(height: 16),
          ],

          // Actions List
          Text(
            'Actions (min 2)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...actionsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Action ${index + 1}',
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: actionsControllers.length > 2
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              actionsControllers.removeAt(index);
                            });
                          },
                        )
                      : null,
                ),
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                actionsControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Action'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              elevation: 0,
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
          ),

          // Note Field (for Topical Treatment section)
          if (noteController != null) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Additional Note (optional)',
                hintText: 'Add any additional notes or warnings',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
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
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveDisease,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.disease != null ? 'Update Disease' : 'Create Disease'),
          ),
        ],
      ),
    );
  }
}
