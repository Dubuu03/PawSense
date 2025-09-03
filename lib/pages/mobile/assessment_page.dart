import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
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
  
  // Data to be passed between steps
  late Map<String, dynamic> assessmentData;

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
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the extra data from GoRouter if not already set from constructor
    if (assessmentData['selectedPetType'] == null) {
      final routerState = GoRouterState.of(context);
      final extra = routerState.extra as Map<String, dynamic>?;
      
      if (extra != null && extra['selectedPetType'] != null) {
        setState(() {
          assessmentData['selectedPetType'] = extra['selectedPetType'];
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
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

  void _updateAssessmentData(String key, dynamic value) {
    setState(() {
      assessmentData[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (currentStep == 0) {
              // Navigate to home when on step one
              context.go('/home');
            } else {
              // Go to previous step
              _previousStep();
            }
          },
        ),
        title: Text(
          'Pet Assessment',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: AppColors.textPrimary),
            onPressed: () {
              if (currentStep < 2) {
                _nextStep();
              } else {
                // Complete the assessment on step 3
                context.go('/home');
              }
            },
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
            key: const ValueKey('step_one'),
            assessmentData: assessmentData,
            onDataUpdate: _updateAssessmentData,
            onNext: _nextStep,
          ),
          AssessmentStepTwo(
            key: const ValueKey('step_two'),
            assessmentData: assessmentData,
            onDataUpdate: _updateAssessmentData,
            onNext: _nextStep,
            onPrevious: _previousStep,
          ),
          AssessmentStepThree(
            key: const ValueKey('step_three'),
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
    );
  }
}
