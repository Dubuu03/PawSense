import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/super_admin/predefined_specialization_service.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import 'package:pawsense/core/widgets/shared/pagination_widget.dart';

class SpecializationsManagementScreen extends StatefulWidget {
  const SpecializationsManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('specializations_management'));

  @override
  State<SpecializationsManagementScreen> createState() => _SpecializationsManagementScreenState();
}

class _SpecializationsManagementScreenState extends State<SpecializationsManagementScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _allSpecializations = [];
  List<Map<String, dynamic>> _filteredSpecializations = [];
  List<Map<String, dynamic>> _displayedSpecializations = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalSpecializations = 0;
  int _totalPages = 0;
  final int _itemsPerPage = 10;
  
  // Statistics
  int _totalCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  Future<void> _loadSpecializations() async {
    setState(() => _isLoading = true);
    
    try {
      final specializations = await PredefinedSpecializationService.getAllSpecializations();
      
      setState(() {
        _allSpecializations = specializations;
        _filteredSpecializations = specializations;
        _updateStatistics();
        _updatePagination();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading specializations: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading specializations: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _updateStatistics() {
    _totalCount = _allSpecializations.length;
    _activeCount = _allSpecializations.where((s) => s['isActive'] == true).length;
    _inactiveCount = _totalCount - _activeCount;
  }

  void _updatePagination() {
    _totalSpecializations = _filteredSpecializations.length;
    _totalPages = (_totalSpecializations / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    
    // Ensure current page is valid
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    
    // Get current page items
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _totalSpecializations);
    
    if (startIndex < _totalSpecializations) {
      _displayedSpecializations = _filteredSpecializations.sublist(startIndex, endIndex);
    } else {
      _displayedSpecializations = [];
    }
  }

  void _filterSpecializations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSpecializations = _allSpecializations;
      } else {
        _filteredSpecializations = _allSpecializations.where((spec) {
          final name = (spec['name'] ?? '').toString().toLowerCase();
          final description = (spec['description'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || description.contains(searchLower);
        }).toList();
      }
      _currentPage = 1; // Reset to first page on search
      _updatePagination();
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _updatePagination();
    });
  }

  void _showAddEditDialog({Map<String, dynamic>? specialization}) {
    final isEdit = specialization != null;
    final nameController = TextEditingController(text: specialization?['name'] ?? '');
    final descriptionController = TextEditingController(text: specialization?['description'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Specialization' : 'Add Specialization'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g., Small Animal Medicine',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: kSpacingMedium),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Brief description of the specialization',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.of(context).pop();

              try {
                if (isEdit) {
                  await PredefinedSpecializationService.updateSpecialization(
                    id: specialization['id'],
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Specialization updated successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  await PredefinedSpecializationService.addSpecialization(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Specialization added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
                
                await _loadSpecializations();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(String id, bool currentValue) async {
    try {
      await PredefinedSpecializationService.toggleActive(id, !currentValue);
      await _loadSpecializations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            PageHeader(
              title: 'Specializations Management',
              subtitle: 'Manage veterinary specializations available to all clinics',
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Specializations',
                    _totalCount.toString(),
                    Icons.category_outlined,
                    AppColors.primary,
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    _activeCount.toString(),
                    Icons.check_circle_outline,
                    AppColors.success,
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: _buildStatCard(
                    'Inactive',
                    _inactiveCount.toString(),
                    Icons.cancel_outlined,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Actions Bar
            Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search specializations...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    onChanged: _filterSpecializations,
                  ),
                ),
                
                Spacer(),
                
                // Add Button
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
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
            
            // Content
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(kSpacingXLarge),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _filteredSpecializations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(kSpacingXLarge * 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                ),
                                SizedBox(height: kSpacingMedium),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'No specializations yet' 
                                      : 'No matching specializations',
                                  style: TextStyle(
                                    fontSize: kFontSizeLarge,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: kSpacingSmall),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Click "Add Specialization" to create one' 
                                      : 'Try a different search term',
                                  style: TextStyle(
                                    fontSize: kFontSizeRegular,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(kSpacingMedium),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _displayedSpecializations.length,
                          itemBuilder: (context, index) {
                            final spec = _displayedSpecializations[index];
                            return _buildSpecializationCard(spec);
                          },
                        ),
            ),
            
            // Pagination
            if (!_isLoading && _displayedSpecializations.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalSpecializations,
                onPageChanged: _onPageChanged,
              ),
            ],
            
            SizedBox(height: kSpacingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: kSpacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: kFontSizeLarge + 4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: kFontSizeSmall,
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

  Widget _buildSpecializationCard(Map<String, dynamic> spec) {
    final isActive = spec['isActive'] ?? false;
    
    // Handle both Timestamp and ISO string formats
    DateTime? createdAtDate;
    DateTime? updatedAtDate;
    
    if (spec['createdAt'] != null) {
      if (spec['createdAt'] is Timestamp) {
        createdAtDate = (spec['createdAt'] as Timestamp).toDate();
      } else if (spec['createdAt'] is String) {
        createdAtDate = DateTime.tryParse(spec['createdAt']);
      }
    }
    
    if (spec['updatedAt'] != null) {
      if (spec['updatedAt'] is Timestamp) {
        updatedAtDate = (spec['updatedAt'] as Timestamp).toDate();
      } else if (spec['updatedAt'] is String) {
        updatedAtDate = DateTime.tryParse(spec['updatedAt']);
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(kSpacingMedium),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(kSpacingSmall),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.success.withOpacity(0.1) 
                    : AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              child: Icon(
                Icons.medical_services_outlined,
                color: isActive ? AppColors.success : AppColors.textSecondary,
                size: 28,
              ),
            ),
            
            SizedBox(width: kSpacingMedium),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spec['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: kFontSizeRegular + 2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: kSpacingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.success.withOpacity(0.1) 
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: kFontSizeSmall,
                            color: isActive ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    spec['description'] ?? 'No description',
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (createdAtDate != null || updatedAtDate != null) ...[
                    SizedBox(height: 4),
                    Text(
                      updatedAtDate != null
                          ? 'Updated: ${_formatDate(updatedAtDate)}'
                          : 'Created: ${_formatDate(createdAtDate!)}',
                      style: TextStyle(
                        fontSize: kFontSizeSmall,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(width: kSpacingMedium),
            
            // Actions
            Row(
              children: [
                // Toggle Active
                Switch(
                  value: isActive,
                  onChanged: (value) => _toggleActive(spec['id'], isActive),
                  activeColor: Color(0xFF8B5CF6), // Violet color
                ),
                
                SizedBox(width: kSpacingSmall),
                
                // Edit
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: () => _showAddEditDialog(specialization: spec),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
