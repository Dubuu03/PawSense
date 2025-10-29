import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../services/vet_profile/vet_profile_service.dart';
import '../../../services/cloudinary/cloudinary_service.dart';
import '../../../services/super_admin/predefined_specialization_service.dart';

class AddSpecializationModal extends StatefulWidget {
  final Future<void> Function() onSpecializationAdded;

  const AddSpecializationModal({
    super.key,
    required this.onSpecializationAdded,
  });

  @override
  State<AddSpecializationModal> createState() => _AddSpecializationModalState();
}

class _AddSpecializationModalState extends State<AddSpecializationModal> {
  final _formKey = GlobalKey<FormState>();
  final _customSpecializationController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String? _selectedSpecialization;
  String _selectedLevel = 'Expert';
  bool _hasCertification = true;
  bool _isLoading = false;
  bool _isCustom = false;
  String? _errorMessage;
  bool _isLoadingSpecializations = true;
  
  // Image upload fields
  Uint8List? _certificateImageBytes;
  String? _certificateImageName;
  bool _isUploadingImage = false;

  // Predefined specializations from database
  List<Map<String, dynamic>> _predefinedSpecializations = [];

  final List<String> _expertiseLevels = [
    'Basic',
    'Intermediate',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _loadPredefinedSpecializations();
  }

