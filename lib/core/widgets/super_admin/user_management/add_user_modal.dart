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



  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: kTextStyleRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: kSpacingSmall),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: kTextStyleRegular.copyWith(color: AppColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kSpacingMedium,
                vertical: kSpacingMedium,
              ),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: kTextStyleRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: kSpacingSmall),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kSpacingMedium,
                vertical: kSpacingMedium,
              ),
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
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(double width) {
    final labels = ['Basic Information', 'Additional Details'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingLarge,
        vertical: kSpacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Step indicators with connectors
          SizedBox(
            height: 50,
            child: Stack(
              children: [
                // Connector line
                Positioned(
                  top: 19,
                  left: 60,
                  right: 60,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _step > 0 ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Step circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(2, (index) {
                    final isCompleted = index < _step;
                    final isActive = index == _step;
                    final isUpcoming = index > _step;
                    
                    Color bgColor;
                    Color textColor;
                    Widget icon;
                    
                    if (isCompleted) {
                      bgColor = AppColors.primary;
                      textColor = AppColors.white;
                      icon = const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 14,
                      );
                    } else if (isActive) {
                      bgColor = AppColors.primary;
                      textColor = AppColors.white;
                      icon = Text(
                        '${index + 1}',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontSize: 13,
                        ),
                      );
                    } else {
                      bgColor = AppColors.white;
                      textColor = AppColors.textTertiary;
                      icon = Text(
                        '${index + 1}',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 13,
                        ),
                      );
                    }
                    
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: Border.all(
                          color: isUpcoming ? AppColors.border : AppColors.primary,
                          width: 2,
                        ),
                        boxShadow: isActive || isCompleted ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(child: icon),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              labels.length,
              (i) => Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                  style: kTextStyleRegular.copyWith(
                    color: i <= _step ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: i == _step ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Please provide the basic user information',
          style: kTextStyleRegular.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: kSpacingLarge),

        // First Name and Last Name
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'First Name',
                controller: _firstNameController,
                validator: (value) => requiredValidator(value, 'first name'),
                hintText: 'Enter first name',
                isRequired: true,
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: _buildFormField(
                label: 'Last Name',
                controller: _lastNameController,
                validator: (value) => requiredValidator(value, 'last name'),
                hintText: 'Enter last name',
                isRequired: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: kSpacingLarge),

        // Username
        _buildFormField(
          label: 'Username',
          controller: _usernameController,
          validator: (value) => requiredValidator(value, 'username'),
          hintText: 'Enter username',
          isRequired: true,
        ),

        const SizedBox(height: kSpacingLarge),

        // Email and Role
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildFormField(
                label: 'Email Address',
                controller: _emailController,
                validator: emailValidator,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter email address',
                isRequired: true,
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: _buildDropdownField(
                label: 'Role',
                value: _selectedRole,
                isRequired: true,
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
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Optional details to complete the user profile',
          style: kTextStyleRegular.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: kSpacingLarge),

        // Contact Number and Date of Birth
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Contact Number',
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                hintText: 'Enter contact number',
              ),
            ),

          ],
        ),

        const SizedBox(height: kSpacingLarge),

        // Address
        _buildFormField(
          label: 'Address',
          controller: _addressController,
          maxLines: 3,
          hintText: 'Enter full address',
        ),

        const SizedBox(height: kSpacingLarge),

        // Password and Confirm Password
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                validator: passwordValidator,
                hintText: 'Enter password',
                isRequired: true,
              ),
            ),
            const SizedBox(width: kSpacingMedium),
            Expanded(
              child: _buildFormField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) => confirmPasswordValidator(value, _passwordController.text),
                hintText: 'Confirm password',
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          OutlinedButton(
            onPressed: _isLoading ? null : _previousStep,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacingLarge,
                vertical: kSpacingMedium,
              ),
            ),
            child: Text(
              'Previous',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingLarge * 1.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isSmallScreen = mq.size.width < 768;
    final modalWidth = isSmallScreen ? mq.size.width * 0.95 : mq.size.width * 0.5;
    final modalMaxWidth = isSmallScreen ? 400.0 : 600.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? kSpacingMedium : kSpacingLarge,
        vertical: isSmallScreen ? kSpacingMedium : kSpacingLarge,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
      elevation: 8,
      backgroundColor: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: modalWidth.clamp(300.0, modalMaxWidth),
            maxHeight: mq.size.height * (isSmallScreen ? 0.95 : 0.9),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? kSpacingMedium : kSpacingLarge),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_add,
                                  color: AppColors.primary,
                                  size: kIconSizeLarge,
                                ),
                              ),
                            ),
                            const SizedBox(width: kSpacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New User',
                                    style: kTextStyleTitle.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Step ${_step + 1} of 2',
                                    style: kTextStyleRegular.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: kIconSizeLarge,
                          ),
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // Step Indicator
                  _buildStepIndicator(modalWidth),

                  const SizedBox(height: kSpacingLarge),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.border.withValues(alpha: 0.3),
                          AppColors.border,
                          AppColors.border.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: _step == 0 ? _buildBasicInformation() : _buildAdditionalDetails(),
                      ),
                    ),
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.border.withValues(alpha: 0.3),
                          AppColors.border,
                          AppColors.border.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // Action Buttons
                  _buildActionButtons(),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
