import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/breed_options.dart';

class AddEditPetPage extends StatefulWidget {
  final Pet? pet; // null for add, existing pet for edit

  const AddEditPetPage({super.key, this.pet});

  @override
  State<AddEditPetPage> createState() => _AddEditPetPageState();
}

class _AddEditPetPageState extends State<AddEditPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  
  UserModel? _user;
  bool _loading = false;
  String _selectedPetType = 'Dog';
  String _selectedBreed = '';
  List<String> _availableBreeds = [];

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initializeFormData();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthGuard.getCurrentUser();
    setState(() {
      _user = user;
    });
  }

  void _initializeFormData() {
    if (_isEditing) {
      final pet = widget.pet!;
      _petNameController.text = pet.petName;
      _ageController.text = pet.age.toString();
      _weightController.text = pet.weight.toString();
      _selectedPetType = pet.petType;
      _selectedBreed = pet.breed;
    }
    _updateAvailableBreeds();
  }

  void _updateAvailableBreeds() {
    setState(() {
      _availableBreeds = BreedOptions.getBreedsForPetType(_selectedPetType);
      if (_availableBreeds.isNotEmpty && !_availableBreeds.contains(_selectedBreed)) {
        _selectedBreed = _availableBreeds.first;
      }
    });
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate() || _user == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final now = DateTime.now();
      final pet = Pet(
        id: _isEditing ? widget.pet!.id : null,
        userId: _user!.uid,
        petName: _petNameController.text.trim(),
        petType: _selectedPetType,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        breed: _selectedBreed,
        createdAt: _isEditing ? widget.pet!.createdAt : now,
        updatedAt: now,
      );

      bool success;
      if (_isEditing) {
        success = await PetService.updatePet(pet);
      } else {
        final petId = await PetService.addPet(pet);
        success = petId != null;
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pet ${_isEditing ? 'updated' : 'added'} successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isEditing ? 'update' : 'add'} pet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Pet' : 'Add Pet',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePet,
              child: Text(
                _isEditing ? 'Update' : 'Save',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kMobileMarginHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Pet Name
              _buildTextFormField(
                controller: _petNameController,
                label: 'Pet Name',
                hint: 'Enter your pet\'s name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pet name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Pet name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Pet Type Dropdown
              _buildDropdownField(
                label: 'Pet Type',
                value: _selectedPetType,
                items: PetType.values.map((type) => type.displayName).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPetType = value!;
                    _updateAvailableBreeds();
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Breed Dropdown
              _buildDropdownField(
                label: 'Breed',
                value: _selectedBreed.isEmpty ? _availableBreeds.first : _selectedBreed,
                items: _availableBreeds,
                onChanged: (value) {
                  setState(() {
                    _selectedBreed = value!;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Age and Weight Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _ageController,
                      label: 'Age (months)',
                      hint: 'e.g., 24',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Age is required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age <= 0) {
                          return 'Enter valid age';
                        }
                        if (age > 300) {
                          return 'Age seems too high';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: 'e.g., 15.5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Weight is required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Enter valid weight';
                        }
                        if (weight > 200) {
                          return 'Weight seems too high';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Pet' : 'Add Pet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
