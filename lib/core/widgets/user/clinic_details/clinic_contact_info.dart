import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/models/clinic/clinic_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ClinicContactInfo extends StatefulWidget {
  final ClinicDetails clinic;

  const ClinicContactInfo({
    super.key,
    required this.clinic,
  });

  @override
  State<ClinicContactInfo> createState() => _ClinicContactInfoState();
}

class _ClinicContactInfoState extends State<ClinicContactInfo> {
  Clinic? _basicClinicData;

  @override
  void initState() {
    super.initState();
    _loadBasicClinicData();
  }

  Future<void> _loadBasicClinicData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinic.clinicId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _basicClinicData = Clinic.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      print('Error loading basic clinic data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: kMobileTextStyleTitle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Contact items in column
          Column(
            children: [
              _buildContactItem(
                icon: Icons.phone,
                label: 'Contact Number',
                value: widget.clinic.phone,
                onTap: () => _makePhoneCall(widget.clinic.phone),
                color: AppColors.primary,
                isFullWidth: true,
              ),
              const SizedBox(height: kMobileSizedBoxMedium),
              _buildContactItem(
                icon: Icons.email,
                label: 'Email',
                value: widget.clinic.email,
                onTap: () => _sendEmail(widget.clinic.email),
                color: AppColors.info,
                isFullWidth: true,
              ),
            ],
          ),
          
          // Website (if available from multiple sources)
          if (_getWebsiteUrl() != null) ...[
            const SizedBox(height: kMobileSizedBoxMedium),
            _buildContactItem(
              icon: Icons.language,
              label: 'Website',
              value: _getWebsiteUrl()!,
              onTap: () => _openWebsite(_getWebsiteUrl()!),
              color: AppColors.success,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    required Color color,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: kMobileBorderRadiusButtonPreset,
      child: Container(
        padding: const EdgeInsets.all(kMobilePaddingSmall),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: kMobileBorderRadiusButtonPreset,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: isFullWidth ? Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: kMobileSizedBoxMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: color,
              size: 16,
            ),
          ],
        ) : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _truncateText(value, isFullWidth ? 30 : 15),
              style: kMobileTextStyleSubtitle.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get website URL from multiple possible sources
  String? _getWebsiteUrl() {
    // First check the basic clinic data for direct website field
    if (_basicClinicData?.website != null && _basicClinicData!.website!.isNotEmpty) {
      return _basicClinicData!.website;
    }
    
    // Check socialMedia map as fallback
    if (widget.clinic.socialMedia != null && widget.clinic.socialMedia!['website'] != null) {
      final website = widget.clinic.socialMedia!['website'] as String?;
      if (website != null && website.isNotEmpty) {
        return website;
      }
    }
    
    return null;
  }

  void _makePhoneCall(String phone) {
    if (phone.isEmpty) {
      _showSnack('No phone number available');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    canLaunchUrl(uri).then((can) async {
      if (can) {
        await launchUrl(uri);
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: phone));
        _showSnack('Phone number copied to clipboard');
      }
    });
  }

  void _sendEmail(String email) {
    if (email.isEmpty) {
      _showSnack('No email available');
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );

    canLaunchUrl(uri).then((can) async {
      if (can) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: email));
        _showSnack('Email copied to clipboard');
      }
    });
  }

  void _openWebsite(String website) {
    if (website.isEmpty) {
      _showSnack('No website available');
      return;
    }

    var url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);
    canLaunchUrl(uri).then((can) async {
      if (can) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        _showSnack('Website URL copied to clipboard');
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}