import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/validators.dart';

class AddUserModal extends StatefulWidget {
  final void Function(UserModel user)? onCreateUser;

  const AddUserModal({super.key, this.onCreateUser});

  @override
  State<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _isLoading = false;

  // Step 0: Basic Information
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'user';

  // Step 1: Additional Details
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _dateOfBirth;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      // Validate basic information
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step = 1);
      }
    } else if (_step == 1) {
      // Create user
      _createUser();
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _createUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create UserModel instance
      final newUser = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        createdAt: DateTime.now(),
        contactNumber: _contactNumberController.text.trim().isNotEmpty 
            ? _contactNumberController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        dateOfBirth: _dateOfBirth,
        isActive: true,
        agreedToTerms: true,
        updatedAt: DateTime.now(),
      );

      // Call the callback function
      widget.onCreateUser?.call(newUser);
      
      // Close the modal
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Widget _buildStepIndicator(double width) {
    final labels = ['Basic Information', 'Additional Details'];
    
    return Center(
      child: Container(
        width: width * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 72,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(3, (slot) {
                        if (slot % 2 == 0) {
                          // Circle indicators (slots 0, 2)
                          final stepIndex = slot ~/ 2;
                          final isCompleted = stepIndex < _step;
                          final isActive = stepIndex == _step;
                          final bgColor = isCompleted || isActive ? AppColors.primary : Colors.grey.shade200;
                          final textColor = isCompleted || isActive ? AppColors.white : Colors.grey.shade700;
                          
                          return Expanded(
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bgColor,
                                  border: isCompleted || isActive ? null : Border.all(color: Colors.grey.shade300),
                                ),
                                child: Center(
                                  child: isCompleted 
                                      ? const Icon(Icons.check, color: AppColors.white, size: kIconSizeMedium)
                                      : Text(
                                          '${stepIndex + 1}',
                                          style: kTextStyleSmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Line connectors (slot 1)
                          final leftStep = (slot - 1) ~/ 2;
                          final isActive = _step > leftStep;
                          
                          return Expanded(
                            child: Center(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: kSpacingSmall),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  Row(
                    children: List.generate(
                      labels.length,
                      (i) => Expanded(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: kTextStyleSmall.copyWith(
                            color: i <= _step ? AppColors.primary : Colors.grey[600],
                            fontWeight: i <= _step ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: kTextStyleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: kSpacingMedium),

        // First Name and Last Name
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First Name *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _firstNameController,
                    validator: (value) => requiredValidator(value, 'first name'),
                    decoration: InputDecoration(
                      hintText: 'Enter first name',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Name *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _lastNameController,
                    validator: (value) => requiredValidator(value, 'last name'),
                    decoration: InputDecoration(
                      hintText: 'Enter last name',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: kSpacingMedium),

        // Username
        Text(
          'Username *',
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: kSpacingSmall),
        TextFormField(
          controller: _usernameController,
          validator: (value) => requiredValidator(value, 'username'),
          decoration: InputDecoration(
            hintText: 'Enter username',
            hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: kSpacingMedium),

        // Email and Role
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _emailController,
                    validator: emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter email address',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('User'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'super_admin',
                        child: Text('Super Admin'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: kTextStyleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: kSpacingMedium),

        // Contact Number and Date of Birth
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Number',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter contact number',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  InkWell(
                    onTap: _selectDateOfBirth,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateOfBirth != null
                                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                  : 'Select date of birth',
                              style: kTextStyleRegular.copyWith(
                                color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.textSecondary,
                            size: kIconSizeMedium,
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

        const SizedBox(height: kSpacingMedium),

        // Address
        Text(
          'Address',
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: kSpacingSmall),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter full address',
            hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: kSpacingMedium),

        // Password and Confirm Password
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: passwordValidator,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Password *',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) => confirmPasswordValidator(value, _passwordController.text),
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width * 0.5;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: kSpacingLarge, vertical: kSpacingLarge),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: mq.size.height * 0.9,
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_add,
                              color: AppColors.primary,
                              size: kIconSizeMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: kSpacingMedium),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New User',
                              style: kTextStyleTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Step ${_step + 1} of 2',
                              style: kTextStyleRegular.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: kIconSizeLarge,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: kSpacingLarge),

                // Step Indicator
                _buildStepIndicator(width),

                const SizedBox(height: kSpacingLarge),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: _step == 0 ? _buildBasicInformation() : _buildAdditionalDetails(),
                    ),
                  ),
                ),

                const SizedBox(height: kSpacingLarge),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: Text(
                          'Previous',
                          style: kTextStyleRegular.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: kSpacingMedium),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingMedium),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingLarge,
                          vertical: kSpacingMedium,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              _step == 1 ? 'Create User' : 'Next Step',
                              style: kTextStyleRegular.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
