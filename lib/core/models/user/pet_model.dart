import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String userId;
  final String petName;
  final String petType; // Dog, Cat, Bird, etc.
  final int age; // in months
  final double weight; // in kg
  final String breed;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.age,
    required this.weight,
    required this.breed,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Pet to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'age': age,
      'weight': weight,
      'breed': breed,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Pet from Firestore document
  factory Pet.fromMap(Map<String, dynamic> map, String documentId) {
    return Pet(
      id: documentId,
      userId: map['userId'] ?? '',
      petName: map['petName'] ?? '',
      petType: map['petType'] ?? '',
      age: map['age']?.toInt() ?? 0,
      weight: map['weight']?.toDouble() ?? 0.0,
      breed: map['breed'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Pet copyWith({
    String? id,
    String? userId,
    String? petName,
    String? petType,
    int? age,
    double? weight,
    String? breed,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      breed: breed ?? this.breed,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get age in human-readable format
  String get ageString {
    if (age < 12) {
      return '$age months';
    } else {
      final years = age ~/ 12;
      final months = age % 12;
      if (months == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$years ${years == 1 ? 'year' : 'years'} $months ${months == 1 ? 'month' : 'months'}';
      }
    }
  }

  // Get weight string with unit
  String get weightString {
    return '${weight.toStringAsFixed(1)} kg';
  }

  @override
  String toString() {
    return 'Pet(id: $id, userId: $userId, petName: $petName, petType: $petType, age: $age, weight: $weight, breed: $breed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet &&
        other.id == id &&
        other.userId == userId &&
        other.petName == petName &&
        other.petType == petType &&
        other.age == age &&
        other.weight == weight &&
        other.breed == breed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        petName.hashCode ^
        petType.hashCode ^
        age.hashCode ^
        weight.hashCode ^
        breed.hashCode;
  }
}

// Enum for pet types
enum PetType {
  dog('Dog'),
  cat('Cat');

  const PetType(this.displayName);
  final String displayName;
}
