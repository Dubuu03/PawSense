class FAQItemModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int views;
  final int helpfulVotes;
  final bool isExpanded;
  final String? clinicId; // null for super admin FAQs
  final bool isSuperAdminFAQ; // true for general app FAQs
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy; // user ID who created
  final bool isPublished;

  FAQItemModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.views,
    required this.helpfulVotes,
    this.isExpanded = false,
    this.clinicId,
    this.isSuperAdminFAQ = false,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.isPublished = true,
  });

  FAQItemModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? views,
    int? helpfulVotes,
    bool? isExpanded,
    String? clinicId,
    bool? isSuperAdminFAQ,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isPublished,
  }) {
    return FAQItemModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      views: views ?? this.views,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      isExpanded: isExpanded ?? this.isExpanded,
      clinicId: clinicId ?? this.clinicId,
      isSuperAdminFAQ: isSuperAdminFAQ ?? this.isSuperAdminFAQ,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'views': views,
      'helpfulVotes': helpfulVotes,
      'clinicId': clinicId,
      'isSuperAdminFAQ': isSuperAdminFAQ,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'isPublished': isPublished,
    };
  }

  factory FAQItemModel.fromMap(Map<String, dynamic> map) {
    return FAQItemModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? '',
      views: map['views'] ?? 0,
      helpfulVotes: map['helpfulVotes'] ?? 0,
      clinicId: map['clinicId'],
      isSuperAdminFAQ: map['isSuperAdminFAQ'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      createdBy: map['createdBy'] ?? '',
      isPublished: map['isPublished'] ?? true,
    );
  }
}