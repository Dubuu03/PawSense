# System Analytics - Data Model Analysis

**Date:** October 18, 2025  
**Phase:** 0 - Data Analysis (Pre-Implementation)  
**Status:** ✅ VERIFIED

---

## 📊 Data Model Verification Summary

### ✅ Verified Fields & Types

#### 1. **UserModel** (`lib/core/models/user/user_model.dart`)
```dart
class UserModel {
  final String uid;
  final String email;
  final String role;              // ✅ 'user' | 'admin' | 'super_admin'
  final bool isActive;            // ✅ true | false (suspension status)
  final DateTime createdAt;       // ✅ Timestamp field exists
  final String? firstName;
  final String? lastName;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final bool? agreedToTerms;
}
```

**Key Findings:**
- ✅ `isActive` field exists (bool) - for active/suspended filter
- ✅ `createdAt` exists (DateTime) - for growth trends
- ✅ `role` field values confirmed: 'user', 'admin', 'super_admin'
- ✅ `agreedToTerms` exists (nullable bool)

---

#### 2. **Clinic** (`lib/core/models/clinic/clinic_model.dart`)
```dart
class Clinic {
  final String id;
  final String userId;            // Admin UID
  final String clinicName;
  final String status;            // ✅ 'pending' | 'approved' | 'suspended' | 'rejected'
  final String scheduleStatus;    // ✅ 'pending' | 'in_progress' | 'completed'
  final bool isVisible;           // ✅ Only true when schedule completed
  final DateTime createdAt;       // ✅ Timestamp field exists
}
```

**Key Findings:**
- ✅ `status` field values: 'pending', 'approved', 'suspended', 'rejected'
- ✅ `scheduleStatus` for tracking setup progress
- ✅ `isVisible` boolean for filtering operational clinics
- ✅ `createdAt` exists for growth tracking

**Firestore Collections:**
- `clinics` - Main clinic data (approved only)
- `clinic_registrations` - Pending applications

---

#### 3. **Appointment** (`lib/core/models/clinic/appointment_models.dart`)
```dart
class Appointment {
  final String id;
  final String clinicId;
  final String date;              // String YYYY-MM-DD
  final String time;
  final Pet pet;                  // Embedded object
  final Owner owner;              // Embedded object
  final AppointmentStatus status; // ✅ Enum: pending, confirmed, completed, cancelled, rejected
  final DateTime createdAt;       // ✅ Timestamp
  final DateTime updatedAt;
  final DateTime? completedAt;    // ✅ For wait time calculation
  final String diseaseReason;
  final bool isFollowUp;
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rejected
}
```

**Key Findings:**
- ✅ `status` is ENUM (not string) - use `.name` for Firestore
- ✅ `completedAt` exists for wait time analysis
- ✅ Embedded `pet` and `owner` objects (follow-up format)
- ✅ Legacy format also exists (fetch separately)

**Firestore Collection:**
- `appointments` - All appointment records

---

#### 4. **Pet** (`lib/core/models/user/pet_model.dart`)
```dart
class Pet {
  final String? id;
  final String userId;            // Owner UID
  final String petName;
  final String petType;           // ✅ 'Dog', 'Cat', 'Bird', etc.
  final String breed;
  final int age;                  // ✅ In months
  final double weight;            // ✅ In kg
  final DateTime createdAt;       // ✅ Timestamp exists
}
```

**Key Findings:**
- ✅ `petType` values: 'Dog', 'Cat', 'Bird', etc. (capitalized)
- ✅ `age` in months (need conversion for analytics)
- ✅ `createdAt` exists

**Firestore Collection:**
- `pets` - Pet registration records

---

#### 5. **AssessmentResult** (`lib/core/models/user/assessment_result_model.dart`)
```dart
class AssessmentResult {
  final String? id;
  final String userId;
  final String petId;
  final List<DetectionResult> detectionResults;
  final List<AnalysisResultData> analysisResults;
  final DateTime createdAt;       // ✅ Timestamp exists
}

class DetectionResult {
  final String imageUrl;
  final List<Detection> detections;
}

class Detection {
  final String label;             // ✅ Disease name
  final double confidence;        // ✅ 0.0 - 1.0
}

class AnalysisResultData {
  final String condition;         // ✅ Disease name
  final double percentage;        // ✅ Confidence as percentage
}
```

**Key Findings:**
- ✅ `confidence` is double (0.0 - 1.0) - multiply by 100 for %
- ✅ Disease name in `label` field (DetectionResult)
- ✅ Alternative: `condition` in AnalysisResultData
- ✅ Multiple detections per image possible

