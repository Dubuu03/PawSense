import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/widgets/user/pets/pet_avatar.dart';

class PetInfoCard extends StatefulWidget {
  final String? nextAppointmentDate;
  final String? nextAppointmentTime;
  final Key? refreshKey; // Add this to force refresh

  const PetInfoCard({
    super.key,
    this.nextAppointmentDate,
    this.nextAppointmentTime,
    this.refreshKey,
  });

  @override
  State<PetInfoCard> createState() => _PetInfoCardState();
}

class _PetInfoCardState extends State<PetInfoCard> {
  List<Pet> _pets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void didUpdateWidget(PetInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh pets when widget updates or refreshKey changes
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadPets();
    }
  }

  // Public method to refresh pets
  void refreshPets() {
    if (mounted) {
      _loadPets();
    }
  }

  Future<void> _loadPets() async {
    print('DEBUG: PetInfoCard loading pets...');
    // Don't show loading if we already have data and are just refreshing
    final showLoading = _pets.isEmpty;
    
    try {
      setState(() {
        _loading = showLoading;
        _error = null;
      });

      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final pets = await PetService.getUserPets(user.uid);
        print('DEBUG: PetInfoCard loaded ${pets.length} pets');
        if (mounted) {
          setState(() {
            _pets = pets;
            _loading = false;
          });
        }
      } else {
        print('DEBUG: PetInfoCard user not found');
        if (mounted) {
          setState(() {
            _error = 'User not found';
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading pets: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load pets';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: kMobileMarginCard,
        padding: kMobilePaddingCard,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: kMobileBorderRadiusCardPreset,
          boxShadow: kMobileCardShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: kMobileMarginCard,
        padding: kMobilePaddingCard,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: kMobileBorderRadiusCardPreset,
          boxShadow: kMobileCardShadow,
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              _error!,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            ElevatedButton(
              onPressed: _loadPets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Pets',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              if (_pets.length > 2)
                TextButton(
                  onPressed: () async {
                    print('DEBUG: Top View All button clicked');
                    try {
                      await context.push('/pets');
                      print('DEBUG: Navigation to /pets completed, refreshing pets');
                      // Refresh pets when returning from View All page
                      _loadPets();
                    } catch (e) {
                      print('DEBUG: Navigation error: $e');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: kMobileButtonPadding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All (${_pets.length})',
                    style: kMobileTextStyleViewAll.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          
          // Description below title
          const SizedBox(height: 4),
          Text(
            _pets.isEmpty 
                ? 'Add your first pet to get started'
                : 'Essential details about your pet',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Content based on pets count
          _pets.isEmpty ? _buildEmptyState() : _buildPetsContent(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.pets,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: kMobileSizedBoxLarge),
        
        // Message
        Text(
          'No pets added yet',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: kMobileSizedBoxSmall),
        
        Text(
          'Add your first pet to start tracking their health',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kMobileSizedBoxLarge),
        
        // Add Pet button
        Container(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: () async {
              print('DEBUG: Add Pet button clicked');
              try {
                final result = await context.push('/add-pet');
                print('DEBUG: Navigation to /add-pet completed, result: $result');
                // Refresh pets when returning from Add Pet page if pet was added
                if (result == true) {
                  _loadPets();
                }
              } catch (e) {
                print('DEBUG: Navigation error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Pet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetsContent() {
    // Limit to 2 pets maximum on home page
    final displayPets = _pets.take(2).toList();
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pets section - show only 2 pets maximum
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Show pets in a single row (max 2)
                Row(
                  children: displayPets.map((pet) => 
                    Expanded(child: _buildPetIcon(pet))
                  ).toList(),
                ),
                const SizedBox(height: 12),
                // View All button below pets (always show if there are pets)
                if (_pets.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        print('DEBUG: Bottom View All button clicked');
                        try {
                          await context.push('/pets');
                          print('DEBUG: Navigation to /pets completed, refreshing pets');
                          // Refresh pets when returning from View All page
                          _loadPets();
                        } catch (e) {
                          print('DEBUG: Navigation error: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _pets.length > 2 ? 'View All (${_pets.length})' : 'View All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next appointment section - always show
          Expanded(
            flex: 3,
            child: _buildAppointmentSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPetIcon(Pet pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          PetAvatar(
            petType: pet.petType,
            imageUrl: pet.imageUrl,
            size: 40,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 6),
          Text(
            pet.petName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSection() {
    // Check if we have appointment data
    bool hasAppointment = widget.nextAppointmentDate != null && widget.nextAppointmentTime != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and title in one row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: hasAppointment 
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  hasAppointment ? Icons.event_available : Icons.event_busy,
                  size: 14,
                  color: hasAppointment ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (hasAppointment) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.nextAppointmentDate!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.nextAppointmentTime!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No Appointments\nToday',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
