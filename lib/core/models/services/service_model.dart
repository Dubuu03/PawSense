import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String? id;
  final String title;
  final String subtitle;
  final String description;
  final String iconName;
  final String backgroundColor;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ServiceModel({
    this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconName,
    required this.backgroundColor,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'iconName': iconName,
      'backgroundColor': backgroundColor,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  static ServiceModel fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'help_outline',
      backgroundColor: map['backgroundColor'] ?? '#E0E0E0',
      isActive: map['isActive'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      metadata: map['metadata'],
    );
  }

  ServiceModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? iconName,
    String? backgroundColor,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}