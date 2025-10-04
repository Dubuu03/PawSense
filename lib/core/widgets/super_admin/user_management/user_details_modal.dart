import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/validators.dart';

class UserDetailsModal extends StatefulWidget {
  final UserModel user;
  final void Function(UserModel user)? onUpdateUser;
  final void Function(bool isActive, String? reason)? onStatusChange;

  const UserDetailsModal({
    super.key,
    required this.user,
    this.onUpdateUser,
    this.onStatusChange,
  });

  @override
  State<UserDetailsModal> createState() => _UserDetailsModalState();
}

class _UserDetailsModalState extends State<UserDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;
  late TextEditingController _addressController;
  late TextEditingController _suspensionReasonController;
  
  late String _selectedRole;
  DateTime? _dateOfBirth;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.user.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user.lastName ?? '');
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _contactNumberController = TextEditingController(text: widget.user.contactNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _suspensionReasonController = TextEditingController(text: widget.user.suspensionReason ?? '');
    
    _selectedRole = widget.user.role;
    _dateOfBirth = widget.user.dateOfBirth;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _suspensionReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)),
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

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values if canceling edit
        _initializeControllers();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create updated user model
      final updatedUser = UserModel(
        uid: widget.user.uid,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim().isNotEmpty 
            ? _firstNameController.text.trim() 
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty 
            ? _lastNameController.text.trim() 
            : null,
        email: _emailController.text.trim(),
        role: _selectedRole,
        createdAt: widget.user.createdAt,
        contactNumber: _contactNumberController.text.trim().isNotEmpty 
            ? _contactNumberController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        dateOfBirth: _dateOfBirth,
        isActive: _isActive,
        suspensionReason: _suspensionReasonController.text.trim().isNotEmpty 
            ? _suspensionReasonController.text.trim() 
            : null,
        suspendedAt: !_isActive ? DateTime.now() : null,
        updatedAt: DateTime.now(),
        profileImageUrl: widget.user.profileImageUrl,
        darkTheme: widget.user.darkTheme,
        agreedToTerms: widget.user.agreedToTerms,
      );

      // Call the callback function
      widget.onUpdateUser?.call(updatedUser);
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
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

  // User status toggle method removed - functionality not currently used

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isSmallScreen = mq.size.width < 768;
    final modalWidth = isSmallScreen ? mq.size.width * 0.95 : mq.size.width * 0.7;
    final modalMaxWidth = isSmallScreen ? 500.0 : 800.0;

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
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: modalWidth.clamp(400.0, modalMaxWidth),
            maxHeight: mq.size.height * (isSmallScreen ? 0.95 : 0.9),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Tab Bar
              _buildTabBar(),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildAccountTab(),
                    _buildActivityTab(),
                  ],
                ),
              ),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(kSpacingLarge),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getRoleColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: kTextStyleLarge.copyWith(
                  color: _getRoleColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: kSpacingMedium),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: kTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    _buildRoleChip(),
                    const SizedBox(width: kSpacingMedium),
                    _buildStatusBadge(),
                  ],
                ),
              ],
            ),
          ),
          
          // Edit Toggle Button
          IconButton(
            onPressed: _toggleEditMode,
            icon: Icon(
              _isEditing ? Icons.edit_off : Icons.edit,
              color: _isEditing ? AppColors.error : AppColors.primary,
            ),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit User',
          ),
          
          // Close Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Profile', icon: Icon(Icons.person, size: 20)),
          Tab(text: 'Account', icon: Icon(Icons.settings, size: 20)),
          Tab(text: 'Activity', icon: Icon(Icons.history, size: 20)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: kTextStyleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            // First Name and Last Name
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'First Name',
                    controller: _firstNameController,
                    enabled: _isEditing,
                    hintText: 'Enter first name',
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildFormField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    enabled: _isEditing,
                    hintText: 'Enter last name',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: kSpacingLarge),
            
            // Username
            _buildFormField(
              label: 'Username',
              controller: _usernameController,
              enabled: _isEditing,
              validator: (value) => requiredValidator(value, 'username'),
              hintText: 'Enter username',
              isRequired: true,
            ),
            
            const SizedBox(height: kSpacingLarge),
            
            // Contact and Date of Birth
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Contact Number',
                    controller: _contactNumberController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    hintText: 'Enter contact number',
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildDatePickerField(),
                ),
              ],
            ),
            
            const SizedBox(height: kSpacingLarge),
            
            // Address
            _buildFormField(
              label: 'Address',
              controller: _addressController,
              enabled: _isEditing,
              maxLines: 3,
              hintText: 'Enter full address',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Email
          _buildFormField(
            label: 'Email Address',
            controller: _emailController,
            enabled: _isEditing,
            validator: emailValidator,
            keyboardType: TextInputType.emailAddress,
            hintText: 'Enter email address',
            isRequired: true,
          ),
          
          const SizedBox(height: kSpacingLarge),
          
          // Role
          _buildDropdownField(
            label: 'Role',
            value: _selectedRole,
            enabled: _isEditing,
            isRequired: true,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
            ],
            onChanged: _isEditing ? (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            } : null,
          ),
          
          const SizedBox(height: kSpacingLarge),
          
          // Account Status Section
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                
                Row(
                  children: [
                    Switch(
                      value: _isActive,
                      onChanged: _isEditing ? (value) {
                        setState(() => _isActive = value);
                      } : null,
                      activeThumbColor: AppColors.success,
                    ),
                    const SizedBox(width: kSpacingMedium),
                    Text(
                      _isActive ? 'Active' : 'Suspended',
                      style: kTextStyleRegular.copyWith(
                        color: _isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                if (!_isActive) ...[
                  const SizedBox(height: kSpacingMedium),
                  _buildFormField(
                    label: 'Suspension Reason',
                    controller: _suspensionReasonController,
                    enabled: _isEditing,
                    maxLines: 3,
                    hintText: 'Enter reason for suspension',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Activity',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          _buildInfoRow('User ID', widget.user.uid),
          _buildInfoRow('Account Created', _formatDateTime(widget.user.createdAt)),
          if (widget.user.updatedAt != null)
            _buildInfoRow('Last Updated', _formatDateTime(widget.user.updatedAt!)),
          if (widget.user.suspendedAt != null)
            _buildInfoRow('Suspended On', _formatDateTime(widget.user.suspendedAt!)),
          _buildInfoRow('Terms Agreed', widget.user.agreedToTerms == true ? 'Yes' : 'No'),
          _buildInfoRow('Dark Theme', widget.user.darkTheme ? 'Enabled' : 'Disabled'),
          
          const SizedBox(height: kSpacingLarge),
          
          // Additional activity information could go here
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                Text(
                  'Activity logs would be displayed here in a full implementation.',
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: kTextStyleRegular.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: kTextStyleRegular.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
    bool enabled = true,
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
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
            enabled: enabled,
            style: kTextStyleRegular.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
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
    required void Function(String?)? onChanged,
    bool isRequired = false,
    bool enabled = true,
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            style: kTextStyleRegular.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: InkWell(
            onTap: _isEditing ? _selectDateOfBirth : null,
            borderRadius: BorderRadius.circular(kBorderRadius),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kBorderRadius),
                color: AppColors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Select date of birth',
                      style: kTextStyleRegular.copyWith(
                        color: _dateOfBirth != null 
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: _isEditing ? AppColors.textSecondary : AppColors.textTertiary,
                    size: kIconSizeMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(kSpacingLarge),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Footer Information
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: kSpacingSmall),
              Expanded(
                child: Text(
                  'Last updated: ${widget.user.updatedAt != null ? _formatDateTime(widget.user.updatedAt!) : _formatDateTime(widget.user.createdAt)}',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              if (widget.user.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Account',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: kSpacingMedium),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Actions Info
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: kSpacingSmall),
                    Text(
                      'User ID: ${widget.user.uid.substring(0, 8)}...',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditing) ...[
                    OutlinedButton(
                      onPressed: _isLoading ? null : _toggleEditMode,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingLarge,
                          vertical: kSpacingMedium,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingMedium),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
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
                            'Save Changes',
                            style: kTextStyleRegular.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: () {
                        // Copy user ID to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User ID copied to clipboard'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 16),
                      label: Text('Copy ID'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingMedium,
                          vertical: kSpacingSmall,
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpacingMedium),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kBorderRadius),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingLarge,
                          vertical: kSpacingMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final userIsActive = widget.user.isActive;
    
    String statusText;
    Color statusColor;
    Color bgColor;
    
    if (!userIsActive) {
      statusText = 'Suspended';
      statusColor = AppColors.error;
      bgColor = AppColors.statusOpenBg;
    } else {
      statusText = 'Active';
      statusColor = AppColors.success;
      bgColor = AppColors.statusResolvedBg;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRoleChip() {
    final roleColor = _getRoleColor();
    final roleBackgroundColor = _getRoleBackgroundColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
      decoration: BoxDecoration(
        color: roleBackgroundColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Text(
        _formatRoleName(widget.user.role),
        style: kTextStyleSmall.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      default:
        return role.toUpperCase();
    }
  }

  String _getDisplayName() {
    if (widget.user.firstName != null && widget.user.lastName != null) {
      return '${widget.user.firstName} ${widget.user.lastName}';
    }
    return widget.user.username;
  }

  String _getInitials() {
    final displayName = _getDisplayName();
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  Color _getRoleColor() {
    switch (widget.user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdmin;
      case 'admin':
        return AppColors.roleAdmin;
      case 'user':
        return AppColors.roleUser;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _getRoleBackgroundColor() {
    switch (widget.user.role) {
      case 'super_admin':
        return AppColors.roleSuperAdminBg;
      case 'admin':
        return AppColors.roleAdminBg;
      case 'user':
        return AppColors.roleUserBg;
      default:
        return AppColors.border;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}