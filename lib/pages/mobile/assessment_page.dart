import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/breed_options.dart';
import 'package:pawsense/core/widgets/user/assessment/assessment_step_one.dart';
import 'package:pawsense/core/widgets/user/assessment/assessment_step_two.dart';
import 'package:pawsense/core/widgets/user/assessment/assessment_step_three.dart';
import 'package:pawsense/core/widgets/user/assessment/progress_indicator.dart';

class AssessmentPage extends StatefulWidget {
  final String? selectedPetType;
  
  const AssessmentPage({
    super.key,
    this.selectedPetType,
  });

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int currentStep = 0;
  late PageController _pageController;
  bool _isLoading = false;
  String? _previousRoute;
  
  // Global keys to access step widgets
  final GlobalKey<State<AssessmentStepOne>> _stepOneKey = GlobalKey<State<AssessmentStepOne>>();
  final GlobalKey<State<AssessmentStepTwo>> _stepTwoKey = GlobalKey<State<AssessmentStepTwo>>();
  final GlobalKey<State<AssessmentStepThree>> _stepThreeKey = GlobalKey<State<AssessmentStepThree>>();
  
  // Data to be passed between steps
  late Map<String, dynamic> assessmentData;
  
  // Cached breeds for validation
  List<String> _cachedBreeds = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize assessment data with proper types
    assessmentData = <String, dynamic>{
      'selectedPet': null,
      'newPetData': <String, dynamic>{},
      'symptoms': <String>[],
      'photos': <dynamic>[],
      'notes': '',
      'duration': '',
      'selectedPetType': widget.selectedPetType ?? 'Dog', // Use constructor parameter or default
      'petSelectionMode': 'existing', // Track if user is in 'existing' or 'new' pet mode
    };
    
