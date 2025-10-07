import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../services/vet_profile/vet_profile_service.dart';

class AddSpecializationModal extends StatefulWidget {
  final Future<void> Function() onSpecializationAdded;

  const AddSpecializationModal({
    super.key,
    required this.onSpecializationAdded,
  });

  @override
  State<AddSpecializationModal> createState() => _AddSpecializationModalState();
}

class _AddSpecializationModalState extends State<AddSpecializationModal> {
  final _formKey = GlobalKey<FormState>();
  final _customSpecializationController = TextEditingController();
  
  String? _selectedSpecialization;
  String _selectedLevel = 'Expert';
  bool _hasCertification = true;
  bool _isLoading = false;
  bool _isCustom = false;

  // Predefined specializations
  final List<String> _predefinedSpecializations = [
    'Small Animal Medicine',
    'Large Animal Medicine',
    'Emergency and Critical Care',
    'Surgery',
    'Dermatology',
    'Cardiology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Dentistry',
    'Internal Medicine',
    'Anesthesiology',
    'Radiology',
    'Pathology',
    'Exotic Animal Medicine',
  ];

  final List<String> _expertiseLevels = [
    'Basic',
    'Intermediate',
    'Expert',
  ];



  @override
  void dispose() {
    _customSpecializationController.dispose();
    super.dispose();
  }

  Future<void> _addSpecialization() async {
    if (!_formKey.currentState!.validate()) return;

    final specialization = _isCustom 
        ? _customSpecializationController.text.trim()
        : _selectedSpecialization;

    if (specialization == null || specialization.isEmpty) {
      _showErrorSnackBar('Please select or enter a specialization');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('DEBUG Modal: Adding specialization: $specialization');
      print('DEBUG Modal: Level: $_selectedLevel');
      print('DEBUG Modal: Has certification: $_hasCertification');
      
      // Save specialization with level and certification info
      final success = await VetProfileService.addSpecialization(
        specialization,
        level: _selectedLevel,
        hasCertification: _hasCertification,
      );
      print('DEBUG Modal: Add result: $success');

      if (success && mounted) {
        print('DEBUG Modal: Calling onSpecializationAdded callback...');
        await widget.onSpecializationAdded();
        print('DEBUG Modal: Callback completed, closing modal...');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        _showErrorSnackBar('Specialization already exists or failed to add');
      }
    } catch (e) {
      print('DEBUG Modal: Error adding specialization: $e');
      if (mounted) {
        _showErrorSnackBar('Error adding specialization: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Success notification method removed - functionality not currently used

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(kSpacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Specialization',
                    style: TextStyle(
                      fontSize: kFontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                     
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpacingMedium),

              // Toggle between predefined and custom
              Container(
                padding: const EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text(
                          'Select from list',
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        value: false,
                        groupValue: _isCustom,
                        onChanged: _isLoading ? null : (value) {
                          setState(() {
                            _isCustom = false;
                            _selectedSpecialization = null;
                            _customSpecializationController.clear();
                          });
                        },
                        activeColor: AppColors.primary,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        value: true,
                        groupValue: _isCustom,
                        onChanged: _isLoading ? null : (value) {
                          setState(() {
                            _isCustom = true;
                            _selectedSpecialization = null;
                          });
                        },
                        activeColor: AppColors.primary,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpacingLarge),

              // Specialization input section
              if (!_isCustom) ...[
                Text(
                  'Select Specialization',
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(
                      color: _selectedSpecialization == null ? AppColors.border : AppColors.primary,
                      width: _selectedSpecialization == null ? 1 : 2,
                    ),
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSpecialization,
                      hint: Text(
                        'Choose a specialization',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: kFontSizeRegular,
                        ),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: kFontSizeRegular,
                      ),
                      items: _predefinedSpecializations.map((String specialization) {
                        return DropdownMenuItem<String>(
                          value: specialization,
                          child: Text(
                            specialization,
                            style: TextStyle(
                              fontSize: kFontSizeRegular,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoading ? null : (String? newValue) {
                        setState(() {
                          _selectedSpecialization = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Custom Specialization',
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                TextFormField(
                  controller: _customSpecializationController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Enter your specialization',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: kFontSizeRegular,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: kSpacingMedium,
                      vertical: kSpacingMedium,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    color: AppColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a specialization';
                    }
                    if (value.trim().length < 2) {
                      return 'Specialization must be at least 2 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Specialization must be less than 50 characters';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: kSpacingLarge),

              // Expertise Level
              Text(
                'Expertise Level',
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: kSpacingSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLevel,
                    isExpanded: true,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: kFontSizeRegular,
                    ),
                    items: _expertiseLevels.map((String level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (String? newValue) {
                      setState(() {
                        _selectedLevel = newValue ?? 'Expert';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: kSpacingLarge),

              // Certification toggle
              Container(
                padding: const EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: CheckboxListTile(
                  title: Text(
                    'I have certification for this specialization',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: _hasCertification,
                  onChanged: _isLoading ? null : (bool? value) {
                    setState(() {
                      _hasCertification = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              const SizedBox(height: kSpacingLarge),



              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        backgroundColor: AppColors.white,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: kFontSizeRegular,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addSpecialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Add Specialization',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: kFontSizeRegular,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
