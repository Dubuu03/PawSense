import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../shared/content_container.dart';

class VetProfileBasicInfo extends StatelessWidget {
  final String clinicName;
  final String doctorName;
  final String email;
  final String phone;
  final String address;
  final String website;
  final bool isEmergencyAvailable;
  final bool isTelemedicineEnabled;
  final VoidCallback? onEmergencyToggle;
  final VoidCallback? onTelemedicineToggle;

  const VetProfileBasicInfo({
    super.key,
    required this.clinicName,
    required this.doctorName,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
    this.isEmergencyAvailable = false,
    this.isTelemedicineEnabled = false,
    this.onEmergencyToggle,
    this.onTelemedicineToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Clinic & Doctor Names
          Text(
            clinicName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            doctorName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Information
          ContactInfoTile(
            icon: Icons.email_outlined,
            text: email,
          ),
          ContactInfoTile(
            icon: Icons.phone_outlined,
            text: phone,
          ),
          ContactInfoTile(
            icon: Icons.location_on_outlined,
            text: address,
          ),
          ContactInfoTile(
            icon: Icons.language_outlined,
            text: website,
          ),

          const SizedBox(height: kSpacingSmall),
          
          Divider(
            color: AppColors.textTertiary,
            thickness: 1,           // line thickness
            height: 1,             // space around the line
          ),
           const SizedBox(height: kSpacingSmall),
          // Toggles
          AvailabilityToggle(
            title: 'Emergency Available',
            value: isEmergencyAvailable,
            onChanged: onEmergencyToggle,
          ),
          AvailabilityToggle(
            title: 'Telemedicine',
            value: isTelemedicineEnabled,
            onChanged: onTelemedicineToggle,
          ),
        ],
      ),
    );
  }
}

class ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const ContactInfoTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 20),
      title: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 18,
    );
  }
}

class AvailabilityToggle extends StatelessWidget {
  final String title;
  final bool value;
  final VoidCallback? onChanged;

  const AvailabilityToggle({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: kTextStyleSmall),
              Transform.scale(
                scale: 0.8, // 🔹 Smaller toggle
                child: Switch(
                  value: value,
                  onChanged: onChanged != null ? (_) => onChanged!() : null,
                ),
              ),
            ],
          ),
        )


      ],
    );
  }
}
