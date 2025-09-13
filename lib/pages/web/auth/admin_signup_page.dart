import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/models/clinic/clinic_model.dart';
import '../../../core/models/clinic/clinic_details_model.dart';
import '../../../core/models/clinic/clinic_service_model.dart';
import '../../../core/models/clinic/clinic_certification_model.dart';
import '../../../core/models/clinic/clinic_license_model.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});

  @override
  State<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _authService = AuthService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Account Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();

  // Step 2: Clinic Info
  final _clinicNameController = TextEditingController();
  final _clinicDescriptionController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _clinicEmailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 3: Services, Certifications, and Licenses - Dynamic lists
  final List<ClinicService> _services = [];
  final List<ClinicCertification> _certifications = [];
  final List<ClinicLicense> _licenses = [];

  // Image data for certifications and licenses
  final Map<int, Uint8List?> _certificationImages = {};
  final Map<int, String?> _certificationImageNames = {};
  final Map<int, Uint8List?> _licenseImages = {};
  final Map<int, String?> _licenseImageNames = {};

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultEntries();
  }

  /// Initialize with one empty service, certification, and license entry
  void _initializeDefaultEntries() {
    // Add one empty service entry
    _addService();
    // Add one empty certification entry  
    _addCertification();
    // Add one empty license entry
    _addLicense();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _clinicNameController.dispose();
  _clinicDescriptionController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _clinicEmailController.dispose();
    _websiteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Prepare services with dynamic data before signup
  List<ClinicService> _prepareServicesForSignup() {
    return _services.where((service) => _isServiceValid(service)).map((service) {
      // Generate service name if empty but has description
      String finalServiceName = service.serviceName.trim().isEmpty
          ? _generateServiceNameFromDescription(service.serviceDescription, service.category.name)
          : service.serviceName;

      // Return updated service with generated name
      return service.copyWith(
        serviceName: finalServiceName,
        // Ensure required fields are not empty
        serviceDescription: service.serviceDescription.trim().isEmpty 
            ? 'Professional veterinary service' 
            : service.serviceDescription,
        estimatedPrice: service.estimatedPrice.trim().isEmpty 
            ? '0.00' 
            : service.estimatedPrice,
        duration: service.duration.trim().isEmpty 
            ? '30 mins' 
            : service.duration,
      );
    }).toList();
  }

  /// Prepare certifications with dynamic data before signup
  List<ClinicCertification> _prepareCertificationsForSignup() {
    return _certifications.where((cert) => _isCertificationValid(cert)).toList();
  }

  /// Prepare licenses with dynamic data before signup
  List<ClinicLicense> _prepareLicensesForSignup() {
    return _licenses.where((license) => _isLicenseValid(license)).toList();
  }

  /// Check if service has enough data to be valid
  bool _isServiceValid(ClinicService service) {
    // At least service description OR service name should be provided
    return service.serviceDescription.trim().isNotEmpty || service.serviceName.trim().isNotEmpty;
  }

  /// Check if certification has enough data to be valid
  bool _isCertificationValid(ClinicCertification cert) {
    // Certification name, issuer should be provided (image is optional for backend flexibility)
    return cert.name.trim().isNotEmpty && 
           cert.issuer.trim().isNotEmpty;
  }

  /// Preview image in a dialog
  void _previewImage(Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: kTextStyleRegular.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
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

  /// Generate service name from description and category
  String _generateServiceNameFromDescription(String description, String category) {
    final desc = description.toLowerCase();
    
    // Pattern matching for common veterinary services
    if (desc.contains('skin scraping') || desc.contains('microscopic examination')) {
      return 'Skin Scraping & Analysis';
    } else if (desc.contains('vaccination') || desc.contains('vaccine')) {
      return 'Vaccination Package';
    } else if (desc.contains('dental') || desc.contains('teeth cleaning')) {
      return 'Dental Cleaning Service';
    } else if (desc.contains('surgery') || desc.contains('operation')) {
      return 'Surgical Procedure';
    } else if (desc.contains('consultation') || desc.contains('check-up') || desc.contains('checkup')) {
      return 'Veterinary Consultation';
    } else if (desc.contains('grooming') || desc.contains('bath') || desc.contains('nail trim')) {
      return 'Pet Grooming Service';
    } else if (desc.contains('x-ray') || desc.contains('xray') || desc.contains('imaging')) {
      return 'Diagnostic Imaging';
    } else if (desc.contains('blood test') || desc.contains('lab work') || desc.contains('laboratory')) {
      return 'Laboratory Testing';
    } else if (desc.contains('emergency')) {
      return 'Emergency Treatment';
    } else if (desc.contains('spay') || desc.contains('neuter') || desc.contains('sterilization')) {
      return 'Spay/Neuter Service';
    } else if (desc.contains('deworming') || desc.contains('parasite')) {
      return 'Parasite Treatment';
    } else {
      // Generate from category if no pattern matches
      final categoryName = category[0].toUpperCase() + category.substring(1);
      return '$categoryName Service';
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKeys[2].currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the terms and conditions';
      });
      return;
    }

    // Validate that at least one certification and one license are provided
    final validCertifications = _certifications.where((cert) => _isCertificationValid(cert)).toList();
    final validLicenses = _licenses.where((license) => _isLicenseValid(license)).toList();

    if (validCertifications.isEmpty) {
      setState(() {
        _errorMessage = 'At least one certification is required';
      });
      return;
    }

    if (validLicenses.isEmpty) {
      setState(() {
        _errorMessage = 'At least one license is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prepare services, certifications, and licenses with dynamic data before signup
      final preparedServices = _prepareServicesForSignup();
      final preparedCertifications = _prepareCertificationsForSignup();
      final preparedLicenses = _prepareLicensesForSignup();

      // Re-key image maps to match prepared lists and filter nulls
      final certImagesFiltered = <int, Uint8List>{};
      final certNamesFiltered = <int, String>{};
      for (int i = 0; i < preparedCertifications.length; i++) {
        // original UI index might differ; we map by order
        final uiIndex = i; // assume prepared lists follow the same ordering as _certifications
        final bytes = _certificationImages[uiIndex];
        final name = _certificationImageNames[uiIndex];
        if (bytes != null && name != null) {
          certImagesFiltered[i] = bytes;
          certNamesFiltered[i] = name;
        }
      }

      final licenseImagesFiltered = <int, Uint8List>{};
      final licenseNamesFiltered = <int, String>{};
      for (int i = 0; i < preparedLicenses.length; i++) {
        final uiIndex = i;
        final bytes = _licenseImages[uiIndex];
        final name = _licenseImageNames[uiIndex];
        if (bytes != null && name != null) {
          licenseImagesFiltered[i] = bytes;
          licenseNamesFiltered[i] = name;
        }
      }

      // Create the auth account with dynamic field structure
      final result = await _authService.signUpClinicAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        clinic: Clinic(
          id: '', // Will be set to uid
          userId: '', // Will be set to uid
          clinicName: _clinicNameController.text.trim(),
          address: _clinicAddressController.text.trim(),
          phone: _clinicPhoneController.text.trim(),
          email: _clinicEmailController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          createdAt: DateTime.now(),
        ),
        clinicDetailsData: ClinicDetails(
          id: '', // Will be generated
          clinicId: '', // Will be set to uid
      clinicName: _clinicNameController.text.trim(),
      description: _clinicDescriptionController.text.trim().isEmpty
        ? 'Veterinary clinic providing comprehensive pet care services'
        : _clinicDescriptionController.text.trim(),
          address: _clinicAddressController.text.trim(),
          phone: _clinicPhoneController.text.trim(),
          email: _clinicEmailController.text.trim(),
          services: preparedServices,
          certifications: preparedCertifications,
          licenses: preparedLicenses,
          createdAt: DateTime.now(),
  ).toMap(),
  certificationImages: certImagesFiltered.isEmpty ? null : certImagesFiltered,
  certificationImageNames: certNamesFiltered.isEmpty ? null : certNamesFiltered,
  licenseImages: licenseImagesFiltered.isEmpty ? null : licenseImagesFiltered,
  licenseImageNames: licenseNamesFiltered.isEmpty ? null : licenseNamesFiltered,
      );

      if (result.success && result.user != null) {
        // License data (ID, dates) saved successfully
        // Document images are kept in UI state but not uploaded to storage yet
        // Documents can be uploaded later through admin panel or profile management
        print('✅ Account created successfully: ${result.user!.uid}');
        print('   Note: License data saved, document images will be uploaded later');
        
        // Show success message and navigate to login
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Signup failed. Please try again.';
        });
      }
    } catch (e) {
      print('Signup error: $e'); // Add debug print
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.pending_actions, color: AppColors.warning, size: 64),
        title: Text(
          'Registration Submitted!',
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your registration has been submitted with all the license information. Please wait for admin approval before logging in.\n\nNote: Document uploads for certifications and licenses will be available in your profile after approval.',
          style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/web_login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Continue to Sign In'),
          ),
        ],
      ),
    );
  }

  // Service management methods
  void _addService() {
    setState(() {
      _services.add(
        ClinicService(
          id: 'service_${DateTime.now().millisecondsSinceEpoch}', // Dynamic ID
          clinicId: '', // Will be set to real clinic ID during signup
          serviceName: '',
          serviceDescription: '',
          estimatedPrice: '',
          duration: '30 mins',
          category: ServiceCategory.consultation,
          isActive: true, // Set to true so service is available when created
          isVerified: false, // Set to false - needs admin verification
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeService(int index) {
    setState(() {
      if (_services.length > 1) {
        _services.removeAt(index);
      }
    });
  }

  void _updateService(
    int index, {
    String? serviceName,
    String? serviceDescription,
    String? estimatedPrice,
    String? duration,
    ServiceCategory? category,
  }) {
    setState(() {
      _services[index] = _services[index].copyWith(
        serviceName: serviceName ?? _services[index].serviceName,
        serviceDescription:
            serviceDescription ?? _services[index].serviceDescription,
        estimatedPrice: estimatedPrice ?? _services[index].estimatedPrice,
        duration: duration ?? _services[index].duration,
        category: category ?? _services[index].category,
      );
    });
  }

  // Certification management methods
  void _addCertification() {
    setState(() {
      _certifications.add(
        ClinicCertification(
          id: 'cert_${DateTime.now().millisecondsSinceEpoch}', // Dynamic ID
          clinicId: '', // Will be set to real clinic ID during signup
          name: '',
          issuer: '',
          dateIssued: Timestamp.now(),
          dateExpiry: null,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeCertification(int index) {
    setState(() {
      if (_certifications.length > 1) {
        _certifications.removeAt(index);
      }
    });
  }

  void _updateCertification(
    int index, {
    String? name,
    String? issuer,
    Timestamp? dateIssued,
    Timestamp? dateExpiry,
  }) {
    setState(() {
      _certifications[index] = _certifications[index].copyWith(
        name: name ?? _certifications[index].name,
        issuer: issuer ?? _certifications[index].issuer,
        dateIssued: dateIssued ?? _certifications[index].dateIssued,
        dateExpiry: dateExpiry ?? _certifications[index].dateExpiry,
      );
    });
  }

  Future<void> _selectCertificationDate(int index, bool isIssued) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssued
          ? _certifications[index].dateIssued.toDate()
          : (_certifications[index].dateExpiry?.toDate() ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isIssued) {
          _certifications[index] = _certifications[index].copyWith(
            dateIssued: Timestamp.fromDate(picked),
          );
        } else {
          _certifications[index] = _certifications[index].copyWith(
            dateExpiry: Timestamp.fromDate(picked),
          );
        }
      });
    }
  }

  // License management methods
  void _addLicense() {
    setState(() {
      _licenses.add(
        ClinicLicense(
          id: 'license_${DateTime.now().millisecondsSinceEpoch}', // Dynamic ID
          clinicId: '', // Will be set to real clinic ID during signup
          licenseId: '', // License ID to be entered by user
          licensePictureUrl: null, // Will be set after image upload (optional for now)
          licensePictureFileId: null, // Will be set after image upload (optional for now)
          issueDate: Timestamp.now(),
          expiryDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))), // Default 1 year
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeLicense(int index) {
    setState(() {
      if (_licenses.length > 1) {
        _licenses.removeAt(index);
        // Remove associated image data
        _licenseImages.remove(index);
        _licenseImageNames.remove(index);
      }
    });
  }

  void _updateLicense(
    int index, {
    String? licenseId,
    Timestamp? issueDate,
    Timestamp? expiryDate,
  }) {
    setState(() {
      _licenses[index] = _licenses[index].copyWith(
        licenseId: licenseId ?? _licenses[index].licenseId,
        issueDate: issueDate ?? _licenses[index].issueDate,
        expiryDate: expiryDate ?? _licenses[index].expiryDate,
      );
    });
  }

  Future<void> _selectLicenseDate(int index, bool isIssued) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssued
          ? _licenses[index].issueDate.toDate()
          : _licenses[index].expiryDate.toDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isIssued) {
          _licenses[index] = _licenses[index].copyWith(
            issueDate: Timestamp.fromDate(picked),
          );
        } else {
          _licenses[index] = _licenses[index].copyWith(
            expiryDate: Timestamp.fromDate(picked),
          );
        }
      });
    }
  }

  // Image management methods for certifications
  Future<void> _pickCertificationImage(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _certificationImages[index] = bytes;
          _certificationImageNames[index] = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeCertificationImage(int index) {
    setState(() {
      _certificationImages.remove(index);
      _certificationImageNames.remove(index);
    });
  }

  // Image management methods for licenses
  Future<void> _pickLicenseImage(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _licenseImages[index] = bytes;
          _licenseImageNames[index] = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeLicenseImage(int index) {
    setState(() {
      _licenseImages.remove(index);
      _licenseImageNames.remove(index);
    });
  }

  /// Check if license has enough data to be valid
  bool _isLicenseValid(ClinicLicense license) {
    // License ID should be provided (image is optional for backend flexibility)
    return license.licenseId.trim().isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _handleSignup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isActive
                    ? AppColors.primary
                    : AppColors.border,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: AppColors.white,
                size: 16,
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep
                    ? AppColors.success
                    : AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildAccountInfoStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your admin account credentials',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // First Name and Last Name Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Username
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Contact Number
          _buildTextField(
            controller: _contactNumberController,
            label: 'Contact Number',
            hint: 'Enter your contact number',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Contact number is required';
              }
              if (value.length != 11) {
                return 'Contact number must be 11 digits';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Contact number must contain only numbers';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

  

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Information',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your veterinary clinic',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Clinic Name
          _buildTextField(
            controller: _clinicNameController,
            label: 'Clinic Name',
            hint: 'Enter your clinic name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your clinic name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Clinic Description (optional)
          Text(
            'Clinic Description (Optional)',
            style: kTextStyleSmall.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _clinicDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Brief description of your clinic services, specialties, or mission',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.length > 1000) {
                return 'Description must be under 1000 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Clinic Address
          _buildTextField(
            controller: _clinicAddressController,
            label: 'Clinic Address',
            hint: 'Enter your clinic address',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your clinic address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Phone and Email Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _clinicPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Contact number is required';
                    }
                    if (value.length != 11) {
                      return 'Contact number must be 11 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Contact number must contain only numbers';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _clinicEmailController,
                  label: 'Clinic Email',
                  hint: 'Enter clinic email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter clinic email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Website (Optional)
          _buildTextField(
            controller: _websiteController,
            label: 'Website (Optional)',
            hint: 'Enter your clinic website',
            keyboardType: TextInputType.url,
            validator: (value) {
              // Optional field, only validate if not empty
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^https?://').hasMatch(value)) {
                  return 'Please enter a valid URL starting with http:// or https://';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicDetailsStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services, Certifications & Licenses',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your clinic services, certifications, and licenses',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Services Section
          _buildServicesSection(),
          const SizedBox(height: 32),

          // Certifications Section
          _buildCertificationsSection(),
          const SizedBox(height: 32),

          // Licenses Section
          _buildLicensesSection(),
          const SizedBox(height: 32),

          // Terms and Conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (value) =>
                    setState(() => _agreedToTerms = value ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: kTextStyleSmall.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: kTextStyleSmall.copyWith(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle terms and conditions tap
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: kTextStyleSmall.copyWith(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle privacy policy tap
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clinic Services',
              style: kTextStyleRegular.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addService,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: kTextStyleSmall.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._services.asMap().entries.map((entry) {
          final index = entry.key;
          return _buildServiceCard(index);
        }),
      ],
    );
  }

  Widget _buildServiceCard(int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service ${index + 1}',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_services.length > 1)
                  IconButton(
                    onPressed: () => _removeService(index),
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Service Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // spacing between
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<ServiceCategory>(
                    isExpanded: true, // 👈 important
                    value: _services[index].category,
                    onChanged: (value) =>
                        _updateService(index, category: value),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16, // 👈 match TextFormField height
                        horizontal: 8,
                      ),
                    ),
                    items: ServiceCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _services[index].serviceDescription,
              onChanged: (value) =>
                  _updateService(index, serviceDescription: value),
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _services[index].estimatedPrice,
                    onChanged: (value) =>
                        _updateService(index, estimatedPrice: value),
                    decoration: InputDecoration(
                      labelText: 'Estimated Price',
                      border: OutlineInputBorder(),
                      prefixText: '₱ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _services[index].duration,
                    onChanged: (value) =>
                        _updateService(index, duration: value),
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 30 mins',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Certifications',
              style: kTextStyleRegular.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addCertification,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Certification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: kTextStyleSmall.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._certifications.asMap().entries.map((entry) {
          final index = entry.key;
          return _buildCertificationCard(index);
        }),
      ],
    );
  }

  Widget _buildCertificationCard(int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Certification ${index + 1}',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_certifications.length > 1)
                  IconButton(
                    onPressed: () => _removeCertification(index),
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _certifications[index].name,
                    onChanged: (value) =>
                        _updateCertification(index, name: value),
                    decoration: InputDecoration(
                      labelText: 'Certification Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _certifications[index].issuer,
                    onChanged: (value) =>
                        _updateCertification(index, issuer: value),
                    decoration: InputDecoration(
                      labelText: 'Issuing Organization',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimestampDateField(
                    label: 'Issue Date',
                    value: _certifications[index].dateIssued,
                    onTap: () => _selectCertificationDate(index, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimestampDateField(
                    label: 'Expiry Date (Optional)',
                    value: _certifications[index].dateExpiry,
                    onTap: () => _selectCertificationDate(index, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Image upload section - RECOMMENDED
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Certification Document',
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(Required)',
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_certificationImages[index] != null)
                  GestureDetector(
                    onTap: () => _previewImage(_certificationImages[index]!, 'Certification ${index + 1}'),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.success, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _certificationImages[index]!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: () => _removeCertificationImage(index),
                              icon: Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(4),
                                minimumSize: Size(24, 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _certificationImages[index] == null 
                          ? AppColors.primary.withOpacity(0.5) 
                          : AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 32,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload Certification Document',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Recommended for faster verification',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickCertificationImage(index),
                          icon: Icon(Icons.upload_file, size: 16),
                          label: Text('Choose File'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            side: BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add licenses section builder
  Widget _buildLicensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Licenses',
              style: kTextStyleRegular.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addLicense,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add License'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: kTextStyleSmall.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._licenses.asMap().entries.map((entry) {
          final index = entry.key;
          return _buildLicenseCard(index);
        }),
      ],
    );
  }

  Widget _buildLicenseCard(int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'License ${index + 1}',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_licenses.length > 1)
                  IconButton(
                    onPressed: () => _removeLicense(index),
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _licenses[index].licenseId,
              onChanged: (value) =>
                  _updateLicense(index, licenseId: value),
              decoration: InputDecoration(
                labelText: 'License ID *',
                border: OutlineInputBorder(),
                hintText: 'e.g. VET-2024-001',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'License ID is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimestampDateField(
                    label: 'Issue Date',
                    value: _licenses[index].issueDate,
                    onTap: () => _selectLicenseDate(index, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimestampDateField(
                    label: 'Expiry Date',
                    value: _licenses[index].expiryDate,
                    onTap: () => _selectLicenseDate(index, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Image upload section - RECOMMENDED
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'License Document',
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(Reqiuired)',
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_licenseImages[index] != null)
                  GestureDetector(
                    onTap: () => _previewImage(_licenseImages[index]!, 'License ${index + 1}'),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.success, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _licenseImages[index]!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: () => _removeLicenseImage(index),
                              icon: Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(4),
                                minimumSize: Size(24, 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _licenseImages[index] == null 
                          ? AppColors.primary.withOpacity(0.5) 
                          : AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 32,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload License Document',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Recommended for faster verification',
                          style: kTextStyleSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickLicenseImage(index),
                          icon: Icon(Icons.upload_file, size: 16),
                          label: Text('Choose File'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            side: BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: kTextStyleRegular.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTimestampDateField({
    required String label,
    required Timestamp? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.toDate().day}/${value.toDate().month}/${value.toDate().year}'
                        : 'Select date',
                    style: kTextStyleRegular.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentStep > 0
                            ? _previousStep
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.textSecondary,
                      ),
                      Expanded(
                        child: Text(
                          'Create Admin Account',
                          style: kTextStyleTitle.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Step Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 40),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: kTextStyleSmall.copyWith(
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SingleChildScrollView(child: _buildAccountInfoStep()),
                        SingleChildScrollView(child: _buildClinicInfoStep()),
                        SingleChildScrollView(child: _buildClinicDetailsStep()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: kTextStyleRegular.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Create Account' : 'Next',
                                  style: kTextStyleRegular.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in here',
                          style: kTextStyleSmall.copyWith(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.go('/web_login');
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
