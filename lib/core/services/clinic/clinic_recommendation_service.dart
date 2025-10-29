import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';

/// Service for recommending clinics based on skin disease detection
/// 
/// Matches detected diseases with clinic specialties to provide
/// personalized clinic recommendations to users
class ClinicRecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get recommended clinics for a specific disease
  /// 
  /// Searches for clinics that have specialties matching the disease name
  /// Returns clinics sorted by relevance (exact match first, then partial matches)
  static Future<List<Map<String, dynamic>>> getRecommendedClinicsForDisease(
    String diseaseName,
  ) async {
    try {
      print('🔍 Searching for clinics specializing in: $diseaseName');
      
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
      
      // List to store recommended clinics with their match scores
      final List<Map<String, dynamic>> recommendedClinics = [];
      
      for (final clinicDoc in clinicsSnapshot.docs) {
        final clinicData = clinicDoc.data();
        final clinicId = clinicData['userId'] ?? clinicDoc.id;
        
        // Get clinic details to check specialties
        final clinicDetails = await ClinicDetailsService.getClinicDetails(clinicId);
        
        if (clinicDetails != null && clinicDetails.specialties.isNotEmpty) {
          // Calculate match score
          final matchScore = _calculateMatchScore(
            diseaseWords,
            clinicDetails.specialties,
          );
          
          if (matchScore > 0) {
            print('   ✅ Match found: ${clinicDetails.clinicName} (score: $matchScore)');
            
            recommendedClinics.add({
              'id': clinicId,
              'clinicId': clinicId,
              'name': clinicDetails.clinicName,
              'address': clinicDetails.address,
              'phone': clinicDetails.phone,
              'logoUrl': clinicDetails.logoUrl,
              'specialties': clinicDetails.specialties,
              'matchScore': matchScore,
              'matchType': _getMatchType(matchScore),
            });
          }
        }
      }
      
      // Sort by match score (highest first)
      recommendedClinics.sort((a, b) => 
        (b['matchScore'] as int).compareTo(a['matchScore'] as int)
      );
      
      print('🎯 Recommended ${recommendedClinics.length} clinics for $diseaseName');
      
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
  
  /// Calculate match score between disease and clinic specialties
  /// 
  /// Scoring system:
  /// - Exact match: 100 points
  /// - Contains full disease name: 75 points
  /// - Contains all disease words: 50 points
  /// - Contains some disease words: 25 points per word
  static int _calculateMatchScore(
    List<String> diseaseWords,
    List<String> specialties,
  ) {
    int maxScore = 0;
    
    for (final specialty in specialties) {
      final normalizedSpecialty = _normalizeName(specialty);
      final specialtyWords = normalizedSpecialty.split(' ');
      
      // Check for exact match
      if (normalizedSpecialty == diseaseWords.join(' ')) {
        maxScore = maxScore > 100 ? maxScore : 100;
        continue;
      }
      
      // Check if specialty contains the full disease phrase
      final diseasePhrase = diseaseWords.join(' ');
      if (normalizedSpecialty.contains(diseasePhrase)) {
        maxScore = maxScore > 75 ? maxScore : 75;
        continue;
      }
      
      // Check if disease phrase is contained in specialty
      if (diseasePhrase.contains(normalizedSpecialty)) {
        maxScore = maxScore > 70 ? maxScore : 70;
        continue;
      }
      
      // Count matching words
      int matchingWords = 0;
      for (final diseaseWord in diseaseWords) {
        if (diseaseWord.length < 3) continue; // Skip short words like "in", "of"
        
        if (specialtyWords.contains(diseaseWord)) {
          matchingWords++;
        } else {
          // Check for partial matches
          for (final specialtyWord in specialtyWords) {
            if (specialtyWord.contains(diseaseWord) || 
                diseaseWord.contains(specialtyWord)) {
              matchingWords++;
              break;
            }
          }
        }
      }
      
      // Calculate score based on word matches
      if (matchingWords == diseaseWords.length && matchingWords > 0) {
        // All disease words matched
        final score = 50;
        maxScore = maxScore > score ? maxScore : score;
      } else if (matchingWords > 0) {
        // Some words matched
        final score = matchingWords * 25;
        maxScore = maxScore > score ? maxScore : score;
      }
    }
    
    return maxScore;
  }
  
  /// Get match type description based on score
  static String _getMatchType(int score) {
    if (score >= 100) return 'Exact Specialty Match';
    if (score >= 75) return 'Primary Specialty';
    if (score >= 50) return 'Related Specialty';
    if (score >= 25) return 'General Practice';
    return 'Available';
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
  
  /// Check if a clinic specializes in a specific disease
  static Future<bool> clinicSpecializesInDisease(
    String clinicId,
    String diseaseName,
  ) async {
    try {
      final clinicDetails = await ClinicDetailsService.getClinicDetails(clinicId);
      
      if (clinicDetails == null || clinicDetails.specialties.isEmpty) {
        return false;
      }
      
      final normalizedDisease = _normalizeName(diseaseName);
      final diseaseWords = normalizedDisease.split(' ');
      
      final matchScore = _calculateMatchScore(
        diseaseWords,
        clinicDetails.specialties,
      );
      
      return matchScore >= 50; // At least related specialty
    } catch (e) {
      print('❌ Error checking clinic specialty: $e');
      return false;
    }
  }
}