    // Preload breeds for validation
    _loadBreeds();
  }
  
  Future<void> _loadBreeds() async {
    final petType = assessmentData['selectedPetType']?.toString() ?? 'Dog';
    _cachedBreeds = await BreedOptions.getBreedsForPetType(petType);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Capture the previous route information from query parameters
    final routerState = GoRouterState.of(context);
    final uri = routerState.uri;
    
    // Check if the 'from' parameter is provided in the URL
    if (uri.queryParameters.containsKey('from')) {
      _previousRoute = uri.queryParameters['from'];
    }
    
    // Get the extra data from GoRouter if not already set from constructor
    if (assessmentData['selectedPetType'] == null) {
      final extra = routerState.extra as Map<String, dynamic>?;
      
      if (extra != null && extra['selectedPetType'] != null) {
        setState(() {
          assessmentData['selectedPetType'] = extra['selectedPetType'];
        });
      }
    }
  }

  void _goBack() {
    if (_previousRoute != null) {
      // Navigate to the specified previous route
      context.go(_previousRoute!);
    } else {
      // Try to use Navigator.pop() if possible
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback to home
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    debugPrint('🚀 _nextStep called. Current step: $currentStep');
    
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      debugPrint('❌ Validation failed for step: $currentStep');
      _showValidationError();
      return;
    }

    debugPrint('✅ Validation passed for step: $currentStep, proceeding to next step');
    
    // Show loading for step transition
    _showLoading();
    
    try {
      // Simulate any processing time if needed
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (currentStep < 2) {
        setState(() {
          currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } finally {
      // Always hide loading
      _hideLoading();
    }
  }

  bool _validateCurrentStep() {
    debugPrint('🔍 _validateCurrentStep called for step: $currentStep');
    
    switch (currentStep) {
      case 0: // Step One validation
        bool result = _validateStepOne();
        debugPrint('📝 Step One validation result: $result');
        return result;
      case 1: // Step Two validation
        bool result = _validateStepTwo();
        debugPrint('📸 Step Two validation result: $result');
        return result;
      case 2: // Step Three validation
        bool result = _validateStepThree();
        debugPrint('📊 Step Three validation result: $result');
        return result;
      default:
        debugPrint('⚠️ Unknown step: $currentStep');
        return true;
    }
  }

  /// Validates existing pet selection
  bool _validateExistingPet() {
    final selectedPet = assessmentData['selectedPet'];
    if (selectedPet == null) {
      return false; // No existing pet selected
    }

    // In the future, you can add validation for fetched pet details here
    // For example:
    // - Validate that the pet data was successfully fetched
    // - Check if the pet belongs to the current user
    // - Validate pet status (active, not deleted, etc.)
    
    return true; // For now, any selected existing pet is valid
  }

  /// Validates new pet data input
  bool _validateNewPetData() {
    debugPrint('🔍 Validating new pet data...');
    
    // Step 1: Check if all required fields are filled
    if (!_hasAllRequiredFields()) {
      debugPrint('❌ Missing required fields');
      return false;
    }

    // Step 2: Check name, age, weight validity
    if (!_validateBasicPetFields()) {
      print('Basic fields validation failed');
      return false;
    }

    // Step 3: Validate breed specifically for new pets (last)
    bool breedValid = _validateBreedForNewPet();
    print('Breed validation result: $breedValid');
    return breedValid;
  }

  /// Checks if all required fields have input
  bool _hasAllRequiredFields() {
    final newPetData = Map<String, dynamic>.from(assessmentData['newPetData'] as Map? ?? {});
    
    return newPetData['name']?.toString().trim().isNotEmpty == true &&
           newPetData['age']?.toString().trim().isNotEmpty == true &&
           newPetData['weight']?.toString().trim().isNotEmpty == true &&
           newPetData['breed']?.toString().trim().isNotEmpty == true;
  }

  /// Validates basic pet fields (name, age, weight) but not breed
  bool _validateBasicPetFields() {
    final newPetData = Map<String, dynamic>.from(assessmentData['newPetData'] as Map? ?? {});
    
    // For now, just check they exist and are not empty
    // In the future, you can add specific validation rules:
    // - Name: minimum length, no special characters
    // - Age: must be a valid number, within reasonable range
    // - Weight: must be a valid number, within reasonable range
    
    final name = newPetData['name']?.toString().trim() ?? '';
    final age = newPetData['age']?.toString().trim() ?? '';
    final weight = newPetData['weight']?.toString().trim() ?? '';

    return name.isNotEmpty && age.isNotEmpty && weight.isNotEmpty;
  }

  /// Validates breed specifically for new pet creation
  bool _validateBreedForNewPet() {
    final newPetData = Map<String, dynamic>.from(assessmentData['newPetData'] as Map? ?? {});
    
    final breed = newPetData['breed']?.toString().trim() ?? '';
    if (breed.isEmpty) {
      return false;
    }

    // Use cached breeds for synchronous validation
    return _cachedBreeds.contains(breed);
  }

  /// Validates behaviors/symptoms selection
  bool _validateBehaviors() {
    final symptoms = assessmentData['symptoms'] as List<String>?;
    debugPrint('🏃 Validating behaviors: $symptoms');
    bool isValid = symptoms != null && symptoms.isNotEmpty;
    debugPrint('🏃 Behaviors validation result: $isValid');
    return isValid;
  }

  /// Checks if user is creating a new pet (not selecting existing one)
  bool _isCreatingNewPet() {
    // Check the pet selection mode to determine user's intent
    final mode = assessmentData['petSelectionMode'] ?? 'existing';
    return mode == 'new';
  }

  /// Gets specific breed validation error message
  String _getBreedValidationMessage() {
    final newPetData = Map<String, dynamic>.from(assessmentData['newPetData'] as Map? ?? {});
    
    final breed = newPetData['breed']?.toString().trim() ?? '';
    if (breed.isEmpty) {
      return 'Please enter a breed for your pet';
    }

    final petType = assessmentData['selectedPetType']?.toString() ?? 'Dog';
    
    // Use cached breeds for synchronous validation
    if (!_cachedBreeds.contains(breed)) {
      return 'Please select a valid breed from the list. "$breed" is not a recognized ${petType.toLowerCase()} breed.';
    }

    return 'Invalid breed';
  }

  /// Gets validation message for existing pet issues
  String _getExistingPetValidationMessage() {
    // In the future, you can add specific messages based on different existing pet validation failures
    // For example:
    // - "Selected pet could not be found"
    // - "Pet data could not be loaded"
    // - "Pet belongs to another user"
    
    return 'Please select an existing pet from the list';
  }

  /// Gets message for missing required fields
  String _getMissingFieldsMessage() {
    final newPetData = Map<String, dynamic>.from(assessmentData['newPetData'] as Map? ?? {});

    List<String> missingFields = [];
    
    if (newPetData['name']?.toString().trim().isEmpty != false) {
      missingFields.add('name');
    }
    if (newPetData['age']?.toString().trim().isEmpty != false) {
      missingFields.add('age');
    }
    if (newPetData['weight']?.toString().trim().isEmpty != false) {
      missingFields.add('weight');
    }
    if (newPetData['breed']?.toString().trim().isEmpty != false) {
      missingFields.add('breed');
    }

    if (missingFields.isNotEmpty) {
      return 'Please fill in the following fields: ${missingFields.join(', ')}';
    }

    return 'Please complete all new pet information';
  }

  /// Gets validation message for basic field issues (name, age, weight)
  String _getBasicFieldsValidationMessage() {
    // For now, return a generic message
    // In the future, you can add specific validation messages for:
    // - Invalid age format or range
    // - Invalid weight format or range
    // - Invalid name format
    
    return 'Please check that name, age, and weight are valid';
  }

  bool _validateStepOne() {
    debugPrint('🔎 Validating Step One...');
    debugPrint('🔎 Is creating new pet: ${_isCreatingNewPet()}');
    
    // Check pet selection/creation using dedicated methods
    bool hasValidPet = false;
    
    if (_isCreatingNewPet()) {
      // User is creating a new pet - validate new pet data
      hasValidPet = _validateNewPetData();
      debugPrint('🐕 New pet validation result: $hasValidPet');
    } else {
      // User selected an existing pet - validate existing pet
      hasValidPet = _validateExistingPet();
      debugPrint('🐕 Existing pet validation result: $hasValidPet');
    }
    
    if (!hasValidPet) {
      debugPrint('❌ Pet validation failed');
      return false;
    }

    // Validate behaviors/symptoms selection
    if (!_validateBehaviors()) {
      debugPrint('❌ Behavior validation failed');
      return false;
    }

    debugPrint('✅ Step One validation passed');
    return true;
  }

  bool _validateStepTwo() {
    // Check if at least one photo is uploaded
    final photos = assessmentData['photos'] as List<dynamic>?;
    if (photos == null || photos.isEmpty) {
      return false;
    }

    // Check if analysis is still in progress
    final stepTwoState = _stepTwoKey.currentState;
    if (stepTwoState != null) {
      final stepTwoWidget = stepTwoState as dynamic;
      if (stepTwoWidget.isAnalyzing == true) {
        return false; // Can't proceed while analyzing
      }
    }

    return true;
  }

  bool _validateStepThree() {
    // Add Step Three validation logic here
    // For now, return true - you can add specific validation later
    return true;
  }

  void _showValidationError() {
    String message = _getValidationMessage();
    print('Showing validation error: $message');
    
    // Trigger visual validation feedback for step one
    if (currentStep == 0) {
      final stepOneState = _stepOneKey.currentState;
      if (stepOneState != null) {
        final stepOneWidget = stepOneState as dynamic;
        if (stepOneWidget.triggerValidation != null) {
          stepOneWidget.triggerValidation();
        }
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getValidationMessage() {
    print('Getting validation message for step: $currentStep');
    
    switch (currentStep) {
      case 0:
        // Check pet validation first
        if (_isCreatingNewPet()) {
          print('Validating new pet...');
          
          // Step 1: Check if all fields have input
          if (!_hasAllRequiredFields()) {
            print('Missing fields detected');
            return _getMissingFieldsMessage();
          }
          
          // Step 2: Check basic fields validity (name, age, weight)
          if (!_validateBasicPetFields()) {
            print('Basic fields validation failed');
            return _getBasicFieldsValidationMessage();
          }
          
          // Step 3: Check breed validation (last)
          if (!_validateBreedForNewPet()) {
            print('Breed validation failed');
            return _getBreedValidationMessage();
          }
        } else {
          // User selected an existing pet
          if (!_validateExistingPet()) {
            print('Existing pet validation failed');
            return _getExistingPetValidationMessage();
          }
        }
        
        // Check behaviors validation
        if (!_validateBehaviors()) {
          print('Behavior validation failed');
          return 'Please select at least one observed behavior';
        }
        
        return 'Please complete all required fields';
      case 1:
        final photos = assessmentData['photos'] as List<dynamic>?;
        if (photos == null || photos.isEmpty) {
          return 'Please upload or take at least one photo of the affected area';
        }

        // Check if analysis is still in progress
        final stepTwoState = _stepTwoKey.currentState;
        if (stepTwoState != null) {
          final stepTwoWidget = stepTwoState as dynamic;
          if (stepTwoWidget.isAnalyzing == true) {
            return 'Please wait for image analysis to complete before proceeding';
          }
        }

        return 'Please complete Step 2 requirements';
      case 2:
        return 'Please complete Step 3 requirements';
      default:
        return 'Please complete all required fields';
    }
  }

  void _completeAssessment() async {
    // Show loading
    _showLoading();
    
    try {
      print('DEBUG: Assessment completion triggered from check button...');
      // Try to access the AssessmentStepThree widget and call its save method
      final stepThreeState = _stepThreeKey.currentState;
      if (stepThreeState != null && stepThreeState.mounted) {
        // Use dynamic casting to call the save method
        final dynamic assessmentState = stepThreeState;
        if (assessmentState.saveAssessment != null) {
          print('DEBUG: Calling saveAssessment from step three widget...');
          await assessmentState.saveAssessment();
        }
      }
      
      // Hide loading
      _hideLoading();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Assessment completed and saved successfully!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('DEBUG: Assessment saved successfully from check button, waiting for propagation...');
      
      // Small delay to ensure Firebase write has propagated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to home with history tab and force refresh with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      context.go('/home?tab=history&refresh=assessment&t=$timestamp');
      
    } catch (e) {
      // Hide loading on error
      _hideLoading();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing assessment: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _previousStep() async {
    // Check if we're in step 2 and analysis is in progress
    if (currentStep == 1) {
      final stepTwoState = _stepTwoKey.currentState;
      if (stepTwoState != null) {
        final stepTwoWidget = stepTwoState as dynamic;
        if (stepTwoWidget.isAnalyzing == true) {
          // Show confirmation dialog
          final shouldCancel = await _showCancelAnalysisDialog();
          if (!shouldCancel) {
            return; // User chose not to cancel
          }
        }
      }
    }

    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _showCancelAnalysisDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Cancel Analysis?',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Image analysis is currently in progress. Going back will cancel the analysis process. Are you sure you want to continue?',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Stay',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Cancel Analysis'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _updateAssessmentData(String key, dynamic value) {
    setState(() {
      assessmentData[key] = value;
    });
    
    // Debug print to track data updates
    debugPrint('📊 Assessment data updated: $key = $value');
    debugPrint('📊 Current assessment data: $assessmentData');
  }

  void _showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: Tooltip(
              message: currentStep == 0 ? 'Go Back' : 'Previous Step',
              waitDuration: const Duration(milliseconds: 100),
              showDuration: const Duration(seconds: 2),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () async {
                  if (currentStep == 0) {
                    // Navigate back to where user came from
                    _goBack();
                  } else {
                    // Go to previous step (with analysis confirmation if needed)
                    _previousStep();
                  }
                },
              ),
            ),
            title: Text(
              'Pet Assessment',
              style: kMobileTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            actions: [
              Tooltip(
                message: currentStep < 2 ? 'Next Step' : 'Complete Assessment',
                waitDuration: const Duration(milliseconds: 500),
                showDuration: const Duration(seconds: 2),
                child: IconButton(
                  icon: Icon(Icons.check, color: AppColors.textPrimary),
                  onPressed: () {
                    if (currentStep < 2) {
                      _nextStep();
                    } else {
                      // Validate final step before completing
                      if (_validateCurrentStep()) {
                        _completeAssessment();
                      } else {
                        _showValidationError();
                      }
                    }
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                padding: kMobilePaddingCard,
                child: AssessmentProgressIndicator(
                  currentStep: currentStep,
                  totalSteps: 3,
                ),
              ),
            ),
          ),
          body: PageView(
            key: const PageStorageKey<String>('assessment_pageview'),
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AssessmentStepOne(
                key: _stepOneKey,
                assessmentData: assessmentData,
                onDataUpdate: _updateAssessmentData,
                onNext: _nextStep,
              ),
              AssessmentStepTwo(
                key: _stepTwoKey,
                assessmentData: assessmentData,
                onDataUpdate: _updateAssessmentData,
                onNext: _nextStep,
                onPrevious: _previousStep,
              ),
              AssessmentStepThree(
                key: _stepThreeKey,
                assessmentData: assessmentData,
                onDataUpdate: _updateAssessmentData,
                onPrevious: _previousStep,
                onComplete: () {
                  // Handle assessment completion
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        
        // Full screen loading overlay covering everything including app bar
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.6),
        child: const Center(
          child: Card(
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
