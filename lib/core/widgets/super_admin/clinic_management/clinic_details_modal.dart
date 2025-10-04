import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/validators.dart';

class ClinicDetailsModal extends StatefulWidget {
  final ClinicRegistration clinic;
  final Function(ClinicRegistration)? onUpdateClinic;
  final Function(ClinicStatus, String?)? onStatusChange;

  const ClinicDetailsModal({
    super.key,
    required this.clinic,
    this.onUpdateClinic,
    this.onStatusChange,
  });

  @override
  State<ClinicDetailsModal> createState() => _ClinicDetailsModalState();
}

class _ClinicDetailsModalState extends State<ClinicDetailsModal> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _clinicNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _adminNameController;
  late TextEditingController _reasonController;
  
  // State
  bool _isEditing = false;
  bool _isLoading = false;
  late ClinicStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedStatus = widget.clinic.status;
    _initializeControllers();
  }

  void _initializeControllers() {
    _clinicNameController = TextEditingController(text: widget.clinic.clinicName);
    _emailController = TextEditingController(text: widget.clinic.email);
    _phoneController = TextEditingController(text: widget.clinic.phone);
    _addressController = TextEditingController(text: widget.clinic.address);
    _licenseNumberController = TextEditingController(text: widget.clinic.licenseNumber);
    _adminNameController = TextEditingController(text: widget.clinic.adminName);
    _reasonController = TextEditingController(
      text: widget.clinic.rejectionReason ?? widget.clinic.suspensionReason ?? ''
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clinicNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _adminNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values if canceling edit
        _initializeControllers();
        _selectedStatus = widget.clinic.status;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create updated clinic model
      final updatedClinic = ClinicRegistration(
        id: widget.clinic.id,
        clinicName: _clinicNameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminId: widget.clinic.adminId,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        status: _selectedStatus,
        applicationDate: widget.clinic.applicationDate,
        approvedDate: _selectedStatus == ClinicStatus.approved ? DateTime.now() : widget.clinic.approvedDate,
        rejectionReason: _selectedStatus == ClinicStatus.rejected ? _reasonController.text.trim() : null,
        suspensionReason: _selectedStatus == ClinicStatus.suspended ? _reasonController.text.trim() : null,
      );

      // Call the callback function
      widget.onUpdateClinic?.call(updatedClinic);
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinic updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update clinic: $e'),
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
                    _buildDetailsTab(),
                    _buildStatusTab(),
                    _buildActivityTab(),
                  ],
                ),
              ),
              
              // Footer Actions
              _buildFooter(),
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
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Clinic Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color: _getStatusColor(),
              size: kIconSizeLarge,
            ),
          ),
          
          const SizedBox(width: kSpacingMedium),
          
          // Clinic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clinic.clinicName,
                  style: kTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    _buildStatusChip(),
                    const SizedBox(width: kSpacingMedium),
                    Text(
                      'License: ${widget.clinic.licenseNumber}',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(
                onPressed: _toggleEditMode,
                icon: Icon(
                  _isEditing ? Icons.edit_off : Icons.edit_outlined,
                ),
                color: _isEditing ? AppColors.error : AppColors.primary,
                tooltip: _isEditing ? 'Cancel Edit' : 'Edit Clinic',
              ),
              const SizedBox(width: kSpacingSmall),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Clinic Details'),
          Tab(text: 'Status & Actions'),
          Tab(text: 'Activity Log'),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinic Information',
              style: kTextStyleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            // Clinic Name and License Number
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Clinic Name',
                    controller: _clinicNameController,
                    enabled: _isEditing,
                    validator: (value) => requiredValidator(value, 'clinic name'),
                    hintText: 'Enter clinic name',
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildFormField(
                    label: 'License Number',
                    controller: _licenseNumberController,
                    enabled: _isEditing,
                    validator: (value) => requiredValidator(value, 'license number'),
                    hintText: 'Enter license number',
                    isRequired: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: kSpacingLarge),
            
            // Email and Phone
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Email Address',
                    controller: _emailController,
                    enabled: _isEditing,
                    validator: emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'Enter email address',
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildFormField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    hintText: 'Enter phone number',
                  ),
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
              hintText: 'Enter clinic address',
            ),
            
            const SizedBox(height: kSpacingLarge),
            
            // Administrator Details
            Text(
              'Administrator Information',
              style: kTextStyleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            _buildFormField(
              label: 'Administrator Name',
              controller: _adminNameController,
              enabled: _isEditing,
              hintText: 'Enter administrator name',
            ),
            
            const SizedBox(height: kSpacingMedium),
            
            _buildFormField(
              label: 'Administrator ID',
              controller: TextEditingController(text: widget.clinic.adminId),
              enabled: false,
              hintText: 'Administrator ID',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Management',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Current Status
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
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                _buildStatusChip(),
                
                if (widget.clinic.approvedDate != null) ...[
                  const SizedBox(height: kSpacingMedium),
                  Text(
                    'Approved on: ${_formatDateTime(widget.clinic.approvedDate!)}',
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                
                if (widget.clinic.rejectionReason != null && widget.clinic.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: kSpacingMedium),
                  Text(
                    'Rejection Reason:',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  Text(
                    widget.clinic.rejectionReason!,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                
                if (widget.clinic.suspensionReason != null && widget.clinic.suspensionReason!.isNotEmpty) ...[
                  const SizedBox(height: kSpacingMedium),
                  Text(
                    'Suspension Reason:',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  Text(
                    widget.clinic.suspensionReason!,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          
          if (_isEditing) ...[
            const SizedBox(height: kSpacingLarge),
            
            // Status Change Section
            Text(
              'Change Status',
              style: kTextStyleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
            _buildDropdownField(
              label: 'New Status',
              value: _selectedStatus.toString().split('.').last,
              enabled: _isEditing,
              items: [
                const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                const DropdownMenuItem(value: 'approved', child: Text('Approved')),
                const DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                const DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
              ],
              onChanged: _isEditing ? (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = ClinicStatus.values.firstWhere(
                      (status) => status.toString().split('.').last == value,
                    );
                  });
                }
              } : null,
            ),
            
            if (_selectedStatus == ClinicStatus.rejected || _selectedStatus == ClinicStatus.suspended) ...[
              const SizedBox(height: kSpacingLarge),
              _buildFormField(
                label: _selectedStatus == ClinicStatus.rejected ? 'Rejection Reason' : 'Suspension Reason',
                controller: _reasonController,
                enabled: _isEditing,
                maxLines: 3,
                hintText: 'Enter reason for ${_selectedStatus == ClinicStatus.rejected ? 'rejection' : 'suspension'}',
                isRequired: true,
              ),
            ],
          ] else if (widget.clinic.status == ClinicStatus.pending) ...[
            const SizedBox(height: kSpacingLarge),
            
            // Quick Actions for Pending Clinics
            Text(
              'Quick Actions',
              style: kTextStyleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            
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
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This clinic is pending approval. You can quickly approve or reject the application.',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: kSpacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop('reject');
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject Application'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            elevation: 2,
                            shadowColor: AppColors.error.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingMedium,
                              vertical: kSpacingMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop('approve');
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve Application'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            elevation: 2,
                            shadowColor: AppColors.success.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kBorderRadius),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingMedium,
                              vertical: kSpacingMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            'Application Timeline',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Application Date
          _buildTimelineItem(
            icon: Icons.assignment_outlined,
            title: 'Application Submitted',
            subtitle: 'Clinic registration application was submitted',
            timestamp: widget.clinic.applicationDate,
            color: AppColors.info,
          ),
          
          // Approval Date
          if (widget.clinic.approvedDate != null)
            _buildTimelineItem(
              icon: Icons.check_circle_outlined,
              title: 'Application Approved',
              subtitle: 'Clinic has been approved and can operate',
              timestamp: widget.clinic.approvedDate!,
              color: AppColors.success,
            ),
          
          // Additional timeline items could be added here for more detailed activity tracking
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime timestamp,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: kSpacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  subtitle,
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  _formatDateTime(timestamp),
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(kSpacingLarge),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
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
                  'Applied: ${_formatDateTime(widget.clinic.applicationDate)}',
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              if (widget.clinic.status == ClinicStatus.approved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
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
              // Clinic ID Info
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: kSpacingSmall),
                    Text(
                      'ID: ${widget.clinic.id.substring(0, 8)}...',
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
                        shadowColor: AppColors.primary.withOpacity(0.3),
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
                        // Copy clinic ID to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Clinic ID copied to clipboard'),
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
                        shadowColor: AppColors.primary.withOpacity(0.3),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    bool enabled = true,
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
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
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
            style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kSpacingMedium,
                vertical: kSpacingMedium,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            dropdownColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.clinic.status) {
      case ClinicStatus.pending:
        return AppColors.clinicPending;
      case ClinicStatus.approved:
        return AppColors.clinicApproved;
      case ClinicStatus.rejected:
        return AppColors.clinicRejected;
      case ClinicStatus.suspended:
        return AppColors.clinicSuspended;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (widget.clinic.status) {
      case ClinicStatus.pending:
        return AppColors.clinicPendingBg;
      case ClinicStatus.approved:
        return AppColors.clinicApprovedBg;
      case ClinicStatus.rejected:
        return AppColors.clinicRejectedBg;
      case ClinicStatus.suspended:
        return AppColors.clinicSuspendedBg;
    }
  }

  Widget _buildStatusChip() {
    final statusColor = _getStatusColor();
    final statusText = widget.clinic.status.displayName;
    final bgColor = _getStatusBackgroundColor();

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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}