import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../../core/models/clinic/clinic_model.dart';
import '../../../core/models/clinic/clinic_details_model.dart';
import '../../../core/models/clinic/clinic_service_model.dart';
import '../../../core/models/clinic/clinic_certification_model.dart';
import '../../../core/models/clinic/clinic_license_model.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/text_utils.dart';

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
    GlobalKey<FormState>(),
  ];

  final _authService = AuthService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _isEmailVerified = false;
  bool _isSendingVerification = false;
  bool _isCheckingVerification = false;
  Timer? _verificationTimer;
  
  // Store the verified email to compare when user changes it
  String? _verifiedEmail;

  // Step 1: Account Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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

  // Resend email cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Field errors tracking for real-time validation
  final Map<String, String?> _fieldErrors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'contactNumber': null,
    'password': null,
    'confirmPassword': null,
    'clinicName': null,
    'clinicAddress': null,
    'clinicPhone': null,
    'clinicEmail': null,
    'terms': null,
  };

  /// Show error message using SnackBar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
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
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Get password requirements status
  Map<String, bool> _getPasswordRequirements(String password) {
    return {
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'minLength': password.length >= 8,
    };
  }

  /// Validate individual field
  String? _validateField(String keyName, String value) {
    switch (keyName) {
      case 'firstName':
        return nameValidator(value.trim(), 'First name');
      case 'lastName':
        return nameValidator(value.trim(), 'Last name');
      case 'email':
        return emailValidator(value.trim());
      case 'contactNumber':
        return phoneValidator(value.trim());
      case 'password':
        // Check password requirements
        if (value.trim().isEmpty) return 'Enter password';
        final requirements = _getPasswordRequirements(value.trim());
        final allMet = requirements.values.every((met) => met);
        if (!allMet) return 'Password does not meet requirements';
        // Also validate confirm password when password changes
        if (_confirmPasswordController.text.isNotEmpty) {
          _fieldErrors['confirmPassword'] = confirmPasswordValidator(
            _confirmPasswordController.text.trim(), 
            value.trim()
          );
        }
        return null;
      case 'confirmPassword':
        return confirmPasswordValidator(value.trim(), _passwordController.text.trim());
      case 'clinicName':
        if (value.trim().isEmpty) return 'Enter clinic name';
        if (value.trim().length < 3) return 'Clinic name must be at least 3 characters';
        return null;
      case 'clinicAddress':
        return addressValidator(value.trim());
      case 'clinicPhone':
        return phoneValidator(value.trim());
      case 'clinicEmail':
        return emailValidator(value.trim());
      default:
        return null;
    }
  }

  /// Build password requirements widget
  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final requirements = _getPasswordRequirements(password);
    
    if (password.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementItem('A lowercase letter', requirements['lowercase']!),
          const SizedBox(height: 4),
          _buildRequirementItem('A capital (uppercase) letter', requirements['uppercase']!),
          const SizedBox(height: 4),
          _buildRequirementItem('A number', requirements['number']!),
          const SizedBox(height: 4),
          _buildRequirementItem('Minimum 8 characters', requirements['minLength']!),
        ],
      ),
    );
  }

  /// Build individual requirement item
  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check : Icons.close,
          color: isMet ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: kTextStyleSmall.copyWith(
            color: isMet ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Check verification status once
  Future<void> _checkVerificationStatus() async {
    if (!mounted || _isEmailVerified) return;

    try {
      final isVerified = await _authService.checkEmailVerificationForAccount(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted && isVerified) {
        setState(() {
          _isEmailVerified = true;
          _verifiedEmail = _emailController.text.trim(); // Store the verified email
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email verified successfully! You can now proceed.',
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
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Silently fail for quota errors - don't show error for automatic checks
      if (e.toString().contains('quota-exceeded')) {
        print('Quota exceeded - will retry on next interval');
        // Increase the check interval if we hit quota
        _stopVerificationTimer();
        _verificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
          if (!mounted || _isEmailVerified || _currentStep != 1) {
            timer.cancel();
            return;
          }
          await _checkVerificationStatus();
        });
      } else {
        print('Verification check failed: $e');
      }
    }
  }

  /// Start checking for email verification automatically
  void _startVerificationTimer() {
    _stopVerificationTimer(); // Stop any existing timer
    
    // Do an immediate check first
    _checkVerificationStatus();
    
    // Increase interval to 5 seconds to reduce API calls
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isEmailVerified || _currentStep != 1) {
        timer.cancel();
        return;
      }

      // Use the same method for consistency
      await _checkVerificationStatus();
    });
  }

  /// Stop the verification timer and sign out verification account
  void _stopVerificationTimer() {
    _verificationTimer?.cancel();
    _verificationTimer = null;
    
    // Sign out the temporary verification account when timer stops
    _authService.signOutVerificationAccount();
  }

  @override
  void initState() {
    super.initState();
    _initializeDefaultEntries();
    
    // Listen for email changes to reset verification status
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final currentEmail = _emailController.text.trim();
    
    // If email changed from verified email, reset verification status
    if (_verifiedEmail != null && _verifiedEmail != currentEmail && _isEmailVerified) {
      setState(() {
        _isEmailVerified = false;
        _verifiedEmail = null;
      });
      _stopVerificationTimer();
    }
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
  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    
    // Sign out verification account when leaving the page
    _authService.signOutVerificationAccount();
    
    super.dispose();
  }

  /// Start 30-second cooldown for resend button
  void _startResendCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
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
    // Get the index of the certification to check its image
    final index = _certifications.indexOf(cert);
    // Certification name, issuer, expiry date, and image should be provided
    return cert.name.trim().isNotEmpty && 
           cert.issuer.trim().isNotEmpty &&
           cert.dateExpiry != null &&
           _certificationImages[index] != null; // Image is required
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
    // Validate form and show errors
    final formState = _formKeys[3].currentState;
    if (formState == null || !formState.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }
    
    if (!_agreedToTerms) {
      _showErrorSnackBar('Please agree to the terms and conditions');
      return;
    }

    // Validate that at least one certification and one license are provided
    final validCertifications = _certifications.where((cert) => _isCertificationValid(cert)).toList();
    final validLicenses = _licenses.where((license) => _isLicenseValid(license)).toList();

    // Provide more specific error messages for missing data
    if (_services.isEmpty) {
      _showErrorSnackBar('Please add at least one service');
      return;
    }

    if (_certifications.isEmpty) {
      _showErrorSnackBar('Please add at least one certification');
      return;
    }

    if (_licenses.isEmpty) {
      _showErrorSnackBar('Please add at least one license');
      return;
    }

    if (validCertifications.isEmpty) {
      _showErrorSnackBar('Please complete all certification details and upload certification documents');
      return;
    }

    if (validLicenses.isEmpty) {
      _showErrorSnackBar('Please complete all license details and upload license documents');
      return;
    }

    // Also validate services
    final validServices = _services.where((service) => _isServiceValid(service)).toList();
    
    if (validServices.isEmpty) {
      _showErrorSnackBar('Please complete all service details');
      return;
    }

    setState(() {
      _isLoading = true;
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

      // Format names properly using TextUtils
      final formattedFirstName = TextUtils.capitalizeWords(_firstNameController.text.trim());
      final formattedLastName = TextUtils.capitalizeWords(_lastNameController.text.trim());
      final fullName = TextUtils.formatFullName(
        _firstNameController.text.trim(), 
        _lastNameController.text.trim()
      );
      
      // Complete registration (account was already created during email verification)
      final result = await _authService.completeClinicAdminRegistration(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
        username: fullName,
        firstName: formattedFirstName,
        lastName: formattedLastName,
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
        _showErrorSnackBar(result.error ?? 'Signup failed. Please try again.');
      }
    } catch (e) {
      print('Signup error: $e'); // Add debug print
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
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
          duration: '',
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
          dateExpiry: Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))), // Default 1 year expiry
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
    // Get the index of the license to check its image
    final index = _licenses.indexOf(license);
    // License ID and image should be provided
    return license.licenseId.trim().isNotEmpty &&
           _licenseImages[index] != null; // Image is now required
  }

  void _nextStep() async {
    if (_currentStep < 3) {
      // Skip validation for step 1 (email verification) as it has no form fields
      if (_currentStep != 1 && _formKeys[_currentStep].currentState?.validate() == false) {
        return;
      }
        
      // Check email availability and send verification code for step 0
      if (_currentStep == 0) {
        final currentEmail = _emailController.text.trim();
        
        // Check if email has changed from the previously verified email
        if (_isEmailVerified && _verifiedEmail != null && _verifiedEmail != currentEmail) {
          // Email changed, reset verification status
          setState(() {
            _isEmailVerified = false;
            _verifiedEmail = null;
          });
        }
        
        // If email is already verified and hasn't changed, don't recheck availability or resend
        if (_isEmailVerified && _verifiedEmail == currentEmail) {
          // Do nothing, just proceed to verification step
        } else {
          final emailAvailable = await _checkEmailAvailability();
          if (!emailAvailable) {
            return; // Don't proceed if email validation failed
          }
          
          // Send verification email via Firebase
          final emailSent = await _sendVerificationEmail();
          if (!emailSent) {
            return; // Don't proceed if sending verification failed
          }
        }
      } 
      // Verify email for step 1
      else if (_currentStep == 1) {
        // For step 1, only proceed if email is already verified
        if (!_isEmailVerified) {
          _showErrorSnackBar('Please wait for email verification to complete, or check your inbox and click the verification link.');
          return;
        }
        
        // Stop the timer when moving away from verification step
        _stopVerificationTimer();
      }
      // Check clinic email availability for step 2
      else if (_currentStep == 2) {
        final clinicEmailAvailable = await _checkClinicEmailAvailability();
        if (!clinicEmailAvailable) {
          return; // Don't proceed if email validation failed
        }
      }
      
      final previousStep = _currentStep;
      setState(() {
        _currentStep++;
      });
      
      // Start verification timer when moving to step 1 (verification step)
      if (previousStep == 0 && _currentStep == 1) {
        _startVerificationTimer();
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignup();
    }
  }

  Future<bool> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty) return false;

    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final emailStatus = await _authService.checkEmailStatus(email, password);
      
      if (emailStatus['exists'] == true) {
        if (emailStatus['verified'] == true) {
          // Email exists and is already verified - do not allow proceeding
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This email is already registered and verified. Please sign in instead.'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return false; // Don't allow proceeding
        } else {
          // Email exists but is not verified - allow proceeding
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email is already registered but not verified. Proceeding to verification step.'),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return true; // Allow proceeding to verification step
        }
      }
      return true; // Email doesn't exist, can proceed normally
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setState(() {
        _isCheckingEmail = false;
      });
    }
  }

  Future<bool> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    setState(() {
      _isSendingVerification = true;
    });

    try {
      // Create display name from first and last name
      String? displayName;
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        displayName = TextUtils.formatFullName(firstName, lastName);
      }
      
      // Create a temporary Firebase account to send verification email or handle existing account
      final result = await _authService.createTempAccountForVerification(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (result['success']) {
        if (mounted) {
          final message = result['message'] ?? 'Verification email sent to $email. Please check your inbox.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return true;
      } else {
        _showErrorSnackBar(result['error'] ?? 'Failed to send verification email');
        return false;
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send verification email: ${e.toString()}');
      return false;
    } finally {
      setState(() {
        _isSendingVerification = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSendingVerification = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      // Create display name from first and last name
      String? displayName;
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        displayName = TextUtils.formatFullName(firstName, lastName);
      }
      
      await _authService.resendVerificationEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // Start 30-second cooldown
      _startResendCooldown();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to resend verification email: ${e.toString()}');
    } finally {
      setState(() {
        _isSendingVerification = false;
      });
    }
  }

  Future<bool> _checkClinicEmailAvailability() async {
    final email = _clinicEmailController.text.trim();
    if (email.isEmpty) return false;

    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final emailExists = await _authService.clinicEmailExists(email);
      
      if (emailExists) {
        _showErrorSnackBar('A clinic already exists with this email address.');
        return false;
      } else {
        return true;
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      setState(() {
        _isCheckingEmail = false;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Stop verification timer if navigating away from verification step
      if (_currentStep == 1) {
        _stopVerificationTimer();
      }
      
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem('Account', 0, Icons.person_outline),
          _buildStepConnector(0),
          _buildStepItem('Verify', 1, Icons.mark_email_read_outlined),
          _buildStepConnector(1),
          _buildStepItem('Clinic', 2, Icons.local_hospital_outlined),
          _buildStepConnector(2),
          _buildStepItem('Details', 3, Icons.description_outlined),
        ],
      ),
    );
  }

  Widget _buildStepItem(String label, int index, IconData icon) {
    final isActive = index == _currentStep;
    final isCompleted = index < _currentStep;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? const Color(0xFF10B981) // Green for completed
                : isActive 
                    ? const Color(0xFF8B5CF6) // Purple for active
                    : const Color(0xFFE5E7EB), // Light gray for pending
            boxShadow: [
              BoxShadow(
                color: (isCompleted || isActive) 
                    ? (isCompleted ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withOpacity(0.2)
                    : Colors.transparent,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: (isCompleted || isActive) ? Colors.white : const Color(0xFF6B7280),
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive 
                ? const Color(0xFF8B5CF6) // Purple for active
                : isCompleted 
                    ? const Color(0xFF10B981) // Green for completed
                    : const Color(0xFF6B7280), // Gray for pending
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int index) {
    final isCompleted = index < _currentStep;
    
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24), // Align with circles
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFF10B981) // Green for completed connections
            : const Color(0xFFE5E7EB), // Light gray for pending
        borderRadius: BorderRadius.circular(1),
      ),
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
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
                  fieldKey: 'firstName',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  validator: (value) => null, // Real-time validation handles this
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  fieldKey: 'lastName',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  validator: (value) => null, // Real-time validation handles this
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email address',
            fieldKey: 'email',
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^\s')), // No leading spaces
              FilteringTextInputFormatter.deny(RegExp(r'\s$')), // No trailing spaces
            ],
            validator: (value) => null, // Real-time validation handles this
          ),
          const SizedBox(height: 20),

          // Contact Number
          _buildTextField(
            controller: _contactNumberController,
            label: 'Contact Number',
            hint: 'Enter your contact number',
            fieldKey: 'contactNumber',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) => null, // Real-time validation handles this
          ),
          const SizedBox(height: 20),

  

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            fieldKey: 'password',
            obscureText: _obscurePassword,
            inputFormatters: [
              LengthLimitingTextInputFormatter(128),
            ],
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
            validator: (value) => null, // Real-time validation handles this
          ),
          
          // Password requirements indicator
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordRequirements(),
          ],
          
          const SizedBox(height: 20),

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            fieldKey: 'confirmPassword',
            obscureText: _obscureConfirmPassword,
            inputFormatters: [
              LengthLimitingTextInputFormatter(128),
            ],
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
            validator: (value) => null, // Real-time validation handles this
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Center icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isEmailVerified 
                    ? AppColors.success.withOpacity(0.1) 
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isEmailVerified ? Icons.mark_email_read : Icons.email_outlined,
                size: 40,
                color: _isEmailVerified ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Verify Your Email',
            style: kTextStyleTitle.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isEmailVerified
                ? 'Email verified successfully!'
                : 'We\'ve sent a verification code to ${_emailController.text.trim()}',
            style: kTextStyleRegular.copyWith(
              color: _isEmailVerified ? AppColors.success : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (!_isEmailVerified) ...[
            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Check your email inbox for the verification link\n'
                    '2. Click the link in the email to verify your address\n'
                    '3. Return to this page and click "Next" to continue',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _isCheckingVerification ? null : () async {
                    setState(() {
                      _isCheckingVerification = true;
                    });
                    await _checkVerificationStatus();
                    setState(() {
                      _isCheckingVerification = false;
                    });
                  },
                  icon: _isCheckingVerification 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Icon(Icons.refresh, size: 18),
                  label: Text(
                    _isCheckingVerification ? 'Checking...' : 'Check Now',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: (_isSendingVerification || _resendCooldown > 0) ? null : _resendVerificationEmail,
                  icon: _isSendingVerification 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    _isSendingVerification 
                        ? 'Sending...' 
                        : _resendCooldown > 0 
                            ? 'Resend in ${_resendCooldown}s' 
                            : 'Resend Email',
                    style: kTextStyleRegular.copyWith(
                      color: (_isSendingVerification || _resendCooldown > 0) 
                          ? AppColors.textTertiary 
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Success message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your email has been verified. Click Next to continue.',
                      style: kTextStyleRegular.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicInfoStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Information',
            style: kTextStyleTitle.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
            fieldKey: 'clinicName',
            inputFormatters: [
              LengthLimitingTextInputFormatter(100),
            ],
            validator: (value) => null, // Real-time validation handles this
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(1000),
            ],
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
            fieldKey: 'clinicAddress',
            maxLines: 3,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\-'.,#/]")),
              LengthLimitingTextInputFormatter(200),
            ],
            validator: (value) => null, // Real-time validation handles this
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
                  fieldKey: 'clinicPhone',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) => null, // Real-time validation handles this
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _clinicEmailController,
                  label: 'Clinic Email',
                  hint: 'Enter clinic email',
                  fieldKey: 'clinicEmail',
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^\s')), // No leading spaces
                    FilteringTextInputFormatter.deny(RegExp(r'\s$')), // No trailing spaces
                  ],
                  validator: (value) => null, // Real-time validation handles this
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
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services, Certifications & Licenses',
            style: kTextStyleTitle.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
                    initialValue: _services[index].serviceName,
                    onChanged: (value) => _updateService(index, serviceName: value),
                    decoration: const InputDecoration(
                      labelText: 'Service Name *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter service name',
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true ? 'Service name is required' : null,
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
                    validator: (value) => value == null ? 'Category is required' : null,
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
              maxLength: 300,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (value!.length > 300) return 'Description cannot exceed 300 characters';
                return null;
              },
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
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Enter a valid price';
                      if (double.parse(value) <= 0) return 'Price must be greater than 0';
                      return null;
                    },
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
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (!value!.toLowerCase().contains('min') && !value.toLowerCase().contains('hour')) {
                        return 'Specify min/hour';
                      }
                      return null;
                    },
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
                    label: 'Expiry Date *',
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
    String? fieldKey, // Add field key for real-time validation
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 15, // Increased from 13
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8), // Increased spacing
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04), // Reduced shadow intensity
                blurRadius: 4, // Reduced blur
                offset: const Offset(0, 2), // Reduced offset
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02), // Reduced secondary shadow
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: fieldKey != null ? (value) {
              // Real-time validation
              setState(() {
                _fieldErrors[fieldKey] = _validateField(fieldKey, value);
              });
            } : null,
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16, // Increased from 14
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: kTextStyleRegular.copyWith(
                color: AppColors.textTertiary,
                fontSize: 15, // Increased from 13
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14, // Increased padding for better visual balance
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: fieldKey != null && _fieldErrors[fieldKey] != null
                      ? AppColors.error
                      : AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: fieldKey != null && _fieldErrors[fieldKey] != null
                      ? AppColors.error
                      : AppColors.border.withOpacity(0.3),
                  width: fieldKey != null && _fieldErrors[fieldKey] != null ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: fieldKey != null && _fieldErrors[fieldKey] != null
                      ? AppColors.error
                      : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              errorText: fieldKey != null ? _fieldErrors[fieldKey] : null,
              errorStyle: kTextStyleSmall.copyWith(
                color: AppColors.error,
                fontSize: 12,
                height: 1.2,
              ),
              errorMaxLines: 2,
            ),
            validator: validator,
          ),
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
            fontSize: 15, // Increased from 13
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8), // Increased spacing
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04), // Reduced shadow intensity
                blurRadius: 4, // Reduced blur
                offset: const Offset(0, 2), // Reduced offset
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02), // Reduced secondary shadow
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Increased padding
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(10),
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
                        fontSize: 16, // Increased from 14
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ],
              ),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(
                maxWidth: 650,
                minHeight: 900, // Set minimum height to match SizedBox
              ),
              child: SizedBox(
                height: 900,
                  child: Card(
                    elevation: 20,
                    shadowColor: AppColors.primary.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.white,
                            AppColors.white.withOpacity(0.98),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header - Minimized
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                
                                Expanded(
                                  child: Text(
                                    'Create Admin Account',
                                    style: kTextStyleTitle.copyWith(
                                      fontSize: 20,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                
                              ],
                            ),
                            const SizedBox(height: 8),
                  
                            // Form Content Container - Bigger for better field visibility
                            Container(
                              height: 640, // Fixed height for all devices
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    // Step Indicator inside the form container
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.7),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.border.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(child: _buildStepIndicator()),
                                    ),
                                    // Form content area
                                    Expanded(
                                      child: PageView(
                                        controller: _pageController,
                                        physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // Increased padding for more space
                                      child: SingleChildScrollView(
                                        child: _buildAccountInfoStep(),
                                      ),
                                    ),
                                    Padding(
                                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                      child: SingleChildScrollView(
                                        child: _buildEmailVerificationStep(),
                                      ),
                                    ),
                                    Padding(
                                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                      child: SingleChildScrollView(
                                        child: _buildClinicInfoStep(),
                                      ),
                                    ),
                                    Padding(
                                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                      child: SingleChildScrollView(
                                        child: _buildClinicDetailsStep(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  
                            const SizedBox(height: 8),
                  
                            // Navigation Buttons - More Compact
                            Row(
                              children: [
                                if (_currentStep > 0)
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed: (_isLoading || _isCheckingEmail) ? null : _previousStep,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: AppColors.primary, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          backgroundColor: AppColors.white,
                                        ),
                                        child: Text(
                                          'Previous',
                                          style: kTextStyleRegular.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_currentStep > 0) const SizedBox(width: 12),
                                Expanded(
                                  flex: _currentStep == 0 ? 1 : 1,
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.8),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (_isLoading || _isCheckingEmail || _isCheckingVerification || (_currentStep == 1 && !_isEmailVerified) || (_currentStep == 3 && !_agreedToTerms)) ? null : _nextStep,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: AppColors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: (_isLoading || _isCheckingEmail || _isCheckingVerification)
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
                                              _currentStep == 3 ? 'Create Account' : 'Next',
                                              style: kTextStyleRegular.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Footer - More Compact
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: kTextStyleSmall.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: "Already have an account? "),
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
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
        ),
      ),

    );
  }
}