**Firestore Collection:**
- `assessment_results` - AI scan records

---

## 🔧 Implementation Adjustments Required

### 1. **Appointment Status Handling**
**Issue:** Status is ENUM in model, string in Firestore

**Solution:**
```dart
// When querying Firestore
.where('status', isEqualTo: 'completed')  // Use string

// When parsing from Firestore
final statusStr = data['status'].toString();
final status = AppointmentStatus.values.firstWhere(
  (e) => e.name == statusStr,
  orElse: () => AppointmentStatus.pending,
);
```

---

### 2. **Pet Type Capitalization**
**Issue:** Pet types are capitalized ('Dog', 'Cat')

**Solution:**
```dart
// When grouping by type
final dogCount = pets.where((p) => p.petType == 'Dog').length;
final catCount = pets.where((p) => p.petType == 'Cat').length;
```

---

### 3. **Age Calculation**
**Issue:** Pet age in months, analytics need years/categories

**Solution:**
```dart
enum AgeCategory { puppy, young, adult, senior }

AgeCategory getAgeCategory(int ageInMonths, String petType) {
  if (petType == 'Dog') {
    if (ageInMonths < 12) return AgeCategory.puppy;
    if (ageInMonths < 36) return AgeCategory.young;
    if (ageInMonths < 84) return AgeCategory.adult;
    return AgeCategory.senior;
  } else { // Cat
    if (ageInMonths < 12) return AgeCategory.puppy; // kitten
    if (ageInMonths < 24) return AgeCategory.young;
    if (ageInMonths < 84) return AgeCategory.adult;
    return AgeCategory.senior;
  }
}
```

---

### 4. **AI Confidence Conversion**
**Issue:** Confidence is 0.0-1.0, need percentage

**Solution:**
```dart
// High confidence: >0.8 (80%)
final highConfidenceScans = assessments
    .where((a) => a.detectionResults.any(
        (d) => d.detections.any((det) => det.confidence > 0.8)
    ))
    .length;

// Average confidence
final avgConfidence = assessments
    .expand((a) => a.detectionResults)
    .expand((d) => d.detections)
    .map((det) => det.confidence)
    .fold(0.0, (sum, conf) => sum + conf) / totalDetections * 100;
```

---

### 5. **Wait Time Calculation**
**Issue:** Need createdAt to completedAt duration

**Solution:**
```dart
final waitTime = appointment.completedAt != null
    ? appointment.completedAt!.difference(appointment.createdAt).inHours
    : null;

final avgWaitTime = completedAppointments
    .where((a) => a.completedAt != null)
    .map((a) => a.completedAt!.difference(a.createdAt).inHours)
    .fold(0.0, (sum, hours) => sum + hours) / completedCount;
```

---

## 📝 Firestore Collection Summary

| Collection | Key Fields | Count Field | Status Field | Date Field |
|------------|-----------|-------------|--------------|-----------|
| `users` | uid, role, isActive | uid (count) | isActive (bool) | createdAt |
| `clinics` | id, status, isVisible | id (count) | status (string) | createdAt |
| `clinic_registrations` | status | id (count) | status (string) | createdAt |
| `appointments` | clinicId, status | id (count) | status (string) | createdAt, completedAt |
| `pets` | userId, petType | id (count) | - | createdAt |
| `assessment_results` | userId, detectionResults | id (count) | - | createdAt |
| `skin_diseases` | name, viewCount | id (count) | - | createdAt |

---

## ✅ Validation Checklist

- [x] UserModel fields verified
- [x] Clinic model fields verified  
- [x] Appointment model fields verified
- [x] Pet model fields verified
- [x] AssessmentResult model fields verified
- [x] Firestore collections documented
- [x] Status value mappings confirmed
- [x] Timestamp handling documented
- [x] Edge cases identified
- [x] Conversion functions planned

---

## 🚀 Ready for Implementation

**All data models verified. Proceeding to Phase 1: Analytics Models Creation.**

**Critical Notes:**
1. ✅ Use `AppointmentStatus.name` for Firestore queries
2. ✅ Pet types are capitalized: 'Dog', 'Cat'
3. ✅ Confidence is 0.0-1.0 (multiply by 100 for %)
4. ✅ Clinic status values: 'pending', 'approved', 'suspended', 'rejected'
5. ✅ Use client-side aggregation (fetch all, filter in Dart)

---

**Next Step:** Create `system_analytics_models.dart` with verified field mappings.
