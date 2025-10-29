import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

/// Service to fetch disease statistics by location
class DiseaseStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extract city/municipality from address
  /// Address format: "BARANGAY, CITY/MUNICIPALITY, PROVINCE, REGION"
  String? _extractCity(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      return parts[1]; // City/Municipality is the second part
    }
    return null;
  }

  /// Extract province from address
  String? _extractProvince(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      return parts[2]; // Province is the third part
    }
    return null;
  }

  /// Get most common disease in user's area
  Future<DiseaseStatistic?> getMostCommonDiseaseInArea(String userAddress) async {
    try {
      final city = _extractCity(userAddress);
      final province = _extractProvince(userAddress);

      if (city == null && province == null) {
        print('Could not extract location from address: $userAddress');
        return null;
      }

      // Get all users from the same city or province
      final usersSnapshot = await _firestore
          .collection('users')
          .get();

      // Filter users by location
      final userIdsInArea = <String>[];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final address = data['address'] as String?;
        
        if (address != null) {
          final userCity = _extractCity(address);
          final userProvince = _extractProvince(address);
          
          // Match by city first, then by province
          if ((city != null && userCity == city) ||
              (userProvince == province)) {
            userIdsInArea.add(doc.id);
          }
        }
      }

      if (userIdsInArea.isEmpty) {
        print('No users found in area');
        return null;
      }

      print('Found ${userIdsInArea.length} users in area: $city, $province');

      // Get all assessment results for users in the area
      // Firestore 'in' query has a limit of 10, so we need to batch
      final allDetections = <Detection>[];
      
      // Process in batches of 10
      for (var i = 0; i < userIdsInArea.length; i += 10) {
        final batch = userIdsInArea.skip(i).take(10).toList();
        
        final assessmentsSnapshot = await _firestore
            .collection('assessmentResults')
            .where('userId', whereIn: batch)
            .get();

        for (var doc in assessmentsSnapshot.docs) {
          final assessment = AssessmentResult.fromMap(doc.data(), doc.id);
          
          // Extract all detections
          for (var detectionResult in assessment.detectionResults) {
            allDetections.addAll(detectionResult.detections);
          }
        }
      }

      if (allDetections.isEmpty) {
        print('No detections found in area');
        return null;
      }

      // Count occurrences of each disease
      final diseaseCount = <String, int>{};
      for (var detection in allDetections) {
        final disease = detection.label;
        diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
      }

      // Find the most common disease
      String? mostCommonDisease;
      int maxCount = 0;
      
      diseaseCount.forEach((disease, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonDisease = disease;
        }
      });

      if (mostCommonDisease == null) {
        return null;
      }

      // Calculate percentage
      final totalDetections = allDetections.length;
      final percentage = (maxCount / totalDetections * 100);

      print('Most common disease in $city: $mostCommonDisease ($maxCount/$totalDetections = ${percentage.toStringAsFixed(1)}%)');

      return DiseaseStatistic(
        diseaseName: mostCommonDisease!,
        count: maxCount,
        totalCases: totalDetections,
        percentage: percentage,
        location: city ?? province ?? 'your area',
      );
    } catch (e) {
      print('Error getting disease statistics: $e');
      return null;
    }
  }
}

/// Model for disease statistics
class DiseaseStatistic {
  final String diseaseName;
  final int count;
  final int totalCases;
  final double percentage;
  final String location;

  DiseaseStatistic({
    required this.diseaseName,
    required this.count,
    required this.totalCases,
    required this.percentage,
    required this.location,
  });
}
