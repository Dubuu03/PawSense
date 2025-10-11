import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'package:pawsense/core/services/user/user_services.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/validators.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cloudinaryService = CloudinaryService();
  final _userServices = UserServices();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isLoadingData = true;
  String? _profileImageUrl;
  UserModel? _currentUser; // Store the current user data
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Field tracking for validation
  final Map<String, String?> _fieldErrors = {
    'firstName': null,
    'lastName': null,
    'username': null,
    'contactNumber': null,
    'address': null,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchLatestUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _fetchLatestUserData() async {
    try {
      // Fetch the latest user data from Firestore
      final latestUser = await _userServices.getUserByUid(widget.user.uid);
      if (latestUser != null && mounted) {
        setState(() {
          _currentUser = latestUser;
          _isLoadingData = false;
        });
        _initializeFields();
      } else {
        // Fallback to passed user data if fetch fails
        setState(() {
          _currentUser = widget.user;
          _isLoadingData = false;
        });
        _initializeFields();
      }
    } catch (e) {
      // Fallback to passed user data if there's an error
      if (mounted) {
        setState(() {
          _currentUser = widget.user;
          _isLoadingData = false;
        });
        _initializeFields();
      }
    }
  }

  void _initializeFields() {
    if (_currentUser != null) {
      _firstNameController.text = _currentUser!.firstName ?? '';
      _lastNameController.text = _currentUser!.lastName ?? '';
      _usernameController.text = _currentUser!.username;
      _contactNumberController.text = _currentUser!.contactNumber ?? '';
      _addressController.text = _currentUser!.address ?? '';
      _profileImageUrl = _currentUser!.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
          _isUploadingImage = true;
        });

        // Upload to Cloudinary
        final cloudinaryUrl = await _cloudinaryService.uploadImageFromFile(
          pickedFile.path,
          folder: 'profile_images',
        );

        setState(() {
          _profileImageUrl = cloudinaryUrl;
          _isUploadingImage = false;
        });

        _showSuccessSnack('Profile picture updated successfully!');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnack('Failed to upload image. Please try again.');
    }
  }



  Future<void> _saveProfile() async {
    // Clear previous errors
    setState(() {
      _fieldErrors.updateAll((key, value) => null);
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated user model using current user data
      final updatedUser = (_currentUser ?? widget.user).copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      // Update user in Firestore
      await _userServices.updateUser(updatedUser);

      _showSuccessSnack('Profile updated successfully!');
      
      // Navigate back after a short delay and return the updated user
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pop(updatedUser); // Return the updated user data
        }
      });
    } catch (e) {
      _showErrorSnack('Failed to update profile. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgsecond,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: kSpacingLarge),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Profile Picture Section
                        _buildProfilePictureSection(),
                        
                        const SizedBox(height: 30),
                    
                    // Form Fields
                    _buildFormField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                      errorKey: 'firstName',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                      errorKey: 'lastName',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                      errorKey: 'username',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: phoneValidator,
                      errorKey: 'contactNumber',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 1,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                      errorKey: 'address',
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kButtonRadius),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: kTextStyleRegular.copyWith(
                                  fontSize: 14,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _isUploadingImage
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change profile picture',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final initials = _getInitials();
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if ((_currentUser ?? widget.user).username.isNotEmpty) {
      return (_currentUser ?? widget.user).username[0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required String errorKey,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines > 1 ? null : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) {
          if (_fieldErrors[errorKey] != null) {
            setState(() => _fieldErrors[errorKey] = null);
          }
        },
        style: kTextStyleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          labelStyle: kTextStyleSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _fieldErrors[errorKey] != null ? AppColors.error : AppColors.border,
              width: _fieldErrors[errorKey] != null ? 1.5 : 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _fieldErrors[errorKey] != null ? AppColors.error : AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: maxLines > 1 ? 16 : 12),
          isDense: maxLines == 1,
        ),
      ),
    );
  }


}