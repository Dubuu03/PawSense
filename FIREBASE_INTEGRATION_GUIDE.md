# Firebase Integration Guide for PawSense

## Overview
This guide outlines the steps needed to integrate Firebase with PawSense, replacing mock data with real Firebase services.

## Prerequisites
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication, Firestore, and Storage services
3. Configure authentication methods (Email/Password)

## Integration Steps

### 1. Firebase Configuration
Replace the mock data service with Firebase services:

```dart
// In DataService class, set _useFirebase = true
void enableFirebase(bool enabled) {
  _useFirebase = enabled;
}
```

### 2. Authentication Integration

Update `AuthServiceMobile` and `AuthServiceWeb`:
```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceMobile {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Replace mock implementation with Firebase
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      handleError('signInWithEmailPassword', e);
      return null;
    }
  }
}
```

### 3. Firestore Integration

#### User Collection Structure
```
users/
  {uid}/
    username: string
    email: string
    role: string (user|admin|super_admin)
    contactNumber: string?
    address: string?
    dateOfBirth: timestamp?
    createdAt: timestamp
    isEmailVerified: boolean
```

#### Appointments Collection Structure
```
appointments/
  {appointmentId}/
    petName: string
    petType: string
    ownerName: string
    ownerPhone: string
    appointmentDate: timestamp
    timeSlot: string
    status: string (pending|confirmed|completed|cancelled)
    diseaseReason: string
    notes: string?
    createdAt: timestamp
    updatedAt: timestamp
    vetId: string (reference to admin user)
```

#### Patients Collection Structure
```
patients/
  {patientId}/
    name: string
    breed: string
    type: string (dog|cat|bird|etc)
    age: string
    weight: string
    ownerId: string (reference to user)
    ownerName: string
    status: string (healthy|treatment|emergency)
    confidencePercentage: number
    lastVisit: timestamp
    medicalHistory: array
    vaccinations: array
    createdAt: timestamp
    updatedAt: timestamp
```

#### Support Tickets Collection Structure
```
support_tickets/
  {ticketId}/
    title: string
    description: string
    category: string
    status: string (open|in_progress|resolved|closed)
    priority: string (low|medium|high|urgent)
    submitterName: string
    submitterEmail: string
    assignedTo: string? (admin user ID)
    createdAt: timestamp
    updatedAt: timestamp
    lastReply: timestamp
    isArchived: boolean
```

### 4. Update DataService Implementation

```dart
Future<UserModel?> getCurrentUser() async {
  if (_useFirebase) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    }
    return null;
  }
  // Return mock data...
}

Future<List<Appointment>> getAppointments({
  DateTime? startDate,
  DateTime? endDate,
  String? status,
}) async {
  if (_useFirebase) {
    Query query = FirebaseFirestore.instance
        .collection(FirebaseCollections.appointments);
    
    if (startDate != null) {
      query = query.where('appointmentDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('appointmentDate', isLessThanOrEqualTo: endDate);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => 
        Appointment.fromMap(doc.data() as Map<String, dynamic>)
    ).toList();
  }
  // Return mock data...
}
```

### 5. Security Rules

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admins can read all appointments
    match /appointments/{appointmentId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin']);
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin'];
    }
    
    // Similar rules for patients, support_tickets, etc.
  }
}
```

### 6. Cloud Functions (Optional)

For complex operations like sending notifications:
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendAppointmentReminder = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {
    const appointment = snap.data();
    // Send email/SMS reminder logic
  });
```

### 7. Error Handling

Update error handling throughout the app:
```dart
void handleError(String operation, dynamic error) {
  if (kDebugMode) {
    print('DataService Error in $operation: $error');
  }
  
  // Log to Firebase Crashlytics
  FirebaseCrashlytics.instance.recordError(
    error,
    null,
    reason: 'DataService: $operation',
  );
  
  // Show user-friendly error message
  // Implementation depends on your UI framework
}
```

### 8. Performance Optimization

1. Use pagination for large datasets
2. Implement offline support with local caching
3. Use Firebase Performance Monitoring
4. Optimize queries with proper indexing

### 9. Testing

Create integration tests for Firebase services:
```dart
testWidgets('should fetch appointments from Firebase', (tester) async {
  // Setup test Firebase project
  await Firebase.initializeApp();
  
  final dataService = DataService();
  dataService.enableFirebase(true);
  
  final appointments = await dataService.getAppointments();
  expect(appointments, isNotEmpty);
});
```

### 10. Migration Strategy

1. Start with one collection at a time
2. Run both mock and Firebase in parallel during development
3. Use feature flags to toggle between mock and real data
4. Test thoroughly before switching production traffic

## Environment Configuration

Create different Firebase projects for development, staging, and production:

```dart
// lib/core/config/environment.dart
class Environment {
  static const String dev = 'development';
  static const String staging = 'staging';
  static const String prod = 'production';
  
  static String get current {
    return const String.fromEnvironment('ENVIRONMENT', defaultValue: dev);
  }
  
  static bool get isProduction => current == prod;
  static bool get useFirebase => current != dev;
}
```

## Monitoring and Analytics

1. Set up Firebase Analytics for user behavior tracking
2. Use Performance Monitoring for app performance insights
3. Configure Crashlytics for error tracking
4. Set up Remote Config for feature flags

This comprehensive integration plan ensures a smooth transition from mock data to a fully functional Firebase backend while maintaining code quality and user experience.
