import 'package:flutter/material.dart';
import 'package:pawsense/core/services/shared/address_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

/// Modal for selecting structured Philippine address
class AddressSelectorModal extends StatefulWidget {
  final String? initialRegion;
  final String? initialProvince;
  final String? initialMunicipality;
  final String? initialBarangay;

  const AddressSelectorModal({
    super.key,
    this.initialRegion,
    this.initialProvince,
    this.initialMunicipality,
    this.initialBarangay,
  });

  @override
  State<AddressSelectorModal> createState() => _AddressSelectorModalState();
}

class _AddressSelectorModalState extends State<AddressSelectorModal> {
  final _addressService = AddressService();

  List<RegionData> _regions = [];
  List<ProvinceData> _provinces = [];
  List<MunicipalityData> _municipalities = [];
  List<BarangayData> _barangays = [];

  RegionData? _selectedRegion;
  ProvinceData? _selectedProvince;
  MunicipalityData? _selectedMunicipality;
  BarangayData? _selectedBarangay;

  String? _selectedRegionCode;

  bool _isLoadingRegions = true;
  bool _isLoadingProvinces = false;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _addressService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load regions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadProvinces(String regionCode) async {
    setState(() {
      _isLoadingProvinces = true;
      _provinces = [];
      _municipalities = [];
      _barangays = [];
      _selectedProvince = null;
      _selectedMunicipality = null;
      _selectedBarangay = null;
    });

    try {
      final provinces = await _addressService.getProvinces(regionCode);
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load provinces: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMunicipalities(String regionCode, String provinceName) async {
    setState(() {
      _isLoadingMunicipalities = true;
      _municipalities = [];
      _barangays = [];
      _selectedMunicipality = null;
      _selectedBarangay = null;
    });

    try {
      final municipalities = await _addressService.getMunicipalities(
        regionCode,
        provinceName,
      );
      setState(() {
        _municipalities = municipalities;
        _isLoadingMunicipalities = false;
      });
    } catch (e) {
      setState(() => _isLoadingMunicipalities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load municipalities: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadBarangays(
    String regionCode,
    String provinceName,
    String municipalityName,
  ) async {
    setState(() {
      _isLoadingBarangays = true;
      _barangays = [];
      _selectedBarangay = null;
    });

    try {
      final barangays = await _addressService.getBarangays(
        regionCode,
        provinceName,
        municipalityName,
      );
      setState(() {
        _barangays = barangays;
        _isLoadingBarangays = false;
      });
    } catch (e) {
      setState(() => _isLoadingBarangays = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load barangays: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onRegionChanged(RegionData? region) {
    if (region != null) {
      setState(() {
        _selectedRegion = region;
        _selectedRegionCode = region.code;
      });
      _loadProvinces(region.code);
    }
  }

  void _onProvinceChanged(ProvinceData? province) {
    if (province != null && _selectedRegionCode != null) {
      setState(() {
        _selectedProvince = province;
      });
      _loadMunicipalities(_selectedRegionCode!, province.name);
    }
  }

  void _onMunicipalityChanged(MunicipalityData? municipality) {
    if (municipality != null && _selectedRegionCode != null && _selectedProvince != null) {
      setState(() {
        _selectedMunicipality = municipality;
      });
      _loadBarangays(
        _selectedRegionCode!,
        _selectedProvince!.name,
        municipality.name,
      );
    }
  }

  void _onBarangayChanged(BarangayData? barangay) {
    setState(() {
      _selectedBarangay = barangay;
    });
  }

  void _confirmSelection() {
    if (_selectedRegion == null ||
        _selectedProvince == null ||
        _selectedMunicipality == null ||
        _selectedBarangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all address fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final formattedAddress = _addressService.formatAddress(
      region: _selectedRegion!.name,
      province: _selectedProvince!.name,
      municipality: _selectedMunicipality!.name,
      barangay: _selectedBarangay!.name,
    );

    Navigator.of(context).pop({
      'region': _selectedRegion!.name,
      'province': _selectedProvince!.name,
      'municipality': _selectedMunicipality!.name,
      'barangay': _selectedBarangay!.name,
      'formattedAddress': formattedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Region Dropdown
                    _buildDropdown<RegionData>(
                      label: 'Region',
                      items: _regions,
                      selectedItem: _selectedRegion,
                      onChanged: _onRegionChanged,
                      isLoading: _isLoadingRegions,
                      hint: 'Select Region',
                    ),

                    const SizedBox(height: 16),

                    // Province Dropdown
                    _buildDropdown<ProvinceData>(
                      label: 'Province',
                      items: _provinces,
                      selectedItem: _selectedProvince,
                      onChanged: _onProvinceChanged,
                      isLoading: _isLoadingProvinces,
                      hint: 'Select Province',
                      enabled: _selectedRegion != null,
                    ),

                    const SizedBox(height: 16),

                    // Municipality Dropdown
                    _buildDropdown<MunicipalityData>(
                      label: 'Municipality/City',
                      items: _municipalities,
                      selectedItem: _selectedMunicipality,
                      onChanged: _onMunicipalityChanged,
                      isLoading: _isLoadingMunicipalities,
                      hint: 'Select Municipality/City',
                      enabled: _selectedProvince != null,
                    ),

                    const SizedBox(height: 16),

                    // Barangay Dropdown
                    _buildDropdown<BarangayData>(
                      label: 'Barangay',
                      items: _barangays,
                      selectedItem: _selectedBarangay,
                      onChanged: _onBarangayChanged,
                      isLoading: _isLoadingBarangays,
                      hint: 'Select Barangay',
                      enabled: _selectedMunicipality != null,
                    ),

                    const SizedBox(height: 24),

                    // Preview
                    if (_selectedRegion != null ||
                        _selectedProvince != null ||
                        _selectedMunicipality != null ||
                        _selectedBarangay != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Address:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                _selectedBarangay?.name,
                                _selectedMunicipality?.name,
                                _selectedProvince?.name,
                                _selectedRegion?.name,
                              ].where((e) => e != null).join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgsecond,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textTertiary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kButtonRadius),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kButtonRadius),
                        ),
                      ),
                      child: const Text('Confirm'),
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

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required ValueChanged<T?> onChanged,
    required bool isLoading,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.bgsecond,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withOpacity(0.5),
            ),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    isExpanded: true,
                    value: selectedItem,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          item.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: enabled ? onChanged : null,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    dropdownColor: AppColors.white,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
