import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/support/faq_item_model.dart';
import '../../guards/auth_guard.dart';

/// Service for managing FAQ items in Firestore
class FAQService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'faqs';

  /// Get FAQs for a specific clinic
  static Future<List<FAQItemModel>> getClinicFAQs(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FAQItemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting clinic FAQs: $e');
      return [];
    }
  }

  /// Get super admin FAQs (general app FAQs)
  static Future<List<FAQItemModel>> getSuperAdminFAQs() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isSuperAdminFAQ', isEqualTo: true)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FAQItemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting super admin FAQs: $e');
      return [];
    }
  }

  /// Get all FAQs for current user based on their role
  static Future<List<FAQItemModel>> getFAQsForCurrentUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return [];

      if (user.role == 'super_admin') {
        // Super admin sees their own FAQs
        return await getSuperAdminFAQs();
      } else if (user.role == 'admin') {
        // Admin sees their clinic FAQs
        return await getClinicFAQs(user.uid);
      }

      return [];
    } catch (e) {
      print('Error getting FAQs for current user: $e');
      return [];
    }
  }

  /// Get FAQs visible to users (both super admin and specific clinic FAQs)
  static Future<List<FAQItemModel>> getPublicFAQs({String? clinicId}) async {
    try {
      List<FAQItemModel> faqs = [];

      // Always get super admin FAQs (general app FAQs)
      final superAdminFAQs = await getSuperAdminFAQs();
      faqs.addAll(superAdminFAQs);

      // If clinicId provided, also get clinic-specific FAQs
      if (clinicId != null && clinicId.isNotEmpty) {
        final clinicFAQs = await getClinicFAQs(clinicId);
        faqs.addAll(clinicFAQs);
      }

      // Sort by created date (newest first)
      faqs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return faqs;
    } catch (e) {
      print('Error getting public FAQs: $e');
      return [];
    }
  }

  /// Create a new FAQ
  static Future<bool> createFAQ({
    required String question,
    required String answer,
    required String category,
    String? clinicId,
    bool isSuperAdminFAQ = false,
  }) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return false;

      // Validate permissions
      if (isSuperAdminFAQ && user.role != 'super_admin') {
        print('Only super admins can create super admin FAQs');
        return false;
      }

      if (!isSuperAdminFAQ && user.role != 'admin') {
        print('Only admins can create clinic FAQs');
        return false;
      }

      final docRef = _firestore.collection(_collection).doc();
      final faq = FAQItemModel(
        id: docRef.id,
        question: question,
        answer: answer,
        category: category,
        views: 0,
        helpfulVotes: 0,
        clinicId: isSuperAdminFAQ ? null : (clinicId ?? user.uid),
        isSuperAdminFAQ: isSuperAdminFAQ,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        isPublished: true,
      );

      await docRef.set(faq.toMap());
      print('✅ FAQ created successfully');
      return true;
    } catch (e) {
      print('Error creating FAQ: $e');
      return false;
    }
  }

  /// Update an existing FAQ
  static Future<bool> updateFAQ({
    required String faqId,
    required String question,
    required String answer,
    required String category,
    bool? isPublished,
  }) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return false;

      // Get the FAQ to verify ownership
      final faqDoc = await _firestore.collection(_collection).doc(faqId).get();
      if (!faqDoc.exists) {
        print('FAQ not found');
        return false;
      }

      final faq = FAQItemModel.fromMap(faqDoc.data()!);

      // Verify user can edit this FAQ
      if (faq.isSuperAdminFAQ && user.role != 'super_admin') {
        print('Only super admins can edit super admin FAQs');
        return false;
      }

      if (!faq.isSuperAdminFAQ && faq.clinicId != user.uid && user.role != 'super_admin') {
        print('User does not have permission to edit this FAQ');
        return false;
      }

      await _firestore.collection(_collection).doc(faqId).update({
        'question': question,
        'answer': answer,
        'category': category,
        'isPublished': isPublished ?? faq.isPublished,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ FAQ updated successfully');
      return true;
    } catch (e) {
      print('Error updating FAQ: $e');
      return false;
    }
  }

  /// Delete an FAQ
  static Future<bool> deleteFAQ(String faqId) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return false;

      // Get the FAQ to verify ownership
      final faqDoc = await _firestore.collection(_collection).doc(faqId).get();
      if (!faqDoc.exists) {
        print('FAQ not found');
        return false;
      }

      final faq = FAQItemModel.fromMap(faqDoc.data()!);

      // Verify user can delete this FAQ
      if (faq.isSuperAdminFAQ && user.role != 'super_admin') {
        print('Only super admins can delete super admin FAQs');
        return false;
      }

      if (!faq.isSuperAdminFAQ && faq.clinicId != user.uid && user.role != 'super_admin') {
        print('User does not have permission to delete this FAQ');
        return false;
      }

      await _firestore.collection(_collection).doc(faqId).delete();
      print('✅ FAQ deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting FAQ: $e');
      return false;
    }
  }

  /// Increment view count
  static Future<void> incrementViews(String faqId) async {
    try {
      await _firestore.collection(_collection).doc(faqId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  /// Increment helpful votes
  static Future<void> incrementHelpfulVotes(String faqId) async {
    try {
      await _firestore.collection(_collection).doc(faqId).update({
        'helpfulVotes': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing helpful votes: $e');
    }
  }

  /// Stream FAQs for real-time updates
  static Stream<List<FAQItemModel>> streamFAQsForCurrentUser() {
    return _firestore
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return <FAQItemModel>[];

      final allFAQs = snapshot.docs
          .map((doc) => FAQItemModel.fromMap(doc.data()))
          .toList();

      if (user.role == 'super_admin') {
        // Super admin sees only super admin FAQs in their management
        return allFAQs.where((faq) => faq.isSuperAdminFAQ).toList();
      } else if (user.role == 'admin') {
        // Admin sees only their clinic FAQs
        return allFAQs.where((faq) => faq.clinicId == user.uid).toList();
      }

      return <FAQItemModel>[];
    });
  }
}
