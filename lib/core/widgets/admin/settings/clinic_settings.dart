import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
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
  final _defaultDurationController = TextEditingController();
  final _bufferTimeController = TextEditingController();
  final _advanceBookingController = TextEditingController();

  bool _autoApproveAppointments = true;
  bool _isLoading = true;
  bool _isSaving = false;

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
          _defaultDurationController.text = (clinicData['defaultAppointmentDuration'] ?? 30).toString();
          _bufferTimeController.text = (clinicData['bufferTime'] ?? 10).toString();
          _advanceBookingController.text = (clinicData['advanceBookingDays'] ?? 60).toString();
          _autoApproveAppointments = clinicData['autoApproveAppointments'] ?? true;
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
        'defaultAppointmentDuration': int.tryParse(_defaultDurationController.text) ?? 30,
        'bufferTime': int.tryParse(_bufferTimeController.text) ?? 10,
        'advanceBookingDays': int.tryParse(_advanceBookingController.text) ?? 60,
        'autoApproveAppointments': _autoApproveAppointments,
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
    _defaultDurationController.dispose();
    _bufferTimeController.dispose();
    _advanceBookingController.dispose();
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
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Address',
            controller: _addressController,
            maxLines: 3,
          ),
          SizedBox(height: kSpacingLarge),
          
          Row(
            children: [
              Expanded(
                child: SettingsFormField(
                  label: 'Phone',
                  controller: _phoneController,
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Email',
                  controller: _emailController,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Website',
            controller: _websiteController,
          ),
          SizedBox(height: kSpacingLarge * 2),
          
          // Appointment Settings
          Text(
            'Appointment Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          // Auto-approve toggle
          Container(
            padding: EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-approve appointments',
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Automatically confirm new appointment requests',
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoApproveAppointments,
                  onChanged: (value) {
                    setState(() {
                      _autoApproveAppointments = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          Row(
            children: [
              Expanded(
                child: SettingsFormField(
                  label: 'Default Duration (min)',
                  controller: _defaultDurationController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Buffer Time (min)',
                  controller: _bufferTimeController,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Advance Booking (days)',
                  controller: _advanceBookingController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
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
