import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../../../../core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:flutter/services.dart';
import 'package:pawsense/core/utils/breed_options.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class AssessmentStepOne extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback? onValidationTrigger;

  const AssessmentStepOne({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onNext,
    this.onValidationTrigger,
  });

  @override
  State<AssessmentStepOne> createState() => _AssessmentStepOneState();
}

class _AssessmentStepOneState extends State<AssessmentStepOne> {
  final _formKey = GlobalKey<FormState>();
  bool isNewPet = false;
  String? selectedPet;
  
  // Controllers for new pet form
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // Breed dropdown state
  List<String> _allBreeds = [];
  String? _selectedBreed;

  // Validation state tracking
  bool _showValidationErrors = false;
  final Map<String, bool> _fieldErrors = {
    'name': false,
    'age': false,
    'weight': false,
    'breed': false,
  };

  // Real pets data from database
  List<Pet> _userPets = [];
  bool _loadingPets = true;
  String? _petsError;

  // Observed behaviors
  final Map<String, bool> behaviors = {
    'Scratching': false,
    'Licking': false,
    'Biting/Chewing': false,
    'Rolling/Rubbing': false,
    'Scooting': false,
    'Head Shaking': false,
  };

  @override
  void initState() {
    super.initState();
    
    // Load real pets data
    _loadUserPets();
    
    // Add listeners to update assessment data in real-time
    _nameController.addListener(_updatePetData);
    _ageController.addListener(_updatePetData);
    _weightController.addListener(_updatePetData);
    _notesController.addListener(_updateNotesData);
    
    // Load breeds asynchronously
    _loadBreeds();
    
    // Initialize with existing data if available
    if (widget.assessmentData['selectedPet'] != null) {
      selectedPet = widget.assessmentData['selectedPet'];
    }
    
    // Initialize the tab mode based on existing data
    final currentMode = widget.assessmentData['petSelectionMode'] ?? 'existing';
    if (currentMode == 'new') {
      isNewPet = true;
    }
    
    // Ensure the parent knows the current mode (defer to avoid setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataUpdate('petSelectionMode', isNewPet ? 'new' : 'existing');
    });
    
    if (widget.assessmentData['newPetData'] != null) {
      final newPetData = Map<String, dynamic>.from(widget.assessmentData['newPetData'] as Map);
      _nameController.text = newPetData['name'] ?? '';
      _ageController.text = newPetData['age'] ?? '';
      _weightController.text = newPetData['weight'] ?? '';
      _selectedBreed = newPetData['breed'];
    }
    _durationController.text = widget.assessmentData['duration'] ?? '';
    _notesController.text = widget.assessmentData['notes'] ?? '';
    
    // Initialize behaviors
    if (widget.assessmentData['symptoms'] != null) {
      final symptoms = List<String>.from(widget.assessmentData['symptoms'] as List);
      for (String symptom in symptoms) {
        if (behaviors.containsKey(symptom)) {
          behaviors[symptom] = true;
        }
      }
    }
  }

  Future<void> _loadUserPets() async {
    print('DEBUG: AssessmentStepOne loading user pets...');
    try {
      setState(() {
        _loadingPets = true;
        _petsError = null;
      });

      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final pets = await PetService.getUserPets(user.uid);
        print('DEBUG: AssessmentStepOne loaded ${pets.length} pets');
        if (mounted) {
          setState(() {
            _userPets = pets;
            _loadingPets = false;
          });
        }
      } else {
        print('DEBUG: AssessmentStepOne user not found');
        if (mounted) {
          setState(() {
            _petsError = 'User not found';
            _loadingPets = false;
          });
        }
      }
    } catch (e) {
      print('Error loading pets in AssessmentStepOne: $e');
      if (mounted) {
        setState(() {
          _petsError = 'Failed to load pets';
          _loadingPets = false;
        });
      }
    }
  }

  // Public method to refresh pets from parent
  void refreshPets() {
    _loadUserPets();
  }

  @override
  void didUpdateWidget(AssessmentStepOne oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if selectedPetType has changed and update accordingly
    final oldPetType = oldWidget.assessmentData['selectedPetType'];
    final newPetType = widget.assessmentData['selectedPetType'];
    
    if (oldPetType != newPetType) {
      // Reset selected pet when pet type changes
      setState(() {
        selectedPet = null;
      });
      
      // Defer the update to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDataUpdate('selectedPet', null);
      });
      
      // Update breed options for the new pet type
      _loadBreedsForPetType(newPetType ?? 'Dog');
      
      // Clear breed field if it was filled
      if (_selectedBreed != null) {
        setState(() {
          _selectedBreed = null;
        });
        
        // Defer the update to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDataUpdate('newPetData', {
            ...widget.assessmentData['newPetData'] ?? {},
            'breed': '',
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBreeds() async {
    final petType = widget.assessmentData['selectedPetType'] ?? 'Dog';
    final breeds = await BreedOptions.getBreedsForPetType(petType);
    setState(() {
      _allBreeds = breeds;
    });
  }

  Future<void> _loadBreedsForPetType(String petType) async {
    final breeds = await BreedOptions.getBreedsForPetType(petType);
    setState(() {
      _allBreeds = breeds;
    });
  }

  void _selectBreed(String? breed) {
    if (breed == null) return;
    
    print('_selectBreed called with: $breed');
    setState(() {
      _selectedBreed = breed;
    });
    
    // Update validation state when breed is selected
    if (_showValidationErrors) {
      _updateValidationState();
    }
    
    // Defer the update to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataUpdate('newPetData', {
        ...widget.assessmentData['newPetData'] ?? {},
        'breed': breed,
      });
    });
    print('Breed selected: $breed');
  }

  void _updatePetData() {
    final newPetData = {
      'name': _nameController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
      'breed': _selectedBreed ?? '',
    };
    
    // Update validation state for visual feedback
    _updateValidationState();
    
    // Defer the update to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataUpdate('newPetData', newPetData);
    });
  }

  void _updateNotesData() {
    // Defer the update to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataUpdate('notes', _notesController.text);
    });
  }

  void _updateValidationState() {
    if (!isNewPet) return; // Only validate for new pet form
    
    setState(() {
      final nameTrimmed = _nameController.text.trim();
      _fieldErrors['name'] = _showValidationErrors && (nameTrimmed.isEmpty || nameTrimmed.length > 20);
      _fieldErrors['age'] = _showValidationErrors && _ageController.text.trim().isEmpty;
      _fieldErrors['weight'] = _showValidationErrors && _weightController.text.trim().isEmpty;
      _fieldErrors['breed'] = _showValidationErrors && (_selectedBreed == null || _selectedBreed!.trim().isEmpty || !_isValidBreed());
    });
  }

  bool _isValidBreed() {
    if (_selectedBreed == null || _selectedBreed!.trim().isEmpty) return false;
    
    // Check if breed exists in all breeds list
    return _allBreeds.contains(_selectedBreed);
  }

  void _triggerValidation() {
    setState(() {
      _showValidationErrors = true;
    });
    _updateValidationState();
  }

  // Public method that can be called from parent widget
  void triggerValidation() {
    _triggerValidation();
  }

  Widget _buildPetBreedField() {
    final hasError = _showValidationErrors && isNewPet && _fieldErrors['breed'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Breed",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedBreed,
          decoration: InputDecoration(
            hintText: "Select breed",
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _allBreeds.map((String breed) {
            return DropdownMenuItem<String>(
              value: breed,
              child: Text(
                breed,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            _selectBreed(value);
          },
          menuMaxHeight: 300,
        ),
      ],
    );
  }
  // Breed search dialog logic has been inlined into the breed field builder.


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Selection Section
            Container(
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color: AppColors.black.withOpacity(0.8),
                        size: 24,
                      ),
                      const SizedBox(width: kSpacingSmall),
                      Text(
                        widget.assessmentData['selectedPetType'] ?? 'Dog',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.black.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingMedium),
                  
                  // Pet Selection Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isNewPet = false;
                              // Clear validation errors when switching tabs
                              _showValidationErrors = false;
                              _fieldErrors.updateAll((key, value) => false);
                            });
                            // Defer the update to avoid setState during build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onDataUpdate('petSelectionMode', 'existing');
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingMedium,
                              vertical: kSpacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: !isNewPet ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              border: Border.all(
                                color: !isNewPet ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'Existing Pet',
                              textAlign: TextAlign.center,
                              style: kTextStyleRegular.copyWith(
                                color: !isNewPet ? AppColors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: kSpacingSmall),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isNewPet = true;
                              // Deselect any selected existing pet when switching to new pet
                              selectedPet = null;
                              // Clear validation errors when switching tabs
                              _showValidationErrors = false;
                              _fieldErrors.updateAll((key, value) => false);
                            });
                            // Defer the updates to avoid setState during build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onDataUpdate('selectedPet', null);
                              widget.onDataUpdate('petSelectionMode', 'new');
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingMedium,
                              vertical: kSpacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: isNewPet ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              border: Border.all(
                                color: isNewPet ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'New Pet',
                              textAlign: TextAlign.center,
                              style: kTextStyleRegular.copyWith(
                                color: isNewPet ? AppColors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingMedium),
                  
                  // Pet Selection/Form
                  if (isNewPet) _buildNewPetForm() else _buildExistingPetSelector(),
                ],
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            // Behaviors Section
            Container(
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observed Behaviors',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                   const SizedBox(height: kSpacingSmall),
                  Text(
                    'Which of the following itchy skin behaviours does your ${widget.assessmentData['selectedPetType']?.toLowerCase() ?? 'pet'} experience?',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: kSpacingMedium),
                  _buildBehaviorCheckboxes(),
                  const SizedBox(height: kSpacingSmall),
                  
                  Text(
                    'Notes (optional)',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  _buildNotesField(),
                ],
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Text(
                'This is a preliminary differential analysis. For a confirmed diagnosis, please consult a licensed veterinarian.',
                style: kTextStyleSmall.copyWith(
                  color: AppColors.info,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPetSelector() {
    // Get pets for the selected pet type from real data
    final selectedPetType = widget.assessmentData['selectedPetType'] ?? 'Dog';
    final existingPets = _userPets.where((pet) => pet.petType.toLowerCase() == selectedPetType.toLowerCase()).toList();
    
    print('DEBUG: Selected pet type: $selectedPetType');
    print('DEBUG: Total pets: ${_userPets.length}');
    print('DEBUG: Filtered pets for $selectedPetType: ${existingPets.length}');
    for (var pet in _userPets) {
      print('DEBUG: Pet "${pet.petName}" is type "${pet.petType}"');
    }
    
    if (_loadingPets) {
      return Container(
        padding: const EdgeInsets.all(kSpacingMedium),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_petsError != null) {
      return Container(
        padding: const EdgeInsets.all(kSpacingMedium),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: kSpacingSmall),
            Text(
              _petsError!,
              style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpacingSmall),
            ElevatedButton(
              onPressed: _loadUserPets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Select Your $selectedPetType',
                style: kMobileTextStyleServiceTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          if (existingPets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(kSpacingMedium),
              child: Text(
                'No $selectedPetType pets found. Please add a new pet.',
                style: kMobileTextStyleViewAll.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...existingPets.map((pet) => Container(
              margin: const EdgeInsets.only(bottom: 0),
              child: RadioListTile<String>(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                title: Text(
                  pet.petName,
                  style: kMobileTextStyleServiceTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${pet.breed} • ${pet.ageString}',
                  style: kMobileTextStyleViewAll.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: pet.id!,
                groupValue: selectedPet,
                onChanged: (value) {
                  setState(() => selectedPet = value);
                  // Defer the update to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onDataUpdate('selectedPet', value);
                  });
                },
                activeColor: AppColors.primary,
                dense: true,
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildNewPetForm() {
    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Add New Pet',
                style: kMobileTextStyleServiceTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingMedium),

          // Pet's Name
          _buildPetNameField(_nameController),
          const SizedBox(height: kSpacingSmall),

          // Age & Weight Row
          Row(
            children: [
              Expanded(child: _buildPetAgeField(_ageController)),
              const SizedBox(width: kSpacingSmall),
              Expanded(child: _buildPetWeightField(_weightController)),
            ],
          ),
          const SizedBox(height: kSpacingSmall),

          // Breed
          _buildPetBreedField(),
          const SizedBox(height: kSpacingSmall),
        ],
      ),
    );
  }


  Widget _buildBehaviorCheckboxes() {
    // Custom images for each behavior (you can replace these with actual image paths)
    final Map<String, String> behaviorImages = {
      'Scratching': 'assets/img/behavior_scratching.png',
      'Licking': 'assets/img/behavior_licking.png',
      'Biting/Chewing': 'assets/img/behavior_biting_chewing.png',
      'Rolling/Rubbing': 'assets/img/behavior_rolling_rubbing.png',
      'Scooting': 'assets/img/behavior_scooting.png',
      'Head Shaking': 'assets/img/behavior_head_shaking.png',
    };

    final behaviorList = behaviors.entries.toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: kSpacingSmall,
        mainAxisSpacing: kSpacingSmall,
      ),
      itemCount: behaviorList.length,
      itemBuilder: (context, index) {
        final behavior = behaviorList[index];
        final isSelected = behavior.value;
        
        return GestureDetector(
          onTap: () {
            debugPrint('🎯 Behavior tapped: ${behavior.key}');
            setState(() {
              behaviors[behavior.key] = !behavior.value;
            });
            
            // Update assessment data with selected symptoms (defer to avoid setState during build)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final selectedSymptoms = behaviors.entries
                  .where((entry) => entry.value)
                  .map((entry) => entry.key)
                  .toList();
              
              debugPrint('🎯 Selected symptoms after tap: $selectedSymptoms');
              widget.onDataUpdate('symptoms', selectedSymptoms);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom behavior image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      behaviorImages[behavior.key] ?? 'assets/img/behavior_licking.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image not found
                        return Icon(
                          Icons.pets,
                          color: AppColors.primary,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                
                // Behavior name
                Text(
                  behavior.key,
                  style: kMobileTextStyleViewAll.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: kSpacingXSmall),
                
                // Selection indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _notesController,
          keyboardType: TextInputType.multiline,
          maxLines: 6,
          maxLength: 300,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          decoration: InputDecoration(
            hintText: "Symptoms, duration...",
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPetNameField(TextEditingController controller) {
    final hasError = _showValidationErrors && isNewPet && _fieldErrors['name'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pet's Name",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\-']")),
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: "Enter pet's name",
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            counterText: "",
          ),
        ),
      ],
    );
  }

  Widget _buildPetAgeField(TextEditingController controller) {
    final hasError = _showValidationErrors && isNewPet && _fieldErrors['age'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Age (months)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 3,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            hintText: "Enter age",
            fillColor: Colors.grey.shade100,
            filled: true,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }  Widget _buildPetWeightField(TextEditingController controller) {
    final hasError = _showValidationErrors && isNewPet && _fieldErrors['weight'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Weight (kg)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
          ],
          decoration: InputDecoration(
            hintText: "Enter weight",
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppColors.primary,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}