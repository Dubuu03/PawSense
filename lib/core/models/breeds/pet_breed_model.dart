import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for pet breed data
/// Simplified for user display - only essential information
class PetBreed {
  final String id;
  final String name;
  final String species; // 'cat' or 'dog'
  final String status; // 'active' or 'inactive'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  PetBreed({
    required this.id,
    required this.name,
    required this.species,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Create from Firestore document
  factory PetBreed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetBreed(
      id: doc.id,
      name: data['name'] ?? '',
      species: data['species'] ?? 'dog',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Create from JSON map
  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? 'dog',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? '',
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  PetBreed copyWith({
    String? id,
    String? name,
    String? species,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PetBreed(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Check if breed is active
  bool get isActive => status == 'active';

  /// Get species display name
  String get speciesDisplayName => species == 'cat' ? 'Cat' : 'Dog';

  @override
  String toString() {
    return 'PetBreed(id: $id, name: $name, species: $species, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetBreed && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum for breed species
enum BreedSpecies {
  all,
  cat,
  dog;

  String get value {
    switch (this) {
      case BreedSpecies.all:
        return 'all';
      case BreedSpecies.cat:
        return 'cat';
      case BreedSpecies.dog:
        return 'dog';
    }
  }

  String get displayName {
    switch (this) {
      case BreedSpecies.all:
        return 'All Species';
      case BreedSpecies.cat:
        return 'Cats';
      case BreedSpecies.dog:
        return 'Dogs';
    }
  }
}

/// Enum for breed status
enum BreedStatus {
  all,
  active,
  inactive;

  String get value {
    switch (this) {
      case BreedStatus.all:
        return 'all';
      case BreedStatus.active:
        return 'active';
      case BreedStatus.inactive:
        return 'inactive';
    }
  }

  String get displayName {
    switch (this) {
      case BreedStatus.all:
        return 'All Status';
      case BreedStatus.active:
        return 'Active';
      case BreedStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Enum for sort options
enum BreedSortOption {
  nameAsc,
  nameDesc,
  species,
  dateAdded;

  String get value {
    switch (this) {
      case BreedSortOption.nameAsc:
        return 'name_asc';
      case BreedSortOption.nameDesc:
        return 'name_desc';
      case BreedSortOption.species:
        return 'species';
      case BreedSortOption.dateAdded:
        return 'date_added';
    }
  }

  String get displayName {
    switch (this) {
      case BreedSortOption.nameAsc:
        return 'Name (A-Z)';
      case BreedSortOption.nameDesc:
        return 'Name (Z-A)';
      case BreedSortOption.species:
        return 'Species';
      case BreedSortOption.dateAdded:
        return 'Date Added';
    }
  }
}
