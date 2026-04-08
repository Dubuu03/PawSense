import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentResult {
  final String? id;
  final String userId;
  final String petId;
  final String petName;
  final String petType;
  final String petBreed;
  final int petAge;
  final double petWeight;
  final List<String> symptoms;
  final List<String> imageUrls;
  final String notes;
  final String duration;
  final List<DetectionResult> detectionResults;
  final List<AnalysisResultData> analysisResults;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool aiEnabled;
  final String? triageModelUsed;
  final String? recommendationModelUsed;
  final String fallbackLevel;
  final String? aiErrorType;
  final int? generationLatencyMs;
  final int? tokenEstimate;
  final bool cacheHit;
  final bool disagreementFlag;
  final bool redFlagEscalation;
  final String? traceId;

  AssessmentResult({
    this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.petType,
    required this.petBreed,
    required this.petAge,
    required this.petWeight,
    required this.symptoms,
    required this.imageUrls,
    required this.notes,
    required this.duration,
    required this.detectionResults,
    required this.analysisResults,
    required this.createdAt,
    required this.updatedAt,
    this.aiEnabled = false,
    this.triageModelUsed,
    this.recommendationModelUsed,
    this.fallbackLevel = 'none',
    this.aiErrorType,
    this.generationLatencyMs,
    this.tokenEstimate,
    this.cacheHit = false,
    this.disagreementFlag = false,
    this.redFlagEscalation = false,
    this.traceId,
  });

  // Convert AssessmentResult to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petId': petId,
      'petName': petName,
      'petType': petType,
      'petBreed': petBreed,
      'petAge': petAge,
      'petWeight': petWeight,
      'symptoms': symptoms,
      'imageUrls': imageUrls,
      'notes': notes,
      'duration': duration,
      'detectionResults': detectionResults.map((result) => result.toMap()).toList(),
      'analysisResults': analysisResults.map((result) => result.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'aiEnabled': aiEnabled,
      'triageModelUsed': triageModelUsed,
      'recommendationModelUsed': recommendationModelUsed,
      'fallbackLevel': fallbackLevel,
      'aiErrorType': aiErrorType,
      'generationLatencyMs': generationLatencyMs,
      'tokenEstimate': tokenEstimate,
      'cacheHit': cacheHit,
      'disagreementFlag': disagreementFlag,
      'redFlagEscalation': redFlagEscalation,
      'traceId': traceId,
    };
  }

  // Create AssessmentResult from Firestore document
  factory AssessmentResult.fromMap(Map<String, dynamic> map, String documentId) {
    return AssessmentResult(
      id: documentId,
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      petType: map['petType'] ?? '',
      petBreed: map['petBreed'] ?? '',
      petAge: map['petAge']?.toInt() ?? 0,
      petWeight: map['petWeight']?.toDouble() ?? 0.0,
      symptoms: List<String>.from(map['symptoms'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      notes: map['notes'] ?? '',
      duration: map['duration'] ?? '',
      detectionResults: (map['detectionResults'] as List<dynamic>? ?? [])
          .map((result) => DetectionResult.fromMap(result))
          .toList(),
      analysisResults: (map['analysisResults'] as List<dynamic>? ?? [])
          .map((result) => AnalysisResultData.fromMap(result))
          .toList(),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
        aiEnabled: map['aiEnabled'] ?? false,
        triageModelUsed: map['triageModelUsed'],
        recommendationModelUsed: map['recommendationModelUsed'],
        fallbackLevel: map['fallbackLevel'] ?? 'none',
        aiErrorType: map['aiErrorType'],
        generationLatencyMs: map['generationLatencyMs']?.toInt(),
        tokenEstimate: map['tokenEstimate']?.toInt(),
        cacheHit: map['cacheHit'] ?? false,
        disagreementFlag: map['disagreementFlag'] ?? false,
        redFlagEscalation: map['redFlagEscalation'] ?? false,
        traceId: map['traceId'],
    );
  }

  // Create a copy with updated fields
  AssessmentResult copyWith({
    String? id,
    String? userId,
    String? petId,
    String? petName,
    String? petType,
    String? petBreed,
    int? petAge,
    double? petWeight,
    List<String>? symptoms,
    List<String>? imageUrls,
    String? notes,
    String? duration,
    List<DetectionResult>? detectionResults,
    List<AnalysisResultData>? analysisResults,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? aiEnabled,
    String? triageModelUsed,
    String? recommendationModelUsed,
    String? fallbackLevel,
    String? aiErrorType,
    int? generationLatencyMs,
    int? tokenEstimate,
    bool? cacheHit,
    bool? disagreementFlag,
    bool? redFlagEscalation,
    String? traceId,
  }) {
    return AssessmentResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      petBreed: petBreed ?? this.petBreed,
      petAge: petAge ?? this.petAge,
      petWeight: petWeight ?? this.petWeight,
      symptoms: symptoms ?? this.symptoms,
      imageUrls: imageUrls ?? this.imageUrls,
      notes: notes ?? this.notes,
      duration: duration ?? this.duration,
      detectionResults: detectionResults ?? this.detectionResults,
      analysisResults: analysisResults ?? this.analysisResults,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      triageModelUsed: triageModelUsed ?? this.triageModelUsed,
      recommendationModelUsed:
          recommendationModelUsed ?? this.recommendationModelUsed,
      fallbackLevel: fallbackLevel ?? this.fallbackLevel,
      aiErrorType: aiErrorType ?? this.aiErrorType,
      generationLatencyMs: generationLatencyMs ?? this.generationLatencyMs,
      tokenEstimate: tokenEstimate ?? this.tokenEstimate,
      cacheHit: cacheHit ?? this.cacheHit,
      disagreementFlag: disagreementFlag ?? this.disagreementFlag,
      redFlagEscalation: redFlagEscalation ?? this.redFlagEscalation,
      traceId: traceId ?? this.traceId,
    );
  }
}

class DetectionResult {
  final String imageUrl;
  final List<Detection> detections;

  DetectionResult({
    required this.imageUrl,
    required this.detections,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'detections': detections.map((detection) => detection.toMap()).toList(),
    };
  }

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      imageUrl: map['imageUrl'] ?? '',
      detections: (map['detections'] as List<dynamic>? ?? [])
          .map((detection) => Detection.fromMap(detection))
          .toList(),
    );
  }
}

class Detection {
  final String label;
  final double confidence;
  final List<double>? boundingBox;

  Detection({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': boundingBox,
    };
  }

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      label: map['label'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      boundingBox: map['boundingBox'] != null 
          ? List<double>.from(map['boundingBox'])
          : null,
    );
  }
}

class AnalysisResultData {
  final String condition;
  final double percentage;
  final String colorHex;

  AnalysisResultData({
    required this.condition,
    required this.percentage,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'percentage': percentage,
      'colorHex': colorHex,
    };
  }

  factory AnalysisResultData.fromMap(Map<String, dynamic> map) {
    return AnalysisResultData(
      condition: map['condition'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
      colorHex: map['colorHex'] ?? '#000000',
    );
  }
}