import 'package:cloud_firestore/cloud_firestore.dart';
import '../guards/auth_guard.dart';

/// Utility class for adding sample data to Firestore
/// Use this for testing the VetProfileScreen
class FirestoreSampleDataUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Add sample data for the current authenticated user
  /// Call this method once to populate your Firestore with test data
  static Future<bool> addSampleVetProfileData() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        print('No authenticated user found');
        return false;
      }
      
      final userUid = currentUser.uid;
      print('Adding sample data for user: $userUid');
      
      // 1. Update user document (if needed)
      await _firestore.collection('users').doc(userUid).set({
        'uid': userUid,
        'username': 'Dr. Sarah Johnson',
        'email': currentUser.email,
        'role': 'admin',
        'firstName': 'Sarah',
        'lastName': 'Johnson',
        'contactNumber': '+1 (555) 123-4567',
        'createdAt': DateTime.now().toIso8601String(),
        'darkTheme': false,
        'agreedToTerms': true,
      }, SetOptions(merge: true));
      
      // 2. Add/Update clinic document
      await _firestore.collection('clinics').doc(userUid).set({
        'id': userUid,
        'userId': userUid,
        'clinicName': 'PawSense Veterinary Clinic',
        'address': '123 Pet Care Lane, Animal City, AC 12345',
        'phone': '+1 (555) 123-4567',
        'email': 'clinic@pawsense.com',
        'website': 'www.pawsense.com',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // 3. Add clinic details document
      final clinicDetailsId = 'clinic_details_$userUid';
      await _firestore.collection('clinicDetails').doc(clinicDetailsId).set({
        'id': clinicDetailsId,
        'clinicId': userUid,
        'clinicName': 'PawSense Veterinary Clinic',
        'description': 'Premier veterinary care facility providing comprehensive medical services for pets',
        'address': '123 Pet Care Lane, Animal City, AC 12345',
        'phone': '+1 (555) 123-4567',
        'email': 'clinic@pawsense.com',
        'operatingHours': 'Mon-Fri: 8AM-6PM, Sat: 9AM-4PM, Sun: Emergency Only',
        'specialties': [
          'Small Animal Care',
          'Dermatology',
          'Dentistry',
          'Emergency Medicine',
          'Surgical Procedures'
        ],
        'services': _getSampleServices(userUid),
        'certifications': _getSampleCertifications(userUid),
        'isVerified': true,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'logoUrl': null,
        'bannerUrl': null,
        'galleryImages': null,
        'socialMedia': {
          'facebook': 'https://facebook.com/pawsenseclinic',
          'instagram': '@pawsenseclinic'
        },
        'location': {
          'latitude': 14.5995,
          'longitude': 120.9842
        },
        'timezone': 'Asia/Manila'
      });
      
      print('Sample data added successfully!');
      return true;
      
    } catch (e) {
      print('Error adding sample data: $e');
      return false;
    }
  }
  
  /// Get sample services data
  static List<Map<String, dynamic>> _getSampleServices(String userUid) {
    return [
      {
        'id': 'service_1_$userUid',
        'clinicId': userUid,
        'serviceName': 'General Consultation',
        'serviceDescription': 'Comprehensive health examination and consultation for your pet',
        'estimatedPrice': 'PHP 750.00',
        'duration': '30 minutes',
        'category': 'consultation',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'service_2_$userUid',
        'clinicId': userUid,
        'serviceName': 'Skin Scraping & Analysis',
        'serviceDescription': 'Microscopic examination for skin conditions and parasites',
        'estimatedPrice': 'PHP 1200.00',
        'duration': '45 minutes',
        'category': 'diagnostic',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'service_3_$userUid',
        'clinicId': userUid,
        'serviceName': 'Vaccination Package',
        'serviceDescription': 'Complete vaccination schedule for puppies and kittens',
        'estimatedPrice': 'PHP 950.00',
        'duration': '20 minutes',
        'category': 'preventive',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'service_4_$userUid',
        'clinicId': userUid,
        'serviceName': 'Dental Cleaning',
        'serviceDescription': 'Professional dental cleaning and oral health assessment',
        'estimatedPrice': 'PHP 2500.00',
        'duration': '90 minutes',
        'category': 'other',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'service_5_$userUid',
        'clinicId': userUid,
        'serviceName': 'Emergency Surgery',
        'serviceDescription': '24/7 emergency surgical procedures for critical cases',
        'estimatedPrice': 'PHP 15000.00',
        'duration': '2-4 hours',
        'category': 'emergency',
        'isActive': false, // Disabled by default
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }
  
  /// Get sample certifications data
  static List<Map<String, dynamic>> _getSampleCertifications(String userUid) {
    final now = DateTime.now();
    return [
      {
        'id': 'cert_1_$userUid',
        'clinicId': userUid,
        'name': 'DVM - Doctor of Veterinary Medicine',
        'issuer': 'Animal Care University',
        'dateIssued': Timestamp.fromDate(DateTime(2015, 1, 15)),
        'dateExpiry': null,
        'status': 'approved',
        'documentUrl': null,
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 'cert_2_$userUid',
        'clinicId': userUid,
        'name': 'Certified Animal Dermatologist',
        'issuer': 'Veterinary Dermatology Association',
        'dateIssued': Timestamp.fromDate(DateTime(2018, 5, 1)),
        'dateExpiry': Timestamp.fromDate(DateTime(2028, 5, 1)),
        'status': 'approved',
        'documentUrl': null,
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 'cert_3_$userUid',
        'clinicId': userUid,
        'name': 'Licensed Veterinary Dentist',
        'issuer': 'Dental Veterinarians International',
        'dateIssued': Timestamp.fromDate(DateTime(2020, 9, 15)),
        'dateExpiry': null,
        'status': 'approved',
        'documentUrl': null,
        'createdAt': now.toIso8601String(),
      },
    ];
  }
  
  /// Clear all sample data (use for cleanup)
  static Future<bool> clearSampleData() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      final userUid = currentUser.uid;
      
      // Delete clinic details
      final clinicDetailsQuery = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: userUid)
          .get();
          
      for (final doc in clinicDetailsQuery.docs) {
        await doc.reference.delete();
      }
      
      print('Sample data cleared successfully!');
      return true;
      
    } catch (e) {
      print('Error clearing sample data: $e');
      return false;
    }
  }
}
