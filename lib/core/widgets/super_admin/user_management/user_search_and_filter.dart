import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/shared/search_field.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class UserSearchAndFilter extends StatefulWidget {
  final String searchQuery;
  final String selectedRole;
  final String selectedStatus;
  final Function(String) onSearchChanged;
  final Function(String) onRoleChanged;
  final Function(String) onStatusChanged;
  final VoidCallback onExportData;

  const UserSearchAndFilter({
    super.key,
    required this.searchQuery,
    required this.selectedRole,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onExportData,
  });

  @override
  State<UserSearchAndFilter> createState() => _UserSearchAndFilterState();
}

class _UserSearchAndFilterState extends State<UserSearchAndFilter> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SearchField(
              hintText: 'Search users by name or email...',
              controller: _searchController,
              onChanged: widget.onSearchChanged,
            ),
          ),
          SizedBox(width: kSpacingMedium),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: widget.selectedRole.isEmpty ? 'All Roles' : widget.selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                labelStyle: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
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
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
                filled: true,
                fillColor: AppColors.white,
              ),
              style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
              items: ['All Roles', 'user', 'admin', 'super_admin'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(
                    role == 'All Roles' ? role : _formatRoleName(role),
                    style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) => widget.onRoleChanged(value == 'All Roles' ? '' : (value ?? '')),
            ),
          ),
          SizedBox(width: kSpacingMedium),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: widget.selectedStatus.isEmpty ? 'All Status' : widget.selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
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
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
                filled: true,
                fillColor: AppColors.white,
              ),
              style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
              items: ['All Status', 'Active', 'Suspended'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) => widget.onStatusChanged(value ?? ''),
            ),
          ),
          SizedBox(width: kSpacingMedium),
          ElevatedButton.icon(
            onPressed: widget.onExportData,
            icon: Icon(Icons.download_outlined, size: kIconSizeMedium),
            label: Text('Export', style: kTextStyleRegular.copyWith(
              fontWeight: FontWeight.w500,
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: kSpacingLarge, 
                vertical: kSpacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'user':
        return 'User';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return role.toUpperCase();
    }
  }
}
