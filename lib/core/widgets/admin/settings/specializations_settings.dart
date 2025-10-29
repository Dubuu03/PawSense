import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/super_admin/predefined_specialization_service.dart';

/// Specializations Management Settings
/// Allows admins to manage the predefined list of specializations
class SpecializationsSettings extends StatefulWidget {
  const SpecializationsSettings({super.key});

  @override
  State<SpecializationsSettings> createState() => _SpecializationsSettingsState();
}

class _SpecializationsSettingsState extends State<SpecializationsSettings> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _specializations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  Future<void> _loadSpecializations() async {
    setState(() => _isLoading = true);
    try {
      final specs = await PredefinedSpecializationService.getAllSpecializations();
      if (mounted) {
        setState(() {
          _specializations = specs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading specializations: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSpecializations {
    if (_searchQuery.isEmpty) return _specializations;
    return _specializations.where((spec) {
      final name = (spec['name'] as String? ?? '').toLowerCase();
      final description = (spec['description'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  Future<void> _addSpecialization() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddEditSpecializationDialog(),
    );

    if (result != null) {
      final success = await PredefinedSpecializationService.addSpecialization(
        name: result['name'],
        description: result['description'],
        isActive: result['isActive'] ?? true,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specialization added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSpecializations();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specialization already exists or failed to add'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _editSpecialization(Map<String, dynamic> specialization) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddEditSpecializationDialog(
        specialization: specialization,
      ),
    );

    if (result != null) {
      final success = await PredefinedSpecializationService.updateSpecialization(
        id: specialization['id'],
        name: result['name'],
        description: result['description'],
        isActive: result['isActive'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specialization updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSpecializations();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update specialization'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSpecialization(Map<String, dynamic> specialization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Specialization'),
        content: Text(
          'Are you sure you want to delete "${specialization['name']}"?\n\n'
          'This will not affect clinics that already have this specialization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PredefinedSpecializationService.deleteSpecialization(
        specialization['id'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Specialization deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSpecializations();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete specialization'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> specialization) async {
    final newStatus = !(specialization['isActive'] ?? false);
    final success = await PredefinedSpecializationService.toggleActive(
      specialization['id'],
      newStatus,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Specialization ${newStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadSpecializations();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update specialization status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specializations Management',
                    style: TextStyle(
                      fontSize: kFontSizeLarge + 2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: kSpacingSmall),
                  Text(
                    'Manage the list of veterinary specializations available for clinics to choose from',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: kFontSizeRegular,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addSpecialization,
              icon: Icon(Icons.add),
              label: Text('Add Specialization'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingLarge,
                  vertical: kSpacingMedium + 4,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: kSpacingLarge),

        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search specializations...',
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: kSpacingMedium,
              vertical: kSpacingMedium,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        SizedBox(height: kSpacingLarge),

        // Specializations List
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(kSpacingXLarge),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredSpecializations.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(kSpacingXLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: kSpacingMedium),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No specializations found'
                        : 'No specializations match your search',
                    style: TextStyle(
                      fontSize: kFontSizeLarge,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSpecializations.length,
              itemBuilder: (context, index) {
                final spec = _filteredSpecializations[index];
                final isActive = spec['isActive'] ?? false;

                return Container(
                  margin: EdgeInsets.only(bottom: kSpacingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(kSpacingMedium),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          spec['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: kFontSizeRegular,
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: kSpacingSmall),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: kFontSizeSmall,
                              color: isActive ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: spec['description'] != null
                        ? Padding(
                            padding: EdgeInsets.only(top: kSpacingSmall),
                            child: Text(
                              spec['description'],
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: kFontSizeSmall,
                              ),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle Active/Inactive
                        IconButton(
                          onPressed: () => _toggleActive(spec),
                          icon: Icon(
                            isActive ? Icons.visibility : Icons.visibility_off,
                            color: isActive ? AppColors.success : AppColors.textSecondary,
                          ),
                          tooltip: isActive ? 'Deactivate' : 'Activate',
                        ),
                        // Edit
                        IconButton(
                          onPressed: () => _editSpecialization(spec),
                          icon: Icon(Icons.edit_outlined),
                          color: AppColors.primary,
                          tooltip: 'Edit',
                        ),
                        // Delete
                        IconButton(
                          onPressed: () => _deleteSpecialization(spec),
                          icon: Icon(Icons.delete_outline),
                          color: AppColors.error,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// Dialog for adding/editing specializations
class _AddEditSpecializationDialog extends StatefulWidget {
  final Map<String, dynamic>? specialization;

  const _AddEditSpecializationDialog({this.specialization});

  @override
  State<_AddEditSpecializationDialog> createState() => _AddEditSpecializationDialogState();
}

class _AddEditSpecializationDialogState extends State<_AddEditSpecializationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.specialization?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.specialization?['description'] ?? '',
    );
    _isActive = widget.specialization?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.specialization != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(kSpacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                isEdit ? 'Edit Specialization' : 'Add Specialization',
                style: TextStyle(
                  fontSize: kFontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: kSpacingLarge),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Specialization Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a specialization name';
                  }
                  return null;
                },
              ),
              SizedBox(height: kSpacingMedium),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                maxLines: 3,
              ),
              SizedBox(height: kSpacingMedium),

              // Active Toggle
              SwitchListTile(
                title: Text('Active'),
                subtitle: Text('Clinics can select this specialization'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppColors.primary,
              ),
              SizedBox(height: kSpacingLarge),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: kSpacingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text.trim(),
                            'description': _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            'isActive': _isActive,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: kSpacingMedium + 4),
                      ),
                      child: Text(isEdit ? 'Update' : 'Add'),
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
