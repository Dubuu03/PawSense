import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../../../../core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/forms/custom_text_field.dart';

class AssessmentStepOne extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;

  const AssessmentStepOne({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onNext,
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
  final _breedController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // Sample existing pets (in real app, this would come from a service)
  final List<Map<String, String>> existingPets = [
    {'id': '1', 'name': 'Buddy', 'breed': 'Golden Retriever', 'age': '3'},
    {'id': '2', 'name': 'Luna', 'breed': 'Labrador', 'age': '2'},
    {'id': '3', 'name': 'Max', 'breed': 'German Shepherd', 'age': '5'},
  ];

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
    
    // Add fake pets data for testing
    _initializeFakeData();
    
    // Initialize with existing data if available
    if (widget.assessmentData['selectedPet'] != null) {
      selectedPet = widget.assessmentData['selectedPet'];
    }
    if (widget.assessmentData['newPetData'] != null) {
      final newPetData = Map<String, dynamic>.from(widget.assessmentData['newPetData'] as Map);
      _nameController.text = newPetData['name'] ?? '';
      _ageController.text = newPetData['age'] ?? '';
      _weightController.text = newPetData['weight'] ?? '';
      _breedController.text = newPetData['breed'] ?? '';
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

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFakeData() {
    // Fake data is already initialized in existingPets list
    // This method is here for future expansion if needed
  }


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
                          onTap: () => setState(() => isNewPet = false),
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
                          onTap: () => setState(() => isNewPet = true),
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
                    'Which of the following itchy skin behaviours does your dog experience?',
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
                  CustomTextField(
                    controller: _notesController,
                    hintText: 'Symptoms, duration...',
                    maxLines: 4,
                  ),
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
    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
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
              Icon(Icons.pets_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Select Your Pet',
                style: kMobileTextStyleServiceTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          ...existingPets.map((pet) => Container(
            margin: const EdgeInsets.only(bottom: 0),
            child: RadioListTile<String>(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: Text(
                pet['name']!,
                style: kMobileTextStyleServiceTitle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${pet['breed']} • ${pet['age']} years old',
                style: kMobileTextStyleViewAll.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: pet['id']!,
              groupValue: selectedPet,
              onChanged: (value) => setState(() => selectedPet = value),
              activeColor: AppColors.primary,
              dense: true,
            ),
          )).toList(),
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
          CustomTextField(
            controller: _nameController,
            labelText: "Pet's Name",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter pet name';
              }
              return null;
            },
          ),
          const SizedBox(height: kSpacingSmall),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _ageController,
                  labelText: 'Age (years)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter age';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: kSpacingSmall),
              Expanded(
                child: CustomTextField(
                  controller: _weightController,
                  labelText: 'Weight (kg)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          CustomTextField(
            controller: _breedController,
            labelText: 'Breed',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter breed';
              }
              return null;
            },
          ),
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
          onTap: () => setState(() => behaviors[behavior.key] = !behavior.value),
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
}
