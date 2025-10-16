import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/validators.dart';
import '../../../services/shared/settings_service.dart';
import 'settings_form_field.dart';

class ClinicSettings extends StatefulWidget {
  const ClinicSettings({super.key});

  @override
  State<ClinicSettings> createState() => _ClinicSettingsState();
}

class _ClinicSettingsState extends State<ClinicSettings> {
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // Field errors tracking for real-time validation
  final Map<String, String?> _fieldErrors = {
    'clinicName': null,
    'address': null,
    'phone': null,
    'email': null,
    'website': null,
  };

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clinicData = await SettingsService.getClinicSettings();
      
      if (clinicData != null && mounted) {
        setState(() {
          _clinicNameController.text = clinicData['clinicName'] ?? '';
          _addressController.text = clinicData['address'] ?? '';
          _phoneController.text = clinicData['phone'] ?? '';
          _emailController.text = clinicData['email'] ?? '';
          _websiteController.text = clinicData['website'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clinic data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Validate individual field
  String? _validateField(String fieldKey, String value) {
    switch (fieldKey) {
      case 'clinicName':
        if (value.trim().isEmpty) return 'Enter clinic name';
        if (value.trim().length < 3) return 'Clinic name must be at least 3 characters';
        return null;
      case 'address':
        return addressValidator(value.trim());
      case 'phone':
        return phoneValidator(value.trim());
      case 'email':
        return emailValidator(value.trim());
      case 'website':
        if (value.trim().isNotEmpty && !value.trim().startsWith('http')) {
          return 'Website must start with http:// or https://';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _saveClinicSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await SettingsService.updateClinicSettings({
        'clinicName': _clinicNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clinic settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save clinic settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving clinic settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Clinic Name',
            controller: _clinicNameController,
            errorText: _fieldErrors['clinicName'],
            onChanged: (value) {
              setState(() {
                _fieldErrors['clinicName'] = _validateField('clinicName', value);
              });
            },
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Address',
            controller: _addressController,
            maxLines: 3,
            errorText: _fieldErrors['address'],
            onChanged: (value) {
              setState(() {
                _fieldErrors['address'] = _validateField('address', value);
              });
            },
          ),
          SizedBox(height: kSpacingLarge),
          
          Row(
            children: [
              Expanded(
                child: SettingsFormField(
                  label: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  errorText: _fieldErrors['phone'],
                  onChanged: (value) {
                    setState(() {
                      _fieldErrors['phone'] = _validateField('phone', value);
                    });
                  },
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _fieldErrors['email'],
                  onChanged: (value) {
                    setState(() {
                      _fieldErrors['email'] = _validateField('email', value);
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Website',
            controller: _websiteController,
            keyboardType: TextInputType.url,
            hintText: 'https://www.example.com',
            errorText: _fieldErrors['website'],
            onChanged: (value) {
              setState(() {
                _fieldErrors['website'] = _validateField('website', value);
              });
            },
          ),
          SizedBox(height: kSpacingLarge),

          // Save Clinic Settings Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveClinicSettings,
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save_outlined, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
