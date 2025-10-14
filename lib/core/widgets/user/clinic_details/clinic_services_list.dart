import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/models/clinic/clinic_service_model.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';

class ClinicServicesList extends StatefulWidget {
  final ClinicDetails clinic;

  const ClinicServicesList({
    super.key,
    required this.clinic,
  });

  @override
  State<ClinicServicesList> createState() => _ClinicServicesListState();
}

class _ClinicServicesListState extends State<ClinicServicesList> {
  late ClinicDetails _currentClinic;
  StreamSubscription<ClinicDetails?>? _clinicSubscription;

  @override
  void initState() {
    super.initState();
    _currentClinic = widget.clinic;
    _listenToClinicUpdates();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    super.dispose();
  }

  void _listenToClinicUpdates() {
    _clinicSubscription = ClinicDetailsService.streamClinicDetails(widget.clinic.clinicId)
        .listen((updatedClinic) {
      if (updatedClinic != null && mounted) {
        setState(() {
          _currentClinic = updatedClinic;
        });
        print('🔄 Services updated in real-time for clinic: ${updatedClinic.clinicName}');
      }
    }, onError: (error) {
      print('❌ Error listening to clinic updates: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter to show only active services
    final activeServices = _currentClinic.services.where((service) => service.isActive).toList();
    
    if (activeServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(kMobilePaddingMedium),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: kMobileBorderRadiusCardPreset,
          boxShadow: kMobileCardShadowSmall,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: kMobileSizedBoxMedium),
                Text(
                  'Services',
                  style: kMobileTextStyleTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Container(
              padding: const EdgeInsets.all(kMobilePaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: kMobileBorderRadiusButtonPreset,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: kMobileSizedBoxSmall),
                  Text(
                    'No Services Available',
                    style: kMobileTextStyleTitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This clinic has no active services at the moment.',
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.medical_services,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Services (${activeServices.length})',
                  style: kMobileTextStyleTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Show only active services in a more compact grid layout
          ...activeServices.take(6).map((service) => _buildServiceItem(service)),
          
          if (activeServices.length > 6) ...[
            const SizedBox(height: kMobileSizedBoxSmall),
            Center(
              child: TextButton(
                onPressed: () {
                  // Show all services
                },
                child: Text(
                  'View All ${activeServices.length} Services',
                  style: kMobileTextStyleViewAll.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceItem(ClinicService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      padding: const EdgeInsets.all(kMobilePaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: kMobileBorderRadiusSmallPreset,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getCategoryColor(service.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getCategoryIcon(service.category),
              size: 16,
              color: _getCategoryColor(service.category),
            ),
          ),
          const SizedBox(width: kMobileSizedBoxMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.serviceName,
                        style: kMobileTextStyleServiceTitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (service.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getCategoryName(service.category),
                  style: kMobileTextStyleServiceSubtitle.copyWith(
                    fontSize: 10,
                    color: _getCategoryColor(service.category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (service.serviceDescription.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.serviceDescription,
                    style: kMobileTextStyleServiceSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: kMobileSizedBoxMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PHP ${service.estimatedPrice}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              _buildServiceDetailChip(
                icon: Icons.access_time,
                label: service.duration,
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.consultation:
        return Icons.chat_bubble_outline;
      case ServiceCategory.diagnostic:
        return Icons.analytics_outlined;
      case ServiceCategory.preventive:
        return Icons.shield_outlined;
      case ServiceCategory.surgery:
        return Icons.local_hospital_outlined;
      case ServiceCategory.emergency:
        return Icons.emergency_outlined;
      case ServiceCategory.telemedicine:
        return Icons.video_call_outlined;
      case ServiceCategory.grooming:
        return Icons.pets_outlined;
      case ServiceCategory.boarding:
        return Icons.hotel_outlined;
      case ServiceCategory.training:
        return Icons.school_outlined;
      case ServiceCategory.other:
        return Icons.more_horiz_outlined;
    }
  }

  Color _getCategoryColor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.consultation:
        return AppColors.primary;
      case ServiceCategory.diagnostic:
        return AppColors.info;
      case ServiceCategory.preventive:
        return AppColors.success;
      case ServiceCategory.surgery:
        return AppColors.error;
      case ServiceCategory.emergency:
        return AppColors.warning;
      case ServiceCategory.telemedicine:
        return AppColors.primary;
      case ServiceCategory.grooming:
        return Color(0xFF8B5CF6);
      case ServiceCategory.boarding:
        return Color(0xFF06B6D4);
      case ServiceCategory.training:
        return Color(0xFF10B981);
      case ServiceCategory.other:
        return AppColors.textSecondary;
    }
  }

  String _getCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.consultation:
        return 'Consultation';
      case ServiceCategory.diagnostic:
        return 'Diagnostic';
      case ServiceCategory.preventive:
        return 'Preventive Care';
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
}