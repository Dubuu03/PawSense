import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';

class AddEditBreedModal extends StatefulWidget {
  final PetBreed? breed;
  final Function(PetBreed) onSave;

  const AddEditBreedModal({
    super.key,
    this.breed,
    required this.onSave,
  });

  @override
  State<AddEditBreedModal> createState() => _AddEditBreedModalState();
}

class _AddEditBreedModalState extends State<AddEditBreedModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedSpecies = 'dog';
  bool _isActive = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.breed != null) {
      _nameController.text = widget.breed!.name;
      _selectedSpecies = widget.breed!.species;
      _isActive = widget.breed!.isActive;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Get current user ID
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      final userId = currentUser?.uid ?? '';
      
      final breed = PetBreed(
        id: widget.breed?.id ?? '',
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        status: _isActive ? 'active' : 'inactive',
        createdAt: widget.breed?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.breed?.createdBy ?? userId,
      );
      
      await widget.onSave(breed);
    } catch (e) {
      setState(() => _isSaving = false);
      rethrow;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(kSpacingMedium + 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kBorderRadius),
                  topRight: Radius.circular(kBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.pets, color: AppColors.primary, size: 22),
                  SizedBox(width: kSpacingSmall + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.breed == null ? 'Add New Breed' : 'Edit Breed',
                          style: kTextStyleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fill in the details below',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            
            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(kSpacingMedium + 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breed Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Breed Name',
                        hint: 'e.g., Labrador Retriever',
                        required: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Breed name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Breed name must be at least 2 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Breed name must be less than 50 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: kSpacingMedium + 4),
                      
                      // Species (Radio buttons)
                      Text(
                        'Species *',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: kSpacingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Text('🐱 ', style: TextStyle(fontSize: 18)),
                                  Text('Cat'),
                                ],
                              ),
                              value: 'cat',
                              groupValue: _selectedSpecies,
                              onChanged: (value) {
                                setState(() => _selectedSpecies = value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: kSpacingSmall),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Text('🐶 ', style: TextStyle(fontSize: 18)),
                                  Text('Dog'),
                                ],
                              ),
                              value: 'dog',
                              groupValue: _selectedSpecies,
                              onChanged: (value) {
                                setState(() => _selectedSpecies = value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: kSpacingMedium),
                      
                      // Status toggle
                      _buildStatusToggle(),
                      
                      SizedBox(height: kSpacingMedium),
                      
                      // Info box
                      Container(
                        padding: EdgeInsets.all(kSpacingSmall + 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: kSpacingSmall + 4),
                            Expanded(
                              child: Text(
                                'Active breeds will be available for users when adding their pets.',
                                style: kTextStyleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer buttons
            Container(
              padding: EdgeInsets.all(kSpacingMedium + 4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: kSpacingSmall + 4),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingLarge,
                        vertical: kSpacingSmall + 4,
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Save Breed'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: kTextStyleRegular.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: kTextStyleRegular.copyWith(color: AppColors.error),
              ),
          ],
        ),
        SizedBox(height: kSpacingSmall),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: maxLength != null ? (_) => setState(() {}) : null,
        ),
      ],
    );
  }
  
  Widget _buildStatusToggle() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: kSpacingSmall),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breed Status',
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isActive 
                      ? 'Breed is currently active and visible to users' 
                      : 'Breed is currently inactive and hidden from users',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
