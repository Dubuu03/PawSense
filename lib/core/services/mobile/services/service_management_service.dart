import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/services/service_model.dart';

class ServiceManagementService {
  static const String _collection = 'services';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active services ordered by sortOrder
  static Future<List<ServiceModel>> getActiveServices() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active services: $e');
      return [];
    }
  }

  /// Get all services (for admin management)
  static Future<List<ServiceModel>> getAllServices() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('sortOrder')
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all services: $e');
      return [];
    }
  }

  /// Get a specific service by ID
  static Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(serviceId).get();
      
      if (doc.exists && doc.data() != null) {
        return ServiceModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting service by ID: $e');
      return null;
    }
  }

  /// Add a new service
  static Future<String?> addService(ServiceModel service) async {
    try {
      final docRef = await _firestore.collection(_collection).add(service.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding service: $e');
      return null;
    }
  }

  /// Update an existing service
  static Future<bool> updateService(ServiceModel service) async {
    try {
      if (service.id == null) return false;
      
      final updatedService = service.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(service.id)
          .update(updatedService.toMap());
      
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  /// Delete a service
  static Future<bool> deleteService(String serviceId) async {
    try {
      await _firestore.collection(_collection).doc(serviceId).delete();
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  /// Toggle service active status
  static Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling service status: $e');
      return false;
    }
  }

  /// Update service sort order
  static Future<bool> updateSortOrder(String serviceId, int sortOrder) async {
    try {
      await _firestore.collection(_collection).doc(serviceId).update({
        'sortOrder': sortOrder,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error updating sort order: $e');
      return false;
    }
  }

  /// Initialize default services if none exist
  static Future<void> initializeDefaultServices() async {
    try {
      final existingServices = await getAllServices();
      if (existingServices.isNotEmpty) return;

      final defaultServices = [
        ServiceModel(
          title: 'Book Appointment',
          subtitle: 'Schedule visit',
          description: 'Schedule appointments with veterinarians and pet care professionals.',
          iconName: 'calendar_today',
          backgroundColor: '#8E44AD',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          title: 'Emergency Hotline',
          subtitle: '24/7 support',
          description: 'Get immediate help for pet emergencies with our 24/7 hotline.',
          iconName: 'phone',
          backgroundColor: '#007AFF',
          sortOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          title: 'First Aid Guide',
          subtitle: 'Emergency tips',
          description: 'Learn essential first aid techniques for pet emergencies.',
          iconName: 'medical_services',
          backgroundColor: '#FF9500',
          sortOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ServiceModel(
          title: 'Pet Care Tips',
          subtitle: 'Daily care',
          description: 'Discover helpful tips and advice for daily pet care.',
          iconName: 'lightbulb_outline',
          backgroundColor: '#34C759',
          sortOrder: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final service in defaultServices) {
        await addService(service);
      }
    } catch (e) {
      print('Error initializing default services: $e');
    }
  }
}