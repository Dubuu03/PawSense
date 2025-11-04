import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';

/// Service for recommending clinics based on skin disease detection
/// 
/// Uses data-driven approach: analyzes actual appointment history to determine
/// which clinics have experience treating specific diseases
class ClinicRecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get recommended clinics for a specific disease based on appointment history
  /// 
  /// Analyzes actual appointments to find clinics that have treated this disease
  /// Returns clinics sorted by relevance (experience count and success rate)
  static Future<List<Map<String, dynamic>>> getRecommendedClinicsForDisease(
    String diseaseName,
  ) async {
    try {
      print('🔍 Analyzing appointment history for disease: $diseaseName');
      
      // Normalize disease name for better matching
      final normalizedDisease = _normalizeName(diseaseName);
      final diseaseWords = normalizedDisease.split(' ');
      
      // Get all active and visible clinics
      final clinicsSnapshot = await _firestore
          .collection('clinics')
          .where('status', isEqualTo: 'approved')
          .where('isVisible', isEqualTo: true)
          .get();
      
      print('📊 Found ${clinicsSnapshot.docs.length} active clinics');
      
      // Map to store clinic experience data
      final Map<String, Map<String, dynamic>> clinicExperience = {};
      
      // Initialize clinic data
      for (final clinicDoc in clinicsSnapshot.docs) {
        final clinicData = clinicDoc.data();
        final clinicId = clinicData['userId'] ?? clinicDoc.id;
        
        clinicExperience[clinicId] = {
          'clinicId': clinicId,
          'totalCases': 0,
          'completedCases': 0,
          'matchScore': 0,
        };
      }
      
      // Analyze appointments for disease treatment history
      // Only count COMPLETED appointments (validated by clinic)
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'completed')
          .get();
      
      print('📋 Analyzing ${appointmentsSnapshot.docs.length} completed & validated appointments...');
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final clinicId = appointmentData['clinicId'] as String?;
        final assessmentResultId = appointmentData['assessmentResultId'] as String?;
        final status = appointmentData['status'] as String?;
        final diagnosis = appointmentData['diagnosis'] as String?;
        final completedAt = appointmentData['completedAt'];
        
        // Skip if not completed or missing required fields
        if (clinicId == null || 
            assessmentResultId == null || 
            status != 'completed' ||
            !clinicExperience.containsKey(clinicId)) {
          continue;
        }
        
        // Additional validation: Only count if clinic has added diagnosis/notes
        // This ensures the appointment was properly validated by the clinic
        if (diagnosis == null || diagnosis.isEmpty) {
          continue; // Skip appointments without clinic validation
        }
        
        // Ensure appointment has completedAt timestamp
        if (completedAt == null) {
          continue; // Skip if missing completion timestamp
        }
        
        // Fetch assessment result to get detected diseases
        try {
          final assessmentDoc = await _firestore
              .collection('assessment_results')
              .doc(assessmentResultId)
              .get();
          
          if (assessmentDoc.exists) {
            final assessmentData = assessmentDoc.data();
            final detectionResults = assessmentData?['detectionResults'] as List?;
            
            if (detectionResults != null && detectionResults.isNotEmpty) {
              // Check each detection result
              for (final detection in detectionResults) {
                final detections = detection['detections'] as List?;
                
                if (detections != null) {
                  for (final det in detections) {
                    final detectedDisease = det['label'] as String?;
                    
                    if (detectedDisease != null) {
                      // Calculate match score for this detection
                      final matchScore = _calculateDiseaseMatchScore(
                        diseaseWords,
                        detectedDisease,
                      );
                      
                      if (matchScore > 0) {
                        // This clinic has completed treatment for this disease!
                        // Only count completed cases (validated by clinic)
                        clinicExperience[clinicId]!['totalCases'] = 
                            (clinicExperience[clinicId]!['totalCases'] as int) + 1;
                        
                        // Since we filter by completed status, all cases are completed
                        clinicExperience[clinicId]!['completedCases'] = 
                            (clinicExperience[clinicId]!['completedCases'] as int) + 1;
                        
                        // Update match score (use highest match found)
                        if (matchScore > clinicExperience[clinicId]!['matchScore']) {
                          clinicExperience[clinicId]!['matchScore'] = matchScore;
                        }
                        
                        break; // Found a match, no need to check other detections in this result
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          // Skip this appointment if assessment data is unavailable
          print('⚠️ Could not load assessment for appointment: $e');
          continue;
        }
      }
      
      // Build recommended clinics list with experience data
      final List<Map<String, dynamic>> recommendedClinics = [];
      
      for (final entry in clinicExperience.entries) {
        final clinicId = entry.key;
        final experience = entry.value;
        final totalCases = experience['totalCases'] as int;
        
        // Only recommend clinics with actual experience treating this disease
        if (totalCases > 0) {
          // Get clinic details
          final clinicDetails = await ClinicDetailsService.getClinicDetails(clinicId);
          
          if (clinicDetails != null) {
            final completedCases = experience['completedCases'] as int;
            final successRate = totalCases > 0 
                ? (completedCases / totalCases * 100).round() 
                : 0;
            
            // Calculate final score: base match score + experience bonus
            final baseScore = experience['matchScore'] as int;
            final experienceBonus = (totalCases * 10).clamp(0, 50); // Up to 50 bonus points
            final finalScore = baseScore + experienceBonus;
            
            print('   ✅ ${clinicDetails.clinicName}: $totalCases cases ($completedCases completed) - Score: $finalScore');
            
            recommendedClinics.add({
              'id': clinicId,
              'clinicId': clinicId,
              'name': clinicDetails.clinicName,
              'address': clinicDetails.address,
              'phone': clinicDetails.phone,
              'logoUrl': clinicDetails.logoUrl,
              'totalCases': totalCases,
              'completedCases': completedCases,
              'successRate': successRate,
              'matchScore': finalScore,
              'matchType': _getMatchType(baseScore, totalCases),
            });
          }
        }
      }
      
      // Sort by final score (highest first), then by total cases
      recommendedClinics.sort((a, b) {
        final scoreCompare = (b['matchScore'] as int).compareTo(a['matchScore'] as int);
        if (scoreCompare != 0) return scoreCompare;
        return (b['totalCases'] as int).compareTo(a['totalCases'] as int);
      });
      
      print('🎯 Recommended ${recommendedClinics.length} clinics with experience treating $diseaseName');
      
      return recommendedClinics;
    } catch (e) {
      print('❌ Error getting recommended clinics: $e');
      return [];
    }
  }
  
  /// Get recommended clinics for multiple diseases
  /// 
  /// Used when multiple conditions are detected
  /// Returns clinics that specialize in any of the detected diseases
  static Future<List<Map<String, dynamic>>> getRecommendedClinicsForMultipleDiseases(
    List<String> diseaseNames,
  ) async {
    try {
      if (diseaseNames.isEmpty) return [];
      
      print('🔍 Searching for clinics specializing in: ${diseaseNames.join(", ")}');
      
      // Collect all recommendations
      final Map<String, Map<String, dynamic>> clinicScores = {};
      
      for (final diseaseName in diseaseNames) {
        final recommendations = await getRecommendedClinicsForDisease(diseaseName);
        
        for (final clinic in recommendations) {
          final clinicId = clinic['id'] as String;
          
          if (clinicScores.containsKey(clinicId)) {
            // Clinic already found for another disease - boost its score
            clinicScores[clinicId]!['matchScore'] = 
              (clinicScores[clinicId]!['matchScore'] as int) + 
              (clinic['matchScore'] as int);
            
            // Add to matched diseases list
            final matchedDiseases = clinicScores[clinicId]!['matchedDiseases'] as List<String>;
            matchedDiseases.add(diseaseName);
          } else {
            // New clinic recommendation
            clinic['matchedDiseases'] = [diseaseName];
            clinicScores[clinicId] = clinic;
          }
        }
      }
      
      // Convert to list and sort by total match score
      final recommendedClinics = clinicScores.values.toList();
      recommendedClinics.sort((a, b) => 
        (b['matchScore'] as int).compareTo(a['matchScore'] as int)
      );
      
      print('🎯 Recommended ${recommendedClinics.length} clinics for multiple diseases');
      
      return recommendedClinics;
    } catch (e) {
      print('❌ Error getting recommended clinics for multiple diseases: $e');
      return [];
    }
  }
  
  /// Calculate match score between search disease and detected disease
  /// 
  /// Scoring system based on disease name similarity:
  /// - Exact match: 100 points
  /// - Contains full disease name: 75 points
  /// - Contains all disease words: 50 points
  /// - Contains some disease words: 25 points per word
  static int _calculateDiseaseMatchScore(
    List<String> searchDiseaseWords,
    String detectedDisease,
  ) {
    final normalizedDetected = _normalizeName(detectedDisease);
    final detectedWords = normalizedDetected.split(' ');
    final searchPhrase = searchDiseaseWords.join(' ');
    
    // Check for exact match
    if (normalizedDetected == searchPhrase) {
      return 100;
    }
    
    // Check if detected disease contains the full search phrase
    if (normalizedDetected.contains(searchPhrase)) {
      return 75;
    }
    
    // Check if search phrase contains detected disease
    if (searchPhrase.contains(normalizedDetected)) {
      return 75;
    }
    
    // Count matching words
    int matchingWords = 0;
    for (final searchWord in searchDiseaseWords) {
      if (searchWord.length < 3) continue; // Skip short words like "in", "of"
      
      if (detectedWords.contains(searchWord)) {
        matchingWords++;
      } else {
        // Check for partial matches
        for (final detectedWord in detectedWords) {
          if (detectedWord.contains(searchWord) || 
              searchWord.contains(detectedWord)) {
            matchingWords++;
            break;
          }
        }
      }
    }
    
    // Calculate score based on word matches
    if (matchingWords == searchDiseaseWords.length && matchingWords > 0) {
      // All search words matched
      return 50;
    } else if (matchingWords > 0) {
      // Some words matched
      return matchingWords * 25;
    }
    
    return 0;
  }
  
  /// Get match type description based on score and experience
  static String _getMatchType(int baseScore, int totalCases) {
    if (totalCases >= 10) {
      return 'Highly Experienced'; // Treated 10+ cases
    } else if (totalCases >= 5) {
      return 'Experienced'; // Treated 5-9 cases
    } else if (totalCases >= 2) {
      return 'Has Experience'; // Treated 2-4 cases
    } else if (baseScore >= 75) {
      return 'Similar Cases'; // Exact/close match with 1 case
    } else {
      return 'Related Cases'; // Partial match with 1 case
    }
  }
  
  /// Normalize name for better matching
  /// Converts to lowercase, removes special characters, extra spaces
  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }
  
  /// Check if a clinic has experience treating a specific disease
  /// 
  /// Checks appointment history to see if clinic has treated this disease before
  static Future<bool> clinicHasExperienceWithDisease(
    String clinicId,
    String diseaseName,
  ) async {
    try {
      final normalizedDisease = _normalizeName(diseaseName);
      final diseaseWords = normalizedDisease.split(' ');
      
      // Get completed appointments for this clinic (validated only)
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'completed')
          .limit(50) // Check last 50 appointments for performance
          .get();
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final assessmentResultId = appointmentData['assessmentResultId'] as String?;
        final diagnosis = appointmentData['diagnosis'] as String?;
        final completedAt = appointmentData['completedAt'];
        
        // Skip if missing required validation fields
        if (assessmentResultId == null || 
            diagnosis == null || 
            diagnosis.isEmpty ||
            completedAt == null) {
          continue;
        }
        
        // Check assessment result
        final assessmentDoc = await _firestore
            .collection('assessment_results')
            .doc(assessmentResultId)
            .get();
        
        if (assessmentDoc.exists) {
          final detectionResults = assessmentDoc.data()?['detectionResults'] as List?;
          
          if (detectionResults != null) {
            for (final detection in detectionResults) {
              final detections = detection['detections'] as List?;
              
              if (detections != null) {
                for (final det in detections) {
                  final detectedDisease = det['label'] as String?;
                  
                  if (detectedDisease != null) {
                    final matchScore = _calculateDiseaseMatchScore(
                      diseaseWords,
                      detectedDisease,
                    );
                    
                    if (matchScore >= 50) {
                      // Found a match!
                      return true;
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return false; // No experience found
    } catch (e) {
      print('❌ Error checking clinic experience: $e');
      return false;
    }
  }
}