  Future<void> _loadPredefinedSpecializations() async {
    setState(() => _isLoadingSpecializations = true);
    try {
      // NOTE: The query used in PredefinedSpecializationService.getActiveSpecializations
      // may require a Firestore composite index depending on the `where`/`orderBy`
      // combination used on the server side. If you see a runtime error like:
      // [cloud_firestore/failed-precondition] The query requires an index.
      // create it via the Firebase console: 
      // https://console.firebase.google.com/v1/r/project/pawsense-134fc/firestore/indexes
      // or follow the URL printed in the exception to create the required index.
      final specs = await PredefinedSpecializationService.getActiveSpecializations();
      if (mounted) {
        setState(() {
          _predefinedSpecializations = specs;
          _isLoadingSpecializations = false;
        });
      }
    } catch (e) {
      print('Error loading predefined specializations: $e');
      if (mounted) {
        setState(() => _isLoadingSpecializations = false);
      }
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _certificateImageBytes = file.bytes;
          _certificateImageName = file.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  void _showCertificatePreview(BuildContext context) {
    if (_certificateImageBytes == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(kSpacingLarge),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kBorderRadius),
                    topRight: Radius.circular(kBorderRadius),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: kSpacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _certificateImageName ?? 'Certificate Preview',
                            style: TextStyle(
                              fontSize: kFontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Specialization Certificate',
                            style: TextStyle(
                              fontSize: kFontSizeRegular,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Image Preview Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(kSpacingLarge),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      child: Image.memory(
                        _certificateImageBytes!,
                        fit: BoxFit.contain,
                      ),
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

  @override
  void dispose() {
    _customSpecializationController.dispose();
    super.dispose();
  }

  Future<void> _addSpecialization() async {
    if (!_formKey.currentState!.validate()) return;

    final specialization = _isCustom 
        ? _customSpecializationController.text.trim()
        : _selectedSpecialization;

    if (specialization == null || specialization.isEmpty) {
      setState(() {
        _errorMessage = 'Please select or enter a specialization';
      });
      return;
    }

    // Check if certification is required but not provided
    if (_hasCertification && _certificateImageBytes == null) {
      setState(() {
        _errorMessage = 'Please upload a certification document';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? certificateUrl;

    try {
      // Upload certificate image if provided
      if (_hasCertification && _certificateImageBytes != null) {
        setState(() => _isUploadingImage = true);
        print('DEBUG Modal: Uploading certification image to Cloudinary...');
        
        certificateUrl = await _cloudinaryService.uploadImageFromBytes(
          _certificateImageBytes!,
          _certificateImageName ?? 'certification',
          folder: 'specialization_certificates',
        );
        
        print('DEBUG Modal: Certificate uploaded successfully: $certificateUrl');
        setState(() => _isUploadingImage = false);
      }

      print('DEBUG Modal: Adding specialization: $specialization');
      print('DEBUG Modal: Level: $_selectedLevel');
      print('DEBUG Modal: Has certification: $_hasCertification');
      print('DEBUG Modal: Certificate URL: $certificateUrl');
      
      // Save specialization with all details
      final success = await VetProfileService.addSpecializationWithCertificate(
        specialization,
        level: _selectedLevel,
        hasCertification: _hasCertification,
        certificateUrl: certificateUrl,
      );
      print('DEBUG Modal: Add result: $success');

      if (success && mounted) {
        print('DEBUG Modal: Calling onSpecializationAdded callback...');
        await widget.onSpecializationAdded();
        print('DEBUG Modal: Callback completed, closing modal...');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Specialization already exists or failed to add';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG Modal: Error adding specialization: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error adding specialization: $e';
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate conditional max height based on certification state
    double maxHeightRatio;
    if (!_hasCertification) {
      // No certification checked - smaller modal
      maxHeightRatio = 0.7;
    } else if (_certificateImageBytes == null) {
      // Certification checked but no image uploaded - medium modal
      maxHeightRatio = 0.85;
    } else {
      // Image uploaded - taller modal
      maxHeightRatio = 0.95;
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          // Conditional max height based on certification state
          maxHeight: MediaQuery.of(context).size.height * maxHeightRatio,
        ),
        padding: const EdgeInsets.all(kSpacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Specialization',
                    style: TextStyle(
                      fontSize: kFontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpacingMedium),

              // Wrap the main body (error banner -> certificate upload) in a scrollable area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(kSpacingMedium),
                          margin: EdgeInsets.only(bottom: kSpacingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              SizedBox(width: kSpacingSmall),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: kFontSizeSmall,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 18, color: AppColors.error),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => setState(() => _errorMessage = null),
                              ),
                            ],
                          ),
                        ),

                      // Toggle between predefined and custom
                      Container(
                        padding: const EdgeInsets.all(kSpacingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(kBorderRadius),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(
                                  'Select from list',
                                  style: TextStyle(
                                    fontSize: kFontSizeRegular,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                value: false,
                                groupValue: _isCustom,
                                onChanged: _isLoading ? null : (value) {
                                  setState(() {
                                    _isCustom = false;
                                    _selectedSpecialization = null;
                                    _customSpecializationController.clear();
                                  });
                                },
                                activeColor: AppColors.primary,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(
                                  'Custom',
                                  style: TextStyle(
                                    fontSize: kFontSizeRegular,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                value: true,
                                groupValue: _isCustom,
                                onChanged: _isLoading ? null : (value) {
                                  setState(() {
                                    _isCustom = true;
                                    _selectedSpecialization = null;
                                  });
                                },
                                activeColor: AppColors.primary,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kSpacingLarge),

                      // Specialization input section
                      if (!_isCustom) ...[
                        Text(
                          'Select Specialization',
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: kSpacingSmall),
                        _isLoadingSpecializations
                            ? Container(
                                padding: const EdgeInsets.all(kSpacingMedium),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  border: Border.all(
                                    color: _selectedSpecialization == null ? AppColors.border : AppColors.primary,
                                    width: _selectedSpecialization == null ? 1 : 2,
                                  ),
                                  borderRadius: BorderRadius.circular(kBorderRadius),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSpecialization,
                                    hint: Text(
                                      _predefinedSpecializations.isEmpty 
                                          ? 'No specializations available'
                                          : 'Choose a specialization',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: kFontSizeRegular,
                                      ),
                                    ),
                                    isExpanded: true,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: kFontSizeRegular,
                                    ),
                                    items: _predefinedSpecializations.map((spec) {
                                      final name = spec['name'] as String;
                                      return DropdownMenuItem<String>(
                                        value: name,
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: kFontSizeRegular,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _isLoading ? null : (String? newValue) {
                                      setState(() {
                                        _selectedSpecialization = newValue;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ] else ...[
                        Text(
                          'Custom Specialization',
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: kSpacingSmall),
                        TextFormField(
                          controller: _customSpecializationController,
                          enabled: !_isLoading,
                          maxLength: 50,
                          decoration: InputDecoration(
                            hintText: 'Enter your specialization',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: kFontSizeRegular,
                            ),
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                              borderSide: BorderSide(color: AppColors.error, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: kSpacingMedium,
                              vertical: kSpacingMedium,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: kFontSizeRegular,
                            color: AppColors.textPrimary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a specialization';
                            }
                            if (value.trim().length < 2) {
                              return 'Specialization must be at least 2 characters';
                            }
                            if (value.trim().length > 50) {
                              return 'Specialization must be less than 50 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: kSpacingLarge),

                      // Expertise Level
                      Text(
                        'Expertise Level',
                        style: TextStyle(
                          fontSize: kFontSizeRegular,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: kSpacingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: kFontSizeRegular,
                            ),
                            items: _expertiseLevels.map((String level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(
                                  level,
                                  style: TextStyle(
                                    fontSize: kFontSizeRegular,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : (String? newValue) {
                              setState(() {
                                _selectedLevel = newValue ?? 'Expert';
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: kSpacingLarge),

                      // Certification toggle
                      Container(
                        padding: const EdgeInsets.all(kSpacingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(kBorderRadius),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'I have certification for this specialization',
                            style: TextStyle(
                              fontSize: kFontSizeRegular,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          value: _hasCertification,
                          onChanged: _isLoading ? null : (bool? value) {
                            setState(() {
                              _hasCertification = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                      const SizedBox(height: kSpacingLarge),

                      // Certificate Upload Section (shown when hasCertification is true)
                      if (_hasCertification) ...[
                        Container(
                          padding: EdgeInsets.all(kSpacingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(kBorderRadius),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: kSpacingSmall),
                                  Text(
                                    'Upload Certification Document',
                                    style: TextStyle(
                                      fontSize: kFontSizeRegular,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: kSpacingSmall),
                              Text(
                                'Please upload an image of your certification (JPG, PNG, JPEG)',
                                style: TextStyle(
                                  fontSize: kFontSizeSmall,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: kSpacingMedium),
                              
                              // Upload Button or Preview
                              if (_certificateImageBytes == null)
                                OutlinedButton.icon(
                                  onPressed: _isLoading || _isUploadingImage ? null : _pickCertificateImage,
                                  icon: Icon(Icons.add_photo_alternate),
                                  label: Text('Select Certificate Image'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: kSpacingLarge,
                                      vertical: kSpacingMedium,
                                    ),
                                    side: BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.all(kSpacingSmall),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Tooltip(
                                        message: 'Click to preview certificate',
                                        child: InkWell(
                                          onTap: () => _showCertificatePreview(context),
                                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                              border: Border.all(
                                                color: AppColors.primary.withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall - 2),
                                                  child: Image.memory(
                                                    _certificateImageBytes!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                ),
                                                // Hover overlay with eye icon
                                                Positioned.fill(
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () => _showCertificatePreview(context),
                                                      borderRadius: BorderRadius.circular(kBorderRadiusSmall - 2),
                                                      hoverColor: AppColors.primary.withOpacity(0.1),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(kBorderRadiusSmall - 2),
                                                        ),
                                                        child: Center(
                                                          child: Container(
                                                            padding: EdgeInsets.all(4),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primary.withOpacity(0.8),
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.visibility,
                                                              color: AppColors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: kSpacingMedium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _certificateImageName ?? 'Certificate',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: kFontSizeSmall,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Ready to upload',
                                              style: TextStyle(
                                                fontSize: kFontSizeSmall,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _isLoading || _isUploadingImage
                                            ? null
                                            : () {
                                                setState(() {
                                                  _certificateImageBytes = null;
                                                  _certificateImageName = null;
                                                });
                                              },
                                        icon: Icon(Icons.close, size: 18),
                                        color: AppColors.error,
                                        tooltip: 'Remove image',
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: kSpacingLarge),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        backgroundColor: AppColors.white,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: kFontSizeRegular,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addSpecialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Add Specialization',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: kFontSizeRegular,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
