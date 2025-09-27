import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

class AssessmentResultService {
  final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'assessment_results';

  // Save assessment result to Firestore
  Future<String> saveAssessmentResult(AssessmentResult assessmentResult) async {
    try {
      final docRef = await _firestore.collection(_collection).add(assessmentResult.toMap());
      return docRef.id;
    } catch (e) {
      print('Error saving assessment result: $e');
      rethrow;
    }
  }

  // Get assessment result by ID
  Future<AssessmentResult?> getAssessmentResultById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return AssessmentResult.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting assessment result: $e');
      return null;
    }
  }

  // Get assessment results by user ID
  Future<List<AssessmentResult>> getAssessmentResultsByUserId(String userId) async {
    try {
      print('DEBUG: Fetching assessment results for userId: $userId');
      
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('DEBUG: Found ${query.docs.length} documents in assessment_results collection');

      final results = query.docs
          .map((doc) {
            print('DEBUG: Processing document ${doc.id} with data: ${doc.data().keys.toList()}');
            return AssessmentResult.fromMap(doc.data(), doc.id);
          })
          .toList();
      
      print('DEBUG: Returning ${results.length} assessment results');
      return results;
    } catch (e) {
      print('Error getting assessment results by user ID: $e');
      return [];
    }
  }

  // Get assessment results by pet ID
  Future<List<AssessmentResult>> getAssessmentResultsByPetId(String petId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('petId', isEqualTo: petId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting assessment results by pet ID: $e');
      return [];
    }
  }

  // Update assessment result
  Future<void> updateAssessmentResult(AssessmentResult assessmentResult) async {
    try {
      if (assessmentResult.id == null) {
        throw Exception('Assessment result ID is required for update');
      }

      final updatedData = assessmentResult.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(assessmentResult.id!)
          .update(updatedData.toMap());
    } catch (e) {
      print('Error updating assessment result: $e');
      rethrow;
    }
  }

  // Delete assessment result
  Future<void> deleteAssessmentResult(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting assessment result: $e');
      rethrow;
    }
  }

  // Stream assessment results by user ID
  Stream<List<AssessmentResult>> streamAssessmentResultsByUserId(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream assessment results by pet ID
  Stream<List<AssessmentResult>> streamAssessmentResultsByPetId(String petId) {
    return _firestore
        .collection(_collection)
        .where('petId', isEqualTo: petId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get recent assessment results with limit
  Future<List<AssessmentResult>> getRecentAssessmentResults({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting recent assessment results: $e');
      return [];
    }
  }

  // Get assessment results count by user ID
  Future<int> getAssessmentResultsCountByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('Error getting assessment results count: $e');
      return 0;
    }
  }

  // Get assessment results within date range
  Future<List<AssessmentResult>> getAssessmentResultsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting assessment results by date range: $e');
      return [];
    }
  }
}