import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for loading and parsing Philippine address data
class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  Map<String, dynamic>? _addressData;
  bool _isLoaded = false;

  /// Load the address data from JSON file
  Future<void> loadAddressData() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/philippine_provinces_cities_municipalities_and_barangays_2019v2.json',
      );
      _addressData = json.decode(jsonString);
      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load address data: $e');
    }
  }

  /// Ensure data is loaded before accessing
  Future<void> _ensureLoaded() async {
    if (!_isLoaded) {
      await loadAddressData();
    }
  }

  /// Get all regions
  Future<List<RegionData>> getRegions() async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    List<RegionData> regions = [];
    _addressData!.forEach((regionCode, regionInfo) {
      if (regionInfo is Map<String, dynamic>) {
        regions.add(RegionData(
          code: regionCode,
          name: regionInfo['region_name'] ?? '',
        ));
      }
    });

    // Sort regions by code
    regions.sort((a, b) => a.code.compareTo(b.code));
    return regions;
  }

  /// Get provinces for a specific region
  Future<List<ProvinceData>> getProvinces(String regionCode) async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    final regionData = _addressData![regionCode];
    if (regionData == null) return [];

    final provinceList = regionData['province_list'];
    if (provinceList == null) return [];

    List<ProvinceData> provinces = [];
    provinceList.forEach((provinceName, provinceInfo) {
      provinces.add(ProvinceData(
        name: provinceName,
      ));
    });

    // Sort alphabetically
    provinces.sort((a, b) => a.name.compareTo(b.name));
    return provinces;
  }

  /// Get municipalities for a specific region and province
  Future<List<MunicipalityData>> getMunicipalities(
    String regionCode,
    String provinceName,
  ) async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    final regionData = _addressData![regionCode];
    if (regionData == null) return [];

    final provinceList = regionData['province_list'];
    if (provinceList == null) return [];

    final provinceData = provinceList[provinceName];
    if (provinceData == null) return [];

    final municipalityList = provinceData['municipality_list'];
    if (municipalityList == null) return [];

    List<MunicipalityData> municipalities = [];
    municipalityList.forEach((municipalityName, municipalityInfo) {
      municipalities.add(MunicipalityData(
        name: municipalityName,
      ));
    });

    // Sort alphabetically
    municipalities.sort((a, b) => a.name.compareTo(b.name));
    return municipalities;
  }

  /// Get barangays for a specific region, province, and municipality
  Future<List<BarangayData>> getBarangays(
    String regionCode,
    String provinceName,
    String municipalityName,
  ) async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    final regionData = _addressData![regionCode];
    if (regionData == null) return [];

    final provinceList = regionData['province_list'];
    if (provinceList == null) return [];

    final provinceData = provinceList[provinceName];
    if (provinceData == null) return [];

    final municipalityList = provinceData['municipality_list'];
    if (municipalityList == null) return [];

    final municipalityData = municipalityList[municipalityName];
    if (municipalityData == null) return [];

    final barangayList = municipalityData['barangay_list'];
    if (barangayList == null || barangayList is! List) return [];

    List<BarangayData> barangays = [];
    for (var barangayName in barangayList) {
      if (barangayName is String) {
        barangays.add(BarangayData(name: barangayName));
      }
    }

    // Sort alphabetically
    barangays.sort((a, b) => a.name.compareTo(b.name));
    return barangays;
  }

  /// Format complete address
  String formatAddress({
    required String region,
    required String province,
    required String municipality,
    required String barangay,
  }) {
    return '$barangay, $municipality, $province, $region';
  }
}

/// Region data model
class RegionData {
  final String code;
  final String name;

  RegionData({
    required this.code,
    required this.name,
  });

  @override
  String toString() => name;
}

/// Province data model
class ProvinceData {
  final String name;

  ProvinceData({
    required this.name,
  });

  @override
  String toString() => name;
}

/// Municipality data model
class MunicipalityData {
  final String name;

  MunicipalityData({
    required this.name,
  });

  @override
  String toString() => name;
}

/// Barangay data model
class BarangayData {
  final String name;

  BarangayData({
    required this.name,
  });

  @override
  String toString() => name;
}
