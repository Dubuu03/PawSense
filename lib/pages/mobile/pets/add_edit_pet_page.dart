import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/breed_options.dart';
import 'package:pawsense/core/widgets/user/pets/pet_form_fields.dart';

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
  String? _petImageUrl;
  bool _uploadingImage = false;

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
      _petImageUrl = pet.imageUrl;
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

  Future<void> _pickPetImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _uploadingImage = true;
        });

        final cloudinaryService = CloudinaryService();
        final cloudinaryUrl = await cloudinaryService.uploadImageFromFile(
          pickedFile.path,
          folder: 'pet_images',
        );

        setState(() {
          _petImageUrl = cloudinaryUrl;
          _uploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet photo uploaded successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _uploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
        imageUrl: _petImageUrl,
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
              PetFormTextField(
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
              
              // Pet Picture Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pet Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickPetImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: _uploadingImage
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(58), // Slightly smaller to fit inside border
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  )
                                : _petImageUrl != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(2), // Account for border width
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(58),
                                          child: Image.network(
                                            _petImageUrl!,
                                            width: 116,
                                            height: 116,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(58),
                                                ),
                                                child: Icon(
                                                  Icons.pets,
                                                  size: 40,
                                                  color: AppColors.primary,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.pets,
                                          size: 40,
                                          color: AppColors.primary.withValues(alpha: 0.6),
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _petImageUrl != null ? Icons.edit : Icons.camera_alt,
                                color: AppColors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _petImageUrl != null ? 'Tap to change photo' : 'Tap to add photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Pet Type Dropdown
              PetFormDropdownField(
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
              
              const SizedBox(height: 24),
              
              // Breed Dropdown
              PetFormDropdownField(
                label: 'Breed',
                value: _selectedBreed.isEmpty ? _availableBreeds.first : _selectedBreed,
                items: _availableBreeds,
                onChanged: (value) {
                  setState(() {
                    _selectedBreed = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Age and Weight Row
              Row(
                children: [
                  Expanded(
                    child: PetFormTextField(
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
                    child: PetFormTextField(
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
}
