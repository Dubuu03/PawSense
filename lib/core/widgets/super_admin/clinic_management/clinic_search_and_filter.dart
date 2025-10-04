import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/shared/search_field.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class ClinicSearchAndFilter extends StatefulWidget {
  final String searchQuery;
  final String selectedStatus;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final VoidCallback onExportData;

  const ClinicSearchAndFilter({
    super.key,
    required this.searchQuery,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onExportData,
  });

  @override
  State<ClinicSearchAndFilter> createState() => _ClinicSearchAndFilterState();
}

class _ClinicSearchAndFilterState extends State<ClinicSearchAndFilter> {
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
              hintText: 'Search clinics by name, email, or registration number...',
              controller: _searchController,
              onChanged: widget.onSearchChanged,
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
              items: ['All Status', 'pending', 'approved', 'rejected', 'suspended'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status == 'All Status' ? status : _formatStatusName(status),
                    style: kTextStyleRegular.copyWith(color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) => widget.onStatusChanged(value == 'All Status' ? '' : (value ?? '')),
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

  String _formatStatusName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return status.toUpperCase();
    }
  }
}
