import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user/assessment_result_model.dart';
import '../shared/address_service.dart';

/// Model for disease statistics by area
class DiseaseAreaStatistic {
  final String diseaseName;
  final int casesCount;
  final String barangay;
  final String municipality;
  final String province;
  final String region;
  final String? petType; // 'dog', 'cat', or null for mixed
  final DateTime? firstDetection;
  final DateTime? lastDetection;

  const DiseaseAreaStatistic({
    required this.diseaseName,
    required this.casesCount,
    required this.barangay,
    required this.municipality,
    required this.province,
    required this.region,
    this.petType,
    this.firstDetection,
    this.lastDetection,
  });

  String get fullAddress => '$barangay, $municipality, $province, $region';

  Map<String, dynamic> toJson() => {
        'diseaseName': diseaseName,
        'casesCount': casesCount,
        'barangay': barangay,
        'municipality': municipality,
        'province': province,
        'region': region,
        'petType': petType,
        'fullAddress': fullAddress,
        'firstDetection': firstDetection?.toIso8601String(),
        'lastDetection': lastDetection?.toIso8601String(),
      };
}

/// Service for disease area statistics
class DiseaseAreaStatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extract address components from formatted address
  /// Address format: "BARANGAY, CITY/MUNICIPALITY, PROVINCE, REGION"
  static Map<String, String> _extractAddressComponents(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    
    // Handle case where address might not have all 4 parts
    // Provide defaults for missing parts
    return {
      'barangay': parts.length > 0 && parts[0].isNotEmpty ? parts[0] : 'Unknown',
      'municipality': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'Unknown',
      'province': parts.length > 2 && parts[2].isNotEmpty ? parts[2] : 'Unknown',
      'region': parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'Unknown',
    };
  }

  /// Get all disease statistics grouped by area
  static Future<List<DiseaseAreaStatistic>> getDiseaseStatisticsByArea({
    String? filterProvince,
    String? filterMunicipality,
    String? filterBarangay,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('🔍 Fetching disease statistics by area...');
      print('🔍 Filters - Province: $filterProvince, Municipality: $filterMunicipality, Barangay: $filterBarangay');

      // Get all users with addresses
      final usersSnapshot = await _firestore.collection('users').get();
      print('📊 Total users in database: ${usersSnapshot.docs.length}');

      // Map user IDs to their addresses
      final userAddresses = <String, String>{};
      int usersWithoutAddress = 0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final address = data['address'] as String?;
        if (address != null && address.isNotEmpty) {
          userAddresses[doc.id] = address;
          print('✓ User ${doc.id}: $address');
        } else {
          usersWithoutAddress++;
        }
      }

      print('📍 Found ${userAddresses.length} users with addresses');
      print('⚠️  Found $usersWithoutAddress users without addresses');

      // Get all assessment results
      Query query = _firestore.collection('assessment_results');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final assessmentsSnapshot = await query.get();
      print('📊 Found ${assessmentsSnapshot.docs.length} assessment results in database');

      // Map to store disease counts by location
      // Key: "disease|barangay|municipality|province|region"
      final Map<String, _DiseaseLocationData> diseaseLocationMap = {};
      int processedAssessments = 0;
      int assessmentsWithoutAddress = 0;
      int assessmentsWithoutDetections = 0;
      int totalDetections = 0;

      for (var doc in assessmentsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('⚠️  Assessment ${doc.id} has no data');
            continue;
          }
          
          final assessment = AssessmentResult.fromMap(data, doc.id);
          final userAddress = userAddresses[assessment.userId];

          if (userAddress == null || userAddress.isEmpty) {
            assessmentsWithoutAddress++;
            print('⚠️  Assessment ${doc.id} - User ${assessment.userId} has no address');
            continue;
          }

          if (assessment.detectionResults.isEmpty) {
            assessmentsWithoutDetections++;
            print('⚠️  Assessment ${doc.id} has no detection results');
            continue;
          }

          final addressComponents = _extractAddressComponents(userAddress);
          final barangay = addressComponents['barangay']!;
          final municipality = addressComponents['municipality']!;
          final province = addressComponents['province']!;
          final region = addressComponents['region']!;

          print('📍 Processing assessment ${doc.id}: $barangay, $municipality, $province, $region');

          // Apply filters
          if (filterProvince != null && 
              province.toLowerCase() != filterProvince.toLowerCase()) {
            print('   ⏭️  Skipped: Province filter mismatch');
            continue;
          }
          if (filterMunicipality != null && 
              municipality.toLowerCase() != filterMunicipality.toLowerCase()) {
            print('   ⏭️  Skipped: Municipality filter mismatch');
            continue;
          }
          if (filterBarangay != null && 
              barangay.toLowerCase() != filterBarangay.toLowerCase()) {
            print('   ⏭️  Skipped: Barangay filter mismatch');
            continue;
          }

          // Find the highest confidence detection across all detection results
          Detection? highestDetection;
          double highestConfidence = 0.0;
          
          for (var detectionResult in assessment.detectionResults) {
            for (var detection in detectionResult.detections) {
              totalDetections++;
              if (detection.confidence > highestConfidence) {
                highestConfidence = detection.confidence;
                highestDetection = detection;
              }
            }
          }

          // Only count the highest confidence detection per assessment
          if (highestDetection != null) {
            final disease = highestDetection.label;
            final petType = assessment.petType.toLowerCase(); // 'dog' or 'cat'
            final key = '$disease|$barangay|$municipality|$province|$region|$petType';

            if (diseaseLocationMap.containsKey(key)) {
              diseaseLocationMap[key]!.increment(assessment.createdAt);
            } else {
              diseaseLocationMap[key] = _DiseaseLocationData(
                disease: disease,
                barangay: barangay,
                municipality: municipality,
                province: province,
                region: region,
                petType: petType,
                firstDate: assessment.createdAt,
              );
            }
            print('   ✓ Counted highest confidence detection: $disease for $petType (${(highestConfidence * 100).toStringAsFixed(1)}%)');
          }
          processedAssessments++;
        } catch (e) {
          print('❌ Error processing assessment ${doc.id}: $e');
        }
      }

      print('📊 Summary:');
      print('   - Processed assessments: $processedAssessments');
      print('   - Assessments without address: $assessmentsWithoutAddress');
      print('   - Assessments without detections: $assessmentsWithoutDetections');
      print('   - Total detections found: $totalDetections');

      // Convert to list of statistics
      final statistics = diseaseLocationMap.values
          .map((data) => DiseaseAreaStatistic(
                diseaseName: data.disease,
                casesCount: data.count,
                barangay: data.barangay,
                municipality: data.municipality,
                province: data.province,
                region: data.region,
                petType: data.petType,
                firstDetection: data.firstDate,
                lastDetection: data.lastDate,
              ))
          .toList();

      // Sort by cases count (descending)
      statistics.sort((a, b) => b.casesCount.compareTo(a.casesCount));

      print('✅ Processed ${statistics.length} disease-area combinations');

      return statistics;
    } catch (e) {
      print('❌ Error fetching disease statistics: $e');
      rethrow;
    }
  }

  /// Get top diseases across all areas
  static Future<List<DiseaseAreaStatistic>> getTopDiseases({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allStats = await getDiseaseStatisticsByArea(
      startDate: startDate,
      endDate: endDate,
    );

    // Group by disease name and sum cases
    final Map<String, int> diseaseTotals = {};
    final Map<String, Set<String>> diseaseLocations = {};

    for (var stat in allStats) {
      diseaseTotals[stat.diseaseName] = 
          (diseaseTotals[stat.diseaseName] ?? 0) + stat.casesCount;
      
      diseaseLocations[stat.diseaseName] ??= {};
      diseaseLocations[stat.diseaseName]!.add(stat.fullAddress);
    }

    // Create aggregated statistics
    final topDiseases = diseaseTotals.entries
        .map((entry) => DiseaseAreaStatistic(
              diseaseName: entry.key,
              casesCount: entry.value,
              barangay: 'Multiple',
              municipality: 'Multiple',
              province: 'Multiple',
              region: 'Multiple',
            ))
        .toList();

    topDiseases.sort((a, b) => b.casesCount.compareTo(a.casesCount));

    return topDiseases.take(limit).toList();
  }

  /// Get unique list of regions from Philippine address JSON
  static Future<List<Map<String, String>>> getRegions() async {
    try {
      final addressService = AddressService();
      await addressService.loadAddressData();
      
      final regions = await addressService.getRegions();
      return regions.map((r) => {
        'code': r.code,
        'name': r.name,
      }).toList();
    } catch (e) {
      print('Error loading regions: $e');
      return [];
    }
  }

  /// Get unique list of provinces from Philippine address JSON
  static Future<List<String>> getProvinces({String? regionCode}) async {
    try {
      final addressService = AddressService();
      await addressService.loadAddressData();
      
      if (regionCode != null) {
        // Get provinces for specific region
        final provincesInRegion = await addressService.getProvinces(regionCode);
        final sortedList = provincesInRegion.map((p) => p.name).toList()..sort();
        return sortedList;
      } else {
        // Get all provinces across all regions
        final regions = await addressService.getRegions();
        final provinces = <String>{};

        for (var region in regions) {
          final provincesInRegion = await addressService.getProvinces(region.code);
          for (var province in provincesInRegion) {
            provinces.add(province.name);
          }
        }

        final sortedList = provinces.toList()..sort();
        return sortedList;
      }
    } catch (e) {
      print('Error loading provinces: $e');
      return [];
    }
  }

  /// Get unique list of municipalities for a province from Philippine address JSON
  static Future<List<String>> getMunicipalities(String province) async {
    try {
      final addressService = AddressService();
      await addressService.loadAddressData();
      
      final regions = await addressService.getRegions();
      
      // Find the province in all regions
      for (var region in regions) {
        final provincesInRegion = await addressService.getProvinces(region.code);
        
        for (var prov in provincesInRegion) {
          if (prov.name.toLowerCase() == province.toLowerCase()) {
            final municipalities = await addressService.getMunicipalities(
              region.code,
              prov.name,
            );
            
            final municipalityNames = municipalities.map((m) => m.name).toList()..sort();
            return municipalityNames;
          }
        }
      }

      return [];
    } catch (e) {
      print('Error loading municipalities: $e');
      return [];
    }
  }

  /// Get unique list of barangays for a province and municipality from Philippine address JSON
  static Future<List<String>> getBarangays(String province, String municipality) async {
    try {
      final addressService = AddressService();
      await addressService.loadAddressData();
      
      final regions = await addressService.getRegions();
      
      // Find the province and municipality in all regions
      for (var region in regions) {
        final provincesInRegion = await addressService.getProvinces(region.code);
        
        for (var prov in provincesInRegion) {
          if (prov.name.toLowerCase() == province.toLowerCase()) {
            final barangays = await addressService.getBarangays(
              region.code,
              prov.name,
              municipality,
            );
            
            final barangayNames = barangays.map((b) => b.name).toList()..sort();
            return barangayNames;
          }
        }
      }

      return [];
    } catch (e) {
      print('Error loading barangays: $e');
      return [];
    }
  }

  /// Get unique list of diseases
  static Future<List<String>> getDiseases() async {
    final assessmentsSnapshot = 
        await _firestore.collection('assessment_results').get();
    final diseases = <String>{};

    for (var doc in assessmentsSnapshot.docs) {
      try {
        final assessment = AssessmentResult.fromMap(doc.data(), doc.id);
        for (var detectionResult in assessment.detectionResults) {
          for (var detection in detectionResult.detections) {
            diseases.add(detection.label);
          }
        }
      } catch (e) {
        // Skip invalid documents
      }
    }

    final sortedList = diseases.toList()..sort();
    return sortedList;
  }
}

/// Helper class to track disease location data
class _DiseaseLocationData {
  final String disease;
  final String barangay;
  final String municipality;
  final String province;
  final String region;
  final String? petType; // 'dog', 'cat', or null for mixed
  int count = 1;
  DateTime firstDate;
  DateTime? lastDate;

  _DiseaseLocationData({
    required this.disease,
    required this.barangay,
    required this.municipality,
    required this.province,
    required this.region,
    this.petType,
    required this.firstDate,
  }) {
    lastDate = firstDate;
  }

  void increment(DateTime date) {
    count++;
    if (date.isBefore(firstDate)) {
      firstDate = date;
    }
    if (lastDate == null || date.isAfter(lastDate!)) {
      lastDate = date;
    }
  }
}
