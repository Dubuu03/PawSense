import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/clinic/clinic_service_model.dart';
import '../../../services/vet_profile/vet_profile_service.dart';

class AddServiceModal extends StatefulWidget {
  final VoidCallback onServiceAdded;

  const AddServiceModal({
    super.key,
    required this.onServiceAdded,
  });

  @override
  State<AddServiceModal> createState() => _AddServiceModalState();
}

class _AddServiceModalState extends State<AddServiceModal> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _priceController = TextEditingController(text: '0');
  
  ServiceCategory _selectedCategory = ServiceCategory.consultation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.consultation:
        return 'Consultation';
      case ServiceCategory.diagnostic:
        return 'Diagnostic';
      case ServiceCategory.preventive:
        return 'Preventive';
      case ServiceCategory.surgery:
        return 'Surgery';
      case ServiceCategory.emergency:
        return 'Emergency';
      case ServiceCategory.telemedicine:
        return 'Telemedicine';
      case ServiceCategory.grooming:
        return 'Grooming';
      case ServiceCategory.boarding:
        return 'Boarding';
      case ServiceCategory.training:
        return 'Training';
      case ServiceCategory.other:
        return 'Other';
    }
  }

  Future<void> _addService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      final success = await VetProfileService.addService(
        serviceName: _serviceNameController.text.trim(),
        serviceDescription: _descriptionController.text.trim(),
        estimatedPrice: 'PHP ${_priceController.text.trim()}',
        duration: '${_durationController.text.trim()} minutes',
        category: _selectedCategory.name,
        isActive: true,
        isVerified: false,
      );

      if (success) {
        widget.onServiceAdded();
        if (mounted) {
          Navigator.of(context).pop();
          // Show success message on parent screen after modal closes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to add service. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.medical_services, color: AppColors.primary, size: 20),
                      ),
                    ),
                    SizedBox(width: kSpacingSmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Service',
                          style: TextStyle(
                            fontSize: kFontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Create a new service offering',
                          style: TextStyle(
                            fontSize: kFontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: kSpacingLarge),

            // Error Banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(kSpacingMedium),
                margin: EdgeInsets.only(bottom: kSpacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    SizedBox(width: kSpacingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: kFontSizeSmall,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name
                  Text(
                    'Service Name',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _serviceNameController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'e.g., General Consultation',
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a service name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: kSpacingMedium),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 6,
                    maxLength: 300,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Describe the service...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.all(kSpacingMedium),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.length > 300) {
                        return 'Description cannot exceed 300 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: kSpacingMedium),

                  // Duration and Price Row
                  Row(
                    children: [
                      // Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration (minutes)',
                              style: TextStyle(
                                fontSize: kFontSizeRegular,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: kSpacingSmall),
                            TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: '30',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: kSpacingMedium,
                                  vertical: kSpacingSmall,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final number = int.tryParse(value.trim());
                                if (number == null || number <= 0) {
                                  return 'Must be a positive number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: kSpacingMedium),

                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price (PHP)',
                              style: TextStyle(
                                fontSize: kFontSizeRegular,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: kSpacingSmall),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly, // Only allow digits (integers)
                              ],
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: '₱ ',
                                prefixStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: kFontSizeRegular,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: kSpacingMedium,
                                  vertical: kSpacingSmall,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final number = int.tryParse(value.trim());
                                if (number == null || number < 0) {
                                  return 'Must be a valid integer';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: kSpacingMedium),

                  // Category
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  DropdownButtonFormField<ServiceCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                    ),
                    items: ServiceCategory.values.map((category) {
                      return DropdownMenuItem<ServiceCategory>(
                        value: category,
                        child: Text(_getCategoryDisplayName(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: kSpacingLarge),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge,
                      vertical: kSpacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text('Add Service'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
