import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

/// Service to fetch disease statistics by location
class DiseaseStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extract barangay from address
  /// Address format: "BARANGAY, CITY/MUNICIPALITY, PROVINCE, REGION"
  String? _extractBarangay(String address) {
    if (address.isEmpty) return null;
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].trim(); // Barangay is the first part
    }
    return null;
  }

  /// Extract city/municipality from address
  /// Address format: "BARANGAY, CITY/MUNICIPALITY, PROVINCE, REGION"
  String? _extractCity(String address) {
    if (address.isEmpty) return null;
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return parts[1].trim(); // City/Municipality is the second part
    }
    return null;
  }

  /// Get most common diseases in user's area, separated by species
  Future<AreaDiseaseStatistics?> getMostCommonDiseaseInArea(String userAddress) async {
    try {
      print('\n========================================');
      print('🔍 AREA STATISTICS DEBUG START');
      print('========================================');
      print('📍 Current user address: $userAddress');
      
      final barangay = _extractBarangay(userAddress);
      final city = _extractCity(userAddress);

      print('📍 Extracted Barangay: $barangay');
      print('📍 Extracted City: $city');

      if (barangay == null || city == null) {
        print('❌ Could not extract barangay and city from address: $userAddress');
        print('========================================\n');
        return null;
      }

      print('\n🔎 Step 1: Fetching all users from Firestore...');
      // Get all users from the same barangay and city
      final usersSnapshot = await _firestore
          .collection('users')
          .get();

      print('📊 Total users in database: ${usersSnapshot.docs.length}');

      // Filter users by barangay and city
      final userIdsInArea = <String>[];
      print('\n🔎 Step 2: Filtering users by location (STRICT MATCHING)...');
      print('   🎯 Target Barangay: "$barangay" (lowercase: "${barangay.toLowerCase()}")');
      print('   🎯 Target City: "$city" (lowercase: "${city.toLowerCase()}")');
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final uid = doc.id;
        final address = data['address'] as String?;
        
        if (address != null && address.isNotEmpty) {
          final userBarangay = _extractBarangay(address);
          final userCity = _extractCity(address);
          
          print('\n   👤 User UID: $uid');
          print('      Full Address: "$address"');
          print('      Extracted Barangay: "$userBarangay"');
          print('      Extracted City: "$userCity"');
          
          // STRICT match: both barangay and city must match exactly (case-insensitive)
          // Also trim whitespace to avoid false negatives
          if (userBarangay != null && userCity != null) {
            final normalizedUserBarangay = userBarangay.trim().toLowerCase();
            final normalizedUserCity = userCity.trim().toLowerCase();
            final normalizedTargetBarangay = barangay.trim().toLowerCase();
            final normalizedTargetCity = city.trim().toLowerCase();
            
            print('      Normalized Barangay: "$normalizedUserBarangay"');
            print('      Normalized City: "$normalizedUserCity"');
            print('      Barangay Match: ${normalizedUserBarangay == normalizedTargetBarangay}');
            print('      City Match: ${normalizedUserCity == normalizedTargetCity}');
            
            if (normalizedUserBarangay == normalizedTargetBarangay &&
                normalizedUserCity == normalizedTargetCity) {
              userIdsInArea.add(uid);
              print('      ✅ EXACT MATCH! Added to area list');
            } else {
              print('      ❌ No match - Barangay or City differs');
            }
          } else {
            print('      ❌ Could not extract barangay or city from address');
          }
        } else {
          print('\n   👤 User UID: $uid - No address set');
        }
      }

      print('\n========================================');
      print('📊 STEP 2 SUMMARY:');
      print('   Total users scanned: ${usersSnapshot.docs.length}');
      print('   Users matching area: ${userIdsInArea.length}');
      print('   Matching criteria:');
      print('      - Barangay (case-insensitive): "$barangay"');
      print('      - City/Municipality (case-insensitive): "$city"');
      
      if (userIdsInArea.isNotEmpty) {
        print('   📋 Matched User IDs:');
        for (var uid in userIdsInArea) {
          print('      - $uid');
        }
      }
      print('========================================');

      if (userIdsInArea.isEmpty) {
        print('\n❌ RESULT: No users found in area: $barangay, $city');
        print('   This means no other users share the exact same Barangay AND City.');
        print('========================================\n');
        return null;
      }

      // Get all assessment results for users in the area
      // Separate detections by species (petType)
      final dogDetections = <Detection>[];
      final catDetections = <Detection>[];
      int totalAssessmentsFound = 0;
      
      print('\n🔎 Step 3: Fetching assessments for users in area...');
      
      // Process in batches of 10 (Firestore 'in' query limit)
      for (var i = 0; i < userIdsInArea.length; i += 10) {
        final batch = userIdsInArea.skip(i).take(10).toList();
        print('\n📦 Batch ${(i ~/ 10) + 1}: Querying assessments for ${batch.length} users');
        print('   Query: collection("assessment_results").where("userId", whereIn: $batch)');
        
        final assessmentsSnapshot = await _firestore
            .collection('assessment_results')
            .where('userId', whereIn: batch)
            .get();

        print('   📊 Found ${assessmentsSnapshot.docs.length} assessments in this batch');
        totalAssessmentsFound += assessmentsSnapshot.docs.length;

        for (var doc in assessmentsSnapshot.docs) {
          try {
            final data = doc.data();
            print('\n   📄 Assessment ID: ${doc.id}');
            print('      User ID: ${data['userId']}');
            print('      Pet Name: ${data['petName']}');
            print('      Pet Type: ${data['petType']}');
            print('      Detection Results Count: ${(data['detectionResults'] as List?)?.length ?? 0}');
            
            final assessment = AssessmentResult.fromMap(data, doc.id);
            final petType = assessment.petType.toLowerCase();
            
            // Extract only the HIGHEST confidence detection per image
            for (var detectionResult in assessment.detectionResults) {
              print('      🖼️ Image: ${detectionResult.imageUrl}');
              print('      🔬 Total detections in this image: ${detectionResult.detections.length}');
              
              if (detectionResult.detections.isEmpty) {
                print('      ⚠️ No detections found in this image');
                continue;
              }
              
              // Show all detections for debugging
              for (var detection in detectionResult.detections) {
                print('         - Disease: ${detection.label} (Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%)');
              }
              
              // Find the detection with highest confidence
              Detection highestConfidenceDetection = detectionResult.detections.first;
              for (var detection in detectionResult.detections) {
                if (detection.confidence > highestConfidenceDetection.confidence) {
                  highestConfidenceDetection = detection;
                }
              }
              
              print('      🏆 Highest confidence: ${highestConfidenceDetection.label} (${(highestConfidenceDetection.confidence * 100).toStringAsFixed(1)}%)');
              
              // Only add the highest confidence detection to statistics
              if (petType.contains('dog')) {
                dogDetections.add(highestConfidenceDetection);
                print('      ✅ Added to dog statistics');
              } else if (petType.contains('cat')) {
                catDetections.add(highestConfidenceDetection);
                print('      ✅ Added to cat statistics');
              } else {
                print('      ⚠️ Unknown pet type: $petType');
              }
            }
          } catch (e) {
            print('   ❌ Error processing assessment ${doc.id}: $e');
          }
        }
      }
      
      print('\n========================================');
      print('📊 STEP 3 SUMMARY:');
      print('   Total assessments found: $totalAssessmentsFound');
      print('   Dog detections (highest confidence per image): ${dogDetections.length}');
      print('   Cat detections (highest confidence per image): ${catDetections.length}');
      print('   Note: Only the highest confidence detection per image is counted');
      print('========================================');

      final location = '$barangay, $city';

      print('\n🔎 Step 4: Calculating top 5 diseases per species...');
      
      // Calculate top 5 diseases for dogs
      final dogStatistics = <DiseaseStatistic>[];
      if (dogDetections.isNotEmpty) {
        print('\n🐶 Processing dog statistics...');
        dogStatistics.addAll(_calculateTopDiseases(dogDetections, 'Dog'));
      } else {
        print('\n🐶 No dog detections found');
      }

      // Calculate top 5 diseases for cats
      final catStatistics = <DiseaseStatistic>[];
      if (catDetections.isNotEmpty) {
        print('\n🐱 Processing cat statistics...');
        catStatistics.addAll(_calculateTopDiseases(catDetections, 'Cat'));
      } else {
        print('\n🐱 No cat detections found');
      }

      if (dogStatistics.isEmpty && catStatistics.isEmpty) {
        print('\n❌ No disease statistics available');
        print('========================================\n');
        return null;
      }

      print('\n✅ AREA STATISTICS COMPLETE!');
      print('   Dogs: ${dogStatistics.length} diseases found');
      print('   Cats: ${catStatistics.length} diseases found');
      print('========================================\n');

      return AreaDiseaseStatistics(
        dogStatistics: dogStatistics,
        catStatistics: catStatistics,
        location: location,
      );
    } catch (e) {
      print('\n❌ ERROR in getMostCommonDiseaseInArea: $e');
      print('Stack trace: ${StackTrace.current}');
      print('========================================\n');
      return null;
    }
  }

  /// Calculate top 5 most common diseases from a list of detections
  List<DiseaseStatistic> _calculateTopDiseases(
    List<Detection> detections,
    String species,
    {int limit = 5}
  ) {
    if (detections.isEmpty) {
      print('   ⚠️ No detections provided for $species');
      return [];
    }

    print('   📊 Analyzing ${detections.length} detections for $species...');
    
    // Count occurrences of each disease
    final diseaseCount = <String, int>{};
    for (var detection in detections) {
      final disease = detection.label;
      diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
    }

    print('   📋 Disease counts:');
    diseaseCount.forEach((disease, count) {
      print('      - $disease: $count');
    });

    // Sort diseases by count (descending) and take top 5
    final sortedDiseases = diseaseCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topDiseases = sortedDiseases.take(limit).toList();
    
    if (topDiseases.isEmpty) {
      print('   ❌ Could not determine disease statistics');
      return [];
    }

    final totalDetections = detections.length;
    final statistics = <DiseaseStatistic>[];
    
    print('   ✅ Top ${topDiseases.length} diseases:');
    for (var entry in topDiseases) {
      final percentage = (entry.value / totalDetections * 100);
      print('      ${statistics.length + 1}. ${entry.key}: ${entry.value} cases (${percentage.toStringAsFixed(1)}%)');
      
      statistics.add(DiseaseStatistic(
        diseaseName: entry.key,
        count: entry.value,
        totalCases: totalDetections,
        percentage: percentage,
        species: species,
      ));
    }

    return statistics;
  }
}

/// Model for area disease statistics (combines dog and cat statistics)
class AreaDiseaseStatistics {
  final List<DiseaseStatistic> dogStatistics;
  final List<DiseaseStatistic> catStatistics;
  final String location;

  AreaDiseaseStatistics({
    required this.dogStatistics,
    required this.catStatistics,
    required this.location,
  });
}

/// Model for disease statistics
class DiseaseStatistic {
  final String diseaseName;
  final int count;
  final int totalCases;
  final double percentage;
  final String species; // 'Dog' or 'Cat'

  DiseaseStatistic({
    required this.diseaseName,
    required this.count,
    required this.totalCases,
    required this.percentage,
    required this.species,
  });
}
