import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'settings_form_field.dart';

class ClinicSettings extends StatefulWidget {
  const ClinicSettings({Key? key}) : super(key: key);

  @override
  State<ClinicSettings> createState() => _ClinicSettingsState();
}

class _ClinicSettingsState extends State<ClinicSettings> {
  final _clinicNameController = TextEditingController(text: 'PawSense Veterinary Clinic');
  final _addressController = TextEditingController(text: '123 Pet Care Lane, Animal City, AC 12345');
  final _phoneController = TextEditingController(text: '+1 (555) 123-4567');
  final _emailController = TextEditingController(text: 'info@pawsense.com');
  final _websiteController = TextEditingController(text: 'www.pawsense.com');
  final _defaultDurationController = TextEditingController(text: '30');
  final _bufferTimeController = TextEditingController(text: '10');
  final _advanceBookingController = TextEditingController(text: '60');

  bool _autoApproveAppointments = true;

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
        ],
      ),
    );
  }
}
