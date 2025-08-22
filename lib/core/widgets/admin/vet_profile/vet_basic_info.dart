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

  const VetProfileBasicInfo({
    super.key,
    required this.clinicName,
    required this.doctorName,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
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
          SizedBox(height: kSpacingMedium),

          // Clinic & Doctor Names
          Text(
            clinicName,
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            doctorName,
            style: TextStyle(
              fontSize: kFontSizeRegular,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: kSpacingMedium),

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
      leading: Icon(
        icon, 
        color: AppColors.textSecondary, 
        size: kIconSizeMedium,
      ),
      title: Text(
        text, 
        style: TextStyle(
          fontSize: kFontSizeSmall, 
          color: AppColors.textSecondary, 
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: kSpacingMedium + 2,
    );
  }
}
