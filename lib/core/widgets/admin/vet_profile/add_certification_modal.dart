import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../services/documents/document_management_service.dart';
import '../../../services/clinic/clinic_service.dart';

class AddCertificationModal extends StatefulWidget {
  final VoidCallback onCertificationAdded;

  const AddCertificationModal({
    super.key,
    required this.onCertificationAdded,
  });

  @override
  State<AddCertificationModal> createState() => _AddCertificationModalState();
}

class _AddCertificationModalState extends State<AddCertificationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isLoading = false;
  String? _dateValidationError;
  String? _errorMessage;
  
  // File upload
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _hasSelectedFile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _hasSelectedFile = true;
          _errorMessage = null; // Clear any previous errors
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate expiry date is not earlier than issue date
      if (!isIssueDate && _issueDate != null && picked.isBefore(_issueDate!)) {
        setState(() {
          _dateValidationError = 'Expiry date cannot be earlier than issue date';
        });
        return;
      }

      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          // Clear expiry date if it's now invalid
          if (_expiryDate != null && _expiryDate!.isBefore(picked)) {
            _expiryDate = null;
          }
          _dateValidationError = null; // Clear error when issue date changes
        } else {
          _expiryDate = picked;
          _dateValidationError = null; // Clear error when valid expiry date is selected
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _addCertification() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate expiry date is not earlier than issue date
    if (_expiryDate != null && _issueDate != null && _expiryDate!.isBefore(_issueDate!)) {
      setState(() {
        _dateValidationError = 'Expiry date cannot be earlier than issue date';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      // Get current clinic ID
      final clinic = await ClinicService.getCurrentUserClinic();
      if (clinic == null) {
        throw Exception('No clinic found for current user');
      }

      final documentService = DocumentManagementService();
      
      await documentService.addCertificationWithImage(
        clinicId: clinic.id,
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        issueDate: _issueDate!,
        expiryDate: _expiryDate,
        imageBytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
        verificationNotes: null,
      );

      widget.onCertificationAdded();
      
      if (mounted) {
        Navigator.of(context).pop();
        // Show success message on parent screen after modal closes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certification added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error adding certification: $e';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.verified, color: AppColors.primary, size: 20),
                      ),
                    ),
                    SizedBox(width: kSpacingSmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Certification',
                          style: TextStyle(
                            fontSize: kFontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Upload a new professional certification',
                          style: TextStyle(
                            fontSize: kFontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
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
            SizedBox(height: kSpacingLarge),

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

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certificate Name
                  Text(
                    'Certificate Name *',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'e.g., Doctor of Veterinary Medicine',
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.all(kSpacingMedium),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the certificate name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: kSpacingMedium),

                  // Issuing Authority
                  Text(
                    'Issuing Authority *',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _issuerController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'e.g., Philippine Veterinary Medical Association',
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.all(kSpacingMedium),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the issuing authority';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: kSpacingMedium),

                  // Dates Row
                  Row(
                    children: [
                      // Issue Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issue Date *',
                              style: TextStyle(
                                fontSize: kFontSizeRegular,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: kSpacingSmall),
                            InkWell(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(kSpacingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _issueDate != null 
                                        ? _formatDate(_issueDate!)
                                        : 'Select date',
                                      style: TextStyle(
                                        color: _issueDate != null 
                                          ? AppColors.textPrimary 
                                          : AppColors.textSecondary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: kSpacingMedium),

                      // Expiry Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date (Optional)',
                              style: TextStyle(
                                fontSize: kFontSizeRegular,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: kSpacingSmall),
                            InkWell(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(kSpacingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _expiryDate != null 
                                        ? _formatDate(_expiryDate!)
                                        : 'No expiry',
                                      style: TextStyle(
                                        color: _expiryDate != null 
                                          ? AppColors.textPrimary 
                                          : AppColors.textSecondary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Date validation error message
                  if (_dateValidationError != null) ...[
                    SizedBox(height: kSpacingSmall),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          SizedBox(width: kSpacingSmall),
                          Expanded(
                            child: Text(
                              _dateValidationError!,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: kFontSizeSmall,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: kSpacingMedium),

                  // Document Upload
                  Text(
                    'Certificate Document *',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  InkWell(
                    onTap: _selectFile,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(kSpacingLarge),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasSelectedFile ? AppColors.success : AppColors.border,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                        color: _hasSelectedFile 
                          ? AppColors.success.withOpacity(0.05)
                          : AppColors.background,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _hasSelectedFile ? Icons.check_circle : Icons.cloud_upload,
                            size: 32,
                            color: _hasSelectedFile ? AppColors.success : AppColors.textSecondary,
                          ),
                          SizedBox(height: kSpacingSmall),
                          Text(
                            _hasSelectedFile 
                              ? _selectedFileName!
                              : 'Click to upload document',
                            style: TextStyle(
                              color: _hasSelectedFile ? AppColors.success : AppColors.textSecondary,
                              fontWeight: _hasSelectedFile ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          if (!_hasSelectedFile) ...[
                            SizedBox(height: 4),
                            Text(
                              'Supported: JPG, PNG, PDF (Max 5MB)',
                              style: TextStyle(
                                fontSize: kFontSizeSmall,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
                ),
              ),
            ),

            SizedBox(height: kSpacingMedium),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addCertification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingLarge,
                      vertical: kSpacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text('Add Certification'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}