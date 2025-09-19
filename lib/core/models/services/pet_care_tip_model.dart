import 'package:cloud_firestore/cloud_firestore.dart';

class PetCareTipModel {
  final String? id;
  final String title;
  final String category;
  final String description;
  final String content;
  final String petType; // Dog, Cat, Bird, All, etc.
  final String ageGroup; // Puppy/Kitten, Adult, Senior, All
  final String difficulty; // Beginner, Intermediate, Advanced
  final List<String> tags;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> relatedTips;
  final int estimatedReadTime; // in minutes
  final bool isFeatured;
  final bool isActive;
  final int likes;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetCareTipModel({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.content,
    required this.petType,
    required this.ageGroup,
    required this.difficulty,
    this.tags = const [],
    this.imageUrl,
    this.videoUrl,
    this.relatedTips = const [],
    this.estimatedReadTime = 5,
    this.isFeatured = false,
    this.isActive = true,
    this.likes = 0,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'content': content,
      'petType': petType,
      'ageGroup': ageGroup,
      'difficulty': difficulty,
      'tags': tags,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'relatedTips': relatedTips,
      'estimatedReadTime': estimatedReadTime,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'likes': likes,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static PetCareTipModel fromMap(Map<String, dynamic> map, String id) {
    return PetCareTipModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      content: map['content'] ?? '',
      petType: map['petType'] ?? 'All',
      ageGroup: map['ageGroup'] ?? 'All',
      difficulty: map['difficulty'] ?? 'Beginner',
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      relatedTips: List<String>.from(map['relatedTips'] ?? []),
      estimatedReadTime: map['estimatedReadTime'] ?? 5,
      isFeatured: map['isFeatured'] ?? false,
      isActive: map['isActive'] ?? true,
      likes: map['likes'] ?? 0,
      views: map['views'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PetCareTipModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? content,
    String? petType,
    String? ageGroup,
    String? difficulty,
    List<String>? tags,
    String? imageUrl,
    String? videoUrl,
    List<String>? relatedTips,
    int? estimatedReadTime,
    bool? isFeatured,
    bool? isActive,
    int? likes,
    int? views,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetCareTipModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      content: content ?? this.content,
      petType: petType ?? this.petType,
      ageGroup: ageGroup ?? this.ageGroup,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      relatedTips: relatedTips ?? this.relatedTips,
      estimatedReadTime: estimatedReadTime ?? this.estimatedReadTime,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}