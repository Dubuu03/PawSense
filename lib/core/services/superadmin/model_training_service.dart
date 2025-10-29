// services/superadmin/model_training_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// For web downloads - conditional import
import 'model_training_web.dart'
  if (dart.library.io) 'model_training_stub.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class TrainingImageData {
  final String id;
  final String appointmentId;
  final String assessmentResultId;
  final String petType;
  final String petBreed;
  final String diseaseLabel;
  final String clinicDiagnosis;
  final bool? overallCorrect;
  final String feedback;
  final String? correctDisease;
  final DateTime validatedAt;
  final String validatedBy;
  final bool canUseForTraining;
  final bool canUseForRetraining;
  final bool hasImageAssessment;
  final String trainingDataType;
  
  // Image data
  final String? originalImageUrl;
  final String? annotatedImageUrl;
  final List<Map<String, dynamic>> assessmentImages;
  final Map<String, dynamic>? assessmentMetadata;
  final String? uniqueFilename;
  final String correctionType;
  
  // AI Predictions
  final List<Map<String, dynamic>> aiPredictions;

  TrainingImageData({
    required this.id,
    required this.appointmentId,
    required this.assessmentResultId,
    required this.petType,
    required this.petBreed,
    required this.diseaseLabel,
    required this.clinicDiagnosis,
    this.overallCorrect,
    required this.feedback,
    this.correctDisease,
    required this.validatedAt,
    required this.validatedBy,
    required this.canUseForTraining,
    required this.canUseForRetraining,
    required this.hasImageAssessment,
    required this.trainingDataType,
    this.originalImageUrl,
    this.annotatedImageUrl,
    required this.assessmentImages,
    this.assessmentMetadata,
    this.uniqueFilename,
    required this.correctionType,
    required this.aiPredictions,
  });

  factory TrainingImageData.fromFirestore(String id, Map<String, dynamic> data) {
    // Support both nested (legacy) and flat (new) data structures
    // New structure: fields at root level (imageUrl, diseaseLabel, uniqueFilename, etc.)
    // Legacy structure: fields nested under 'imageData' object
    
    final imageData = data['imageData'] as Map<String, dynamic>?;
    
    return TrainingImageData(
      id: id,
      appointmentId: data['appointmentId'] ?? '',
      assessmentResultId: data['assessmentResultId'] ?? '',
      petType: data['petType'] ?? 'Unknown',
      petBreed: data['petBreed'] ?? 'Unknown',
      // Try flat structure first, then nested, then fallback
      diseaseLabel: data['diseaseLabel'] ?? 
                    imageData?['diseaseLabel'] ?? 
                    data['correctDisease'] ?? 
                    data['clinicDiagnosis'] ?? 
                    'Unknown',
      clinicDiagnosis: data['clinicDiagnosis'] ?? '',
      // Map 'isCorrect' (new field) to overallCorrect, or use legacy 'overallCorrect'
      overallCorrect: data['isCorrect'] as bool? ?? data['overallCorrect'] as bool?,
      feedback: data['feedback'] ?? '',
      correctDisease: data['correctDisease'] as String?,
      validatedAt: (data['validatedAt'] as Timestamp).toDate(),
      validatedBy: data['validatedBy'] ?? '',
      canUseForTraining: data['canUseForTraining'] ?? false,
      canUseForRetraining: data['canUseForRetraining'] ?? false,
      hasImageAssessment: data['hasImageAssessment'] ?? false,
      trainingDataType: data['trainingDataType'] ?? 'text_assessment',
      // Try flat structure first (imageUrl), then nested (originalImageUrl)
      originalImageUrl: data['imageUrl'] as String? ?? imageData?['originalImageUrl'] as String?,
      annotatedImageUrl: imageData?['annotatedImageUrl'] as String?,
      assessmentImages: (imageData?['assessmentImages'] as List<dynamic>?)
          ?.map((img) => img as Map<String, dynamic>)
          .toList() ?? [],
      assessmentMetadata: imageData?['assessmentMetadata'] as Map<String, dynamic>?,
      // Try flat structure first, then nested
      uniqueFilename: data['uniqueFilename'] as String? ?? imageData?['uniqueFilename'] as String?,
      // Try flat structure first, then nested
      correctionType: data['correctionType'] ?? imageData?['correctionType'] ?? 'validation',
      aiPredictions: (data['aiPredictions'] as List<dynamic>?)
          ?.map((pred) => pred as Map<String, dynamic>)
          .toList() ?? [],
    );
  }

  String get primaryImageUrl => originalImageUrl ?? (assessmentImages.isNotEmpty ? assessmentImages.first['url'] : null) ?? '';
  
  bool get hasValidImage => primaryImageUrl.isNotEmpty;
}

class ModelTrainingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all training data from Firestore
  Future<List<TrainingImageData>> fetchAllTrainingData() async {
    try {
      print('📊 Fetching training data from Firestore...');
      
      final snapshot = await _firestore
          .collection('model_training_data')
          .orderBy('validatedAt', descending: true)
          .get();

      print('📦 Found ${snapshot.docs.length} training data records');

      final data = snapshot.docs.map((doc) {
        try {
          return TrainingImageData.fromFirestore(doc.id, doc.data());
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
          return null;
        }
      }).whereType<TrainingImageData>().toList();

      // Filter to only include records with images
      final dataWithImages = data.where((d) => d.hasValidImage).toList();
      
      print('✅ Loaded ${dataWithImages.length} training records with images');
      return dataWithImages;
    } catch (e) {
      print('❌ Error fetching training data: $e');
      rethrow;
    }
  }

  /// Export selected training images grouped by pet type, then by disease label
  Future<void> exportTrainingImages(Map<String, List<TrainingImageData>> selectedByLabel) async {
    if (!kIsWeb) {
      throw UnsupportedError('Image export is only supported on web platform');
    }

    try {
      print('📦 Starting export of ${selectedByLabel.length} disease labels...');
      
      // Create archive
      final archive = Archive();
      int totalImages = 0;
      
      // Group images by pet type first, then by disease label
      final Map<String, Map<String, List<TrainingImageData>>> imagesByPetType = {
        'Dog': {},
        'Cat': {},
      };
      
      // Organize images by pet type and disease label
      for (var entry in selectedByLabel.entries) {
        final label = entry.key;
        final images = entry.value;
        
        for (var image in images) {
          final petType = image.petType;
          if (!imagesByPetType.containsKey(petType)) {
            imagesByPetType[petType] = {};
          }
          
          if (!imagesByPetType[petType]!.containsKey(label)) {
            imagesByPetType[petType]![label] = [];
          }
          
          imagesByPetType[petType]![label]!.add(image);
        }
      }
      
      print('📊 Organized images: ${imagesByPetType['Dog']?.length ?? 0} dog labels, ${imagesByPetType['Cat']?.length ?? 0} cat labels');
      
      // Download and add images to archive, grouped by pet type then by disease label
      for (var petTypeEntry in imagesByPetType.entries) {
        final petType = petTypeEntry.key;
        final diseaseLabels = petTypeEntry.value;
        
        if (diseaseLabels.isEmpty) continue;
        
        final petTypeFolder = petType.toLowerCase();
        print('\n🐾 Processing $petType images (${diseaseLabels.length} disease labels)...');
        
        for (var labelEntry in diseaseLabels.entries) {
          final label = labelEntry.key;
          final images = labelEntry.value;
          
          // Sanitize label for folder name
          final sanitizedLabel = _sanitizeFolderName(label);
          print('  📁 Processing label: $label (${images.length} images)');
          
          for (var i = 0; i < images.length; i++) {
            final imageData = images[i];
            
            try {
              // Download the image
              final imageUrl = imageData.primaryImageUrl;
              if (imageUrl.isEmpty) continue;
              
              print('    ⬇️ Downloading image ${i + 1}/${images.length}');
              final response = await http.get(Uri.parse(imageUrl));
              
              if (response.statusCode == 200) {
                // Use unique filename if available, otherwise generate one
                String filename = imageData.uniqueFilename ?? 
                    '${imageData.petType.toLowerCase()}_${sanitizedLabel}_${imageData.id.substring(0, 8)}_${i + 1}';
                
                // Get file extension from URL or default to jpg
                final extension = _getFileExtension(imageUrl);
                filename = '$filename.$extension';
                
                // Add to archive under pet type folder, then disease label folder
                final filePath = '$petTypeFolder/$sanitizedLabel/$filename';
                archive.addFile(
                  ArchiveFile(
                    filePath,
                    response.bodyBytes.length,
                    response.bodyBytes,
                  ),
                );
                
                totalImages++;
                print('    ✅ Added: $filePath');
              } else {
                print('    ⚠️ Failed to download image: HTTP ${response.statusCode}');
              }
            } catch (e) {
              print('    ❌ Error downloading image: $e');
              // Continue with next image
            }
          }
        }
      }
      
      if (totalImages == 0) {
        throw Exception('No images were successfully downloaded');
      }
      
      print('🔄 Creating ZIP archive with $totalImages images...');
      
      // Encode the archive to ZIP format
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      
      if (zipData == null) {
        throw Exception('Failed to create ZIP archive');
      }
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final filename = 'training_data_$timestamp.zip';
      
      // Trigger download using helper function
      downloadFile(Uint8List.fromList(zipData), filename, 'application/zip');
      
      print('✅ Export completed: $filename ($totalImages images across ${selectedByLabel.length} labels)');
    } catch (e) {
      print('❌ Export failed: $e');
      rethrow;
    }
  }

  /// Sanitize folder name for file system compatibility
  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Get file extension from URL
  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    
    if (lastDot != -1 && lastDot < path.length - 1) {
      final ext = path.substring(lastDot + 1).toLowerCase();
      // Common image extensions
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        return ext;
      }
    }
    
    // Default to jpg if extension cannot be determined
    return 'jpg';
  }
}
