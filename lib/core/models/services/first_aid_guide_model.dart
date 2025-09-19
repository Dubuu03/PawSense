import 'package:cloud_firestore/cloud_firestore.dart';

class FirstAidStep {
  final String stepNumber;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isImportant;

  FirstAidStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.imageUrl,
    this.isImportant = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
    };
  }

  static FirstAidStep fromMap(Map<String, dynamic> map) {
    return FirstAidStep(
      stepNumber: map['stepNumber'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      isImportant: map['isImportant'] ?? false,
    );
  }
}

class FirstAidGuideModel {
  final String? id;
  final String title;
  final String category;
  final String description;
  final String urgencyLevel; // Low, Medium, High, Critical
  final List<FirstAidStep> steps;
  final List<String> warnings;
  final List<String> whenToCallVet;
  final String? videoUrl;
  final String? imageUrl;
  final List<String> tags;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirstAidGuideModel({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.urgencyLevel,
    this.steps = const [],
    this.warnings = const [],
    this.whenToCallVet = const [],
    this.videoUrl,
    this.imageUrl,
    this.tags = const [],
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'urgencyLevel': urgencyLevel,
      'steps': steps.map((step) => step.toMap()).toList(),
      'warnings': warnings,
      'whenToCallVet': whenToCallVet,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'tags': tags,
      'isActive': isActive,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static FirstAidGuideModel fromMap(Map<String, dynamic> map, String id) {
    return FirstAidGuideModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      urgencyLevel: map['urgencyLevel'] ?? 'Medium',
      steps: (map['steps'] as List<dynamic>?)
          ?.map((step) => FirstAidStep.fromMap(step as Map<String, dynamic>))
          .toList() ?? [],
      warnings: List<String>.from(map['warnings'] ?? []),
      whenToCallVet: List<String>.from(map['whenToCallVet'] ?? []),
      videoUrl: map['videoUrl'],
      imageUrl: map['imageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  FirstAidGuideModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? urgencyLevel,
    List<FirstAidStep>? steps,
    List<String>? warnings,
    List<String>? whenToCallVet,
    String? videoUrl,
    String? imageUrl,
    List<String>? tags,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirstAidGuideModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      steps: steps ?? this.steps,
      warnings: warnings ?? this.warnings,
      whenToCallVet: whenToCallVet ?? this.whenToCallVet,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}