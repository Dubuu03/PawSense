import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Admin Management',
              style: kTextStyleHeader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              'Manage admin users and their permissions',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: kSpacingLarge),
            
            // Quick Actions
            Row(
              children: [
                _buildActionCard(
                  'Add New Admin',
                  Icons.person_add,
                  AppColors.success,
                  () => _showAddAdminDialog(),
                ),
                SizedBox(width: kSpacingMedium),
                _buildActionCard(
                  'Pending Approvals',
                  Icons.pending_actions,
                  AppColors.warning,
                  () => _showPendingApprovals(),
                ),
                SizedBox(width: kSpacingMedium),
                _buildActionCard(
                  'Admin Reports',
                  Icons.analytics,
                  AppColors.info,
                  () => _showAdminReports(),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Admin List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: EdgeInsets.all(kSpacingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(kBorderRadius),
                          topRight: Radius.circular(kBorderRadius),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text('Name', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Email', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Clinic', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Status', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold))),
                          SizedBox(width: 100, child: Text('Actions', style: kTextStyleRegular.copyWith(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    
                    // Admin List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(kSpacingMedium),
                        itemCount: _mockAdmins.length,
                        itemBuilder: (context, index) {
                          final admin = _mockAdmins[index];
                          return _buildAdminRow(admin);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(kSpacingMedium),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: kIconSizeLarge),
              SizedBox(height: kSpacingSmall),
              Text(
                title,
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminRow(Map<String, dynamic> admin) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingSmall),
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        children: [
          Expanded(child: Text(admin['name'], style: kTextStyleRegular)),
          Expanded(child: Text(admin['email'], style: kTextStyleRegular)),
          Expanded(child: Text(admin['clinic'], style: kTextStyleRegular)),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: kSpacingSmall, vertical: 4),
              decoration: BoxDecoration(
                color: admin['status'] == 'Active' ? AppColors.success : AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                admin['status'],
                style: kTextStyleSmall.copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _editAdmin(admin),
                  icon: Icon(Icons.edit, color: AppColors.info, size: kIconSizeMedium),
                ),
                IconButton(
                  onPressed: () => _deleteAdmin(admin),
                  icon: Icon(Icons.delete, color: AppColors.error, size: kIconSizeMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog() {
    // TODO: Implement add admin dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add Admin functionality coming soon')),
    );
  }

  void _showPendingApprovals() {
    // TODO: Implement pending approvals screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pending Approvals functionality coming soon')),
    );
  }

  void _showAdminReports() {
    // TODO: Implement admin reports
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Admin Reports functionality coming soon')),
    );
  }

  void _editAdmin(Map<String, dynamic> admin) {
    // TODO: Implement edit admin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${admin['name']} functionality coming soon')),
    );
  }

  void _deleteAdmin(Map<String, dynamic> admin) {
    // TODO: Implement delete admin with confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete ${admin['name']} functionality coming soon')),
    );
  }

  final List<Map<String, dynamic>> _mockAdmins = [
    {
      'name': 'Dr. Sarah Johnson',
      'email': 'sarah@pawsense.com',
      'clinic': 'PawSense Main Clinic',
      'status': 'Active',
    },
    {
      'name': 'Dr. Michael Chen',
      'email': 'michael@pawsense.com',
      'clinic': 'PawSense North Branch',
      'status': 'Active',
    },
    {
      'name': 'Dr. Emily Davis',
      'email': 'emily@pawsense.com',
      'clinic': 'PawSense South Branch',
      'status': 'Pending',
    },
  ];
}
