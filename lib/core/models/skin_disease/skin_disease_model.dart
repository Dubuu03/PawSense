import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a skin disease condition
/// 
/// Used to display disease information in the Skin Disease Library
/// Stored in Firestore 'skin_diseases' collection
class SkinDiseaseModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> species; // ['cats', 'dogs', 'both']
  final String severity; // 'low', 'moderate', 'high'
  final String detectionMethod; // 'ai', 'vet_guided', 'both'
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final String duration; // e.g., 'Varies', '2-4 weeks'
  final bool isContagious;
  final List<String> categories; // e.g., ['parasitic', 'allergic', 'bacterial']
  final int viewCount; // For tracking popularity
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? initialRemedies; // Initial remedies and care instructions

  SkinDiseaseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.species,
    required this.severity,
    required this.detectionMethod,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.duration,
    required this.isContagious,
    required this.categories,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.initialRemedies,
  });

  /// Create from Firestore document
  factory SkinDiseaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SkinDiseaseModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      species: List<String>.from(data['species'] ?? []),
      severity: data['severity'] ?? 'moderate',
      detectionMethod: data['detectionMethod'] ?? 'both',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      causes: List<String>.from(data['causes'] ?? []),
      treatments: List<String>.from(data['treatments'] ?? []),
      duration: data['duration'] ?? 'Varies',
      isContagious: data['isContagious'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      initialRemedies: data['initialRemedies'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'species': species,
      'severity': severity,
      'detectionMethod': detectionMethod,
      'symptoms': symptoms,
      'causes': causes,
      'treatments': treatments,
      'duration': duration,
      'isContagious': isContagious,
      'categories': categories,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (initialRemedies != null) 'initialRemedies': initialRemedies,
    };
  }

  /// Create a copy with updated fields
  SkinDiseaseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? species,
    String? severity,
    String? detectionMethod,
    List<String>? symptoms,
    List<String>? causes,
    List<String>? treatments,
    String? duration,
    bool? isContagious,
    List<String>? categories,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? initialRemedies,
  }) {
    return SkinDiseaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      species: species ?? this.species,
      severity: severity ?? this.severity,
      detectionMethod: detectionMethod ?? this.detectionMethod,
      symptoms: symptoms ?? this.symptoms,
      causes: causes ?? this.causes,
      treatments: treatments ?? this.treatments,
      duration: duration ?? this.duration,
      isContagious: isContagious ?? this.isContagious,
      categories: categories ?? this.categories,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      initialRemedies: initialRemedies ?? this.initialRemedies,
    );
  }

  /// Get display text for species (case-insensitive)
  String get speciesDisplay {
    final speciesLower = species.map((s) => s.toLowerCase()).toList();
    
    // Check for "both" or if it has both cats and dogs
    if (speciesLower.contains('both')) return 'Cats & Dogs';
    
    final hasCat = speciesLower.any((s) => s.contains('cat'));
    final hasDog = speciesLower.any((s) => s.contains('dog'));
    
    if (hasCat && hasDog) return 'Cats & Dogs';
    if (hasCat) return 'Cats';
    if (hasDog) return 'Dogs';
    return 'All';
  }

  /// Get display text for detection method
  String get detectionMethodDisplay {
    switch (detectionMethod) {
      case 'ai':
        return 'AI Detectable ✨';
      case 'vet_guided':
        return 'Vet guided';
      case 'both':
        return 'AI ✨';
      default:
        return detectionMethod;
    }
  }

  /// Get severity icon emoji
  String get severityIcon {
    switch (severity.toLowerCase()) {
      case 'low':
        return '🟢';
      case 'moderate':
        return '🟡';
      case 'high':
        return '🔴';
      default:
        return '⚪';
    }
  }

  /// Get contagious icon
  String get contagiousIcon => isContagious ? '⚠️' : '✓';
}
