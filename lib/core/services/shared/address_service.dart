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

    try {
      final regionData = _addressData![regionCode];
      if (regionData == null || regionData is! Map) return [];

      final provinceList = regionData['province_list'];
      if (provinceList == null || provinceList is! Map) return [];

      List<ProvinceData> provinces = [];
      provinceList.forEach((provinceName, provinceInfo) {
        if (provinceName is String) {
          provinces.add(ProvinceData(
            name: provinceName,
          ));
        }
      });

      // Sort alphabetically
      provinces.sort((a, b) => a.name.compareTo(b.name));
      return provinces;
    } catch (e) {
      print('Error loading provinces: $e');
      return [];
    }
  }

  /// Get municipalities for a specific region and province
  Future<List<MunicipalityData>> getMunicipalities(
    String regionCode,
    String provinceName,
  ) async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    try {
      final regionData = _addressData![regionCode];
      if (regionData == null || regionData is! Map) return [];

      final provinceList = regionData['province_list'];
      if (provinceList == null || provinceList is! Map) return [];

      final provinceData = provinceList[provinceName];
      if (provinceData == null || provinceData is! Map) return [];

      final municipalityList = provinceData['municipality_list'];
      if (municipalityList == null || municipalityList is! Map) return [];

      List<MunicipalityData> municipalities = [];
      municipalityList.forEach((municipalityName, municipalityInfo) {
        if (municipalityName is String) {
          municipalities.add(MunicipalityData(
            name: municipalityName,
          ));
        }
      });

      // Sort alphabetically
      municipalities.sort((a, b) => a.name.compareTo(b.name));
      return municipalities;
    } catch (e) {
      print('Error loading municipalities: $e');
      return [];
    }
  }

  /// Get barangays for a specific region, province, and municipality
  Future<List<BarangayData>> getBarangays(
    String regionCode,
    String provinceName,
    String municipalityName,
  ) async {
    await _ensureLoaded();
    
    if (_addressData == null) return [];

    try {
      final regionData = _addressData![regionCode];
      if (regionData == null || regionData is! Map) return [];

      final provinceList = regionData['province_list'];
      if (provinceList == null || provinceList is! Map) return [];

      final provinceData = provinceList[provinceName];
      if (provinceData == null || provinceData is! Map) return [];

      final municipalityList = provinceData['municipality_list'];
      if (municipalityList == null || municipalityList is! Map) return [];

      final municipalityData = municipalityList[municipalityName];
      if (municipalityData == null || municipalityData is! Map) return [];

      final barangayList = municipalityData['barangay_list'];
      if (barangayList == null) return [];

      // Handle barangay_list as a List
      if (barangayList is List) {
        List<BarangayData> barangays = [];
        for (var item in barangayList) {
          if (item is String) {
            barangays.add(BarangayData(name: item));
          }
        }
        // Sort alphabetically
        barangays.sort((a, b) => a.name.compareTo(b.name));
        return barangays;
      }

      return [];
    } catch (e) {
      print('Error loading barangays: $e');
      return [];
    }
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
