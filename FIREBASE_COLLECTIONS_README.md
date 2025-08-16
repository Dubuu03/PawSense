# PawSense Firebase Collections Documentation

## Overview
This document outlines all Firebase Firestore collections required for the PawSense veterinary management system. Each collection is designed based on the existing data models and business requirements.

---

## 📚 Collection Structure

### 1. Users Collection (`users`)
**Path:** `/users/{userId}`

```javascript
{
  uid: string,                    // Firebase Auth UID (document ID)
  username: string,               // Display name
  email: string,                  // User email
  role: string,                   // "user" | "admin" | "super_admin"
  profileImageUrl: string?,       // Profile picture URL
  darkTheme: boolean,            // User theme preference
  createdAt: timestamp,          // Account creation date
  dateOfBirth: timestamp?,       // User's birth date
  contactNumber: string?,        // Phone number
  address: string?,              // Physical address
  agreedToTerms: boolean?,       // Terms acceptance
  isEmailVerified: boolean,      // Email verification status
  lastLoginAt: timestamp?,       // Last login time
  isActive: boolean              // Account status
}
```

**Indexes:**
- `role` (for admin queries)
- `email` (for lookups)
- `createdAt` (for sorting)

---

### 2. Appointments Collection (`appointments`)
**Path:** `/appointments/{appointmentId}`

```javascript
{
  id: string,                    // Unique appointment ID
  date: string,                  // Appointment date (YYYY-MM-DD)
  time: string,                  // Time slot (HH:MM)
  petName: string,               // Pet's name
  petType: string,               // "dog" | "cat" | "bird" | "rabbit" | etc.
  petEmoji: string,              // Pet emoji for display
  ownerName: string,             // Pet owner's name
  ownerPhone: string,            // Owner's contact number
  diseaseReason: string,         // Reason for visit/suspected condition
  status: string,                // "pending" | "confirmed" | "completed" | "cancelled"
  userId: string,                // Reference to user document
  vetId: string?,                // Assigned veterinarian ID
  clinicId: string,              // Reference to clinic document
  notes: string?,                // Additional notes
  diagnosis: string?,            // Final diagnosis (after appointment)
  treatment: string?,            // Treatment provided
  followUpDate: timestamp?,      // Follow-up appointment date
  createdAt: timestamp,          // Creation time
  updatedAt: timestamp,          // Last modification
  notificationSent: boolean,     // Reminder notification status
  totalCost: number?,            // Appointment cost
  paymentStatus: string?         // "pending" | "paid" | "cancelled"
}
```

**Indexes:**
- `userId` + `status`
- `vetId` + `date`
- `clinicId` + `date`
- `status` + `date`

---

### 3. Patients Collection (`patients`)
**Path:** `/patients/{patientId}`

```javascript
{
  id: string,                    // Unique patient ID
  name: string,                  // Pet's name
  breed: string,                 // Pet breed
  type: string,                  // Animal type
  petIcon: string,               // Emoji or icon identifier
  age: string,                   // Pet's age
  weight: string,                // Pet's weight
  ownerId: string,               // Reference to owner (user)
  ownerName: string,             // Owner's name (denormalized)
  status: string,                // "healthy" | "treatment" | "emergency" | "recovered"
  confidencePercentage: number,  // AI diagnosis confidence (0-100)
  diseaseDetection: string,      // Current/detected condition
  lastVisit: timestamp,          // Last appointment date
  nextVisit: timestamp?,         // Next scheduled visit
  medicalHistory: array,         // Array of medical records
  vaccinations: array,           // Vaccination records
  allergies: array?,             // Known allergies
  medications: array?,           // Current medications
  vetId: string?,                // Primary veterinarian
  clinicId: string,              // Primary clinic
  createdAt: timestamp,          // Record creation
  updatedAt: timestamp,          // Last update
  isArchived: boolean,           // Archive status
  emergencyContact: string?      // Emergency contact info
}
```

**Medical History Sub-collection:** `/patients/{patientId}/medical_records/{recordId}`
```javascript
{
  id: string,
  date: timestamp,
  diagnosis: string,
  treatment: string,
  vetId: string,
  notes: string?,
  followUpRequired: boolean,
  createdAt: timestamp
}
```

**Indexes:**
- `ownerId` + `status`
- `vetId` + `lastVisit`
- `clinicId` + `status`
- `status` + `nextVisit`

---

### 4. Support Tickets Collection (`support_tickets`)
**Path:** `/support_tickets/{ticketId}`

```javascript
{
  id: string,                    // Unique ticket ID
  title: string,                 // Ticket subject
  description: string,           // Detailed description
  submitterName: string,         // User who submitted
  submitterEmail: string,        // Submitter's email
  userId: string?,               // Reference to user (if logged in)
  category: string,              // "technical" | "billing" | "general" | "emergency"
  priority: string,              // "low" | "medium" | "high" | "urgent"
  status: string,                // "open" | "in_progress" | "resolved" | "closed"
  assignedTo: string?,           // Admin user ID handling the ticket
  assignedToName: string?,       // Admin name (denormalized)
  createdAt: timestamp,          // Ticket creation
  lastReply: timestamp,          // Last response time
  resolvedAt: timestamp?,        // Resolution time
  isFavorited: boolean,          // Admin favorite status
  isArchived: boolean,           // Archive status
  attachments: array?,           // File attachments
  tags: array?                   // Categorization tags
}
```

**Replies Sub-collection:** `/support_tickets/{ticketId}/replies/{replyId}`
```javascript
{
  id: string,
  message: string,
  authorId: string,
  authorName: string,
  authorRole: string,            // "user" | "admin" | "system"
  createdAt: timestamp,
  attachments: array?,
  isInternal: boolean            // Internal admin note
}
```

**Indexes:**
- `status` + `priority`
- `assignedTo` + `status`
- `category` + `createdAt`
- `userId` + `status`

---

### 5. Clinics Collection (`clinics`)
**Path:** `/clinics/{clinicId}`

```javascript
{
  id: string,                    // Unique clinic ID
  name: string,                  // Clinic name
  address: string,               // Full address
  phone: string,                 // Contact number
  email: string,                 // Contact email
  services: string,              // Services offered (comma-separated or array)
  operatingHours: object,        // Operating schedule
  adminIds: array,               // Array of admin user IDs
  isActive: boolean,             // Operational status
  rating: number?,               // Average rating (0-5)
  totalReviews: number?,         // Review count
  createdAt: timestamp,          // Registration date
  updatedAt: timestamp,          // Last modification
  coordinates: geopoint?,        // Location coordinates
  website: string?,              // Website URL
  specializations: array?,       // Veterinary specializations
  equipmentList: array?          // Available equipment
}
```

**Indexes:**
- `isActive` + `rating`
- `adminIds` (array-contains)
- Geographic queries on `coordinates`

---

### 6. FAQs Collection (`faqs`)
**Path:** `/faqs/{faqId}`

```javascript
{
  id: string,                    // Unique FAQ ID
  question: string,              // FAQ question
  answer: string,                // Detailed answer
  category: string,              // "general" | "appointments" | "pets" | "billing"
  views: number,                 // View count
  helpfulVotes: number,          // Helpful votes count
  unhelpfulVotes: number?,       // Unhelpful votes
  tags: array?,                  // Search tags
  isPublished: boolean,          // Publication status
  authorId: string,              // Admin who created
  createdAt: timestamp,          // Creation date
  updatedAt: timestamp,          // Last modification
  searchKeywords: array          // Keywords for search optimization
}
```

**Indexes:**
- `category` + `isPublished`
- `views` (descending)
- `helpfulVotes` (descending)

---

### 7. Schedules Collection (`schedules`)
**Path:** `/schedules/{scheduleId}`

```javascript
{
  id: string,                    // Unique schedule ID
  vetId: string,                 // Veterinarian ID
  clinicId: string,              // Clinic ID
  date: string,                  // Date (YYYY-MM-DD)
  dayOfWeek: string,             // "monday" | "tuesday" | etc.
  timeSlots: array,              // Array of time slot objects
  isActive: boolean,             // Schedule status
  createdAt: timestamp,          // Creation date
  updatedAt: timestamp           // Last modification
}
```

**Time Slot Object Structure:**
```javascript
{
  startTime: string,             // "09:00"
  endTime: string,               // "09:30"
  type: string,                  // "consultation" | "surgery" | "emergency"
  maxAppointments: number,       // Maximum appointments in slot
  currentAppointments: number,   // Current bookings
  isAvailable: boolean,          // Availability status
  utilizationPercentage: number  // Utilization rate (0-100)
}
```

**Indexes:**
- `vetId` + `date`
- `clinicId` + `date`
- `date` + `isActive`

---

### 8. Diseases Collection (`diseases`)
**Path:** `/diseases/{diseaseId}`

```javascript
{
  id: string,                    // Unique disease ID
  name: string,                  // Disease name
  description: string,           // Detailed description
  symptoms: array,               // Common symptoms
  treatments: array,             // Treatment options
  animalTypes: array,            // Affected animal types
  severity: string,              // "low" | "medium" | "high" | "critical"
  isContagious: boolean,         // Contagious status
  detectionCount: number,        // AI detection frequency
  confidence: number,            // AI detection confidence
  preventionTips: array?,        // Prevention advice
  vetRecommended: boolean,       // Requires vet consultation
  createdAt: timestamp,          // Record creation
  updatedAt: timestamp           // Last update
}
```

**Indexes:**
- `animalTypes` (array-contains)
- `severity` + `detectionCount`
- `isContagious` + `animalTypes`

---

### 9. Veterinarian Profiles Collection (`vet_profiles`)
**Path:** `/vet_profiles/{vetId}`

```javascript
{
  id: string,                    // Veterinarian ID (same as userId)
  licenseNumber: string,         // Professional license
  specializations: array,        // Areas of expertise
  experience: number,            // Years of experience
  education: array,              // Educational background
  clinicId: string,              // Primary clinic
  isAvailable: boolean,          // Current availability
  workingHours: object,          // Working schedule
  consultationFee: number?,      // Consultation cost
  rating: number?,               // Average rating
  totalReviews: number?,         // Review count
  bio: string?,                  // Professional biography
  certifications: array?,        // Professional certifications
  languages: array?,             // Spoken languages
  createdAt: timestamp,          // Profile creation
  updatedAt: timestamp           // Last update
}
```

**Indexes:**
- `clinicId` + `isAvailable`
- `specializations` (array-contains)
- `rating` (descending)

---

### 10. Notifications Collection (`notifications`)
**Path:** `/notifications/{notificationId}`

```javascript
{
  id: string,                    // Unique notification ID
  userId: string,                // Target user ID
  title: string,                 // Notification title
  message: string,               // Notification content
  type: string,                  // "appointment" | "reminder" | "system" | "promotion"
  priority: string,              // "low" | "medium" | "high"
  isRead: boolean,               // Read status
  actionUrl: string?,            // Deep link URL
  actionLabel: string?,          // Action button text
  imageUrl: string?,             // Notification image
  scheduledFor: timestamp?,      // Scheduled delivery time
  sentAt: timestamp?,            // Actual sent time
  readAt: timestamp?,            // Read timestamp
  createdAt: timestamp,          // Creation time
  expiresAt: timestamp?,         // Expiration time
  metadata: object?              // Additional data
}
```

**Indexes:**
- `userId` + `isRead`
- `userId` + `createdAt`
- `type` + `scheduledFor`

---

### 11. Activity Logs Collection (`activity_logs`)
**Path:** `/activity_logs/{logId}`

```javascript
{
  id: string,                    // Unique log ID
  userId: string,                // User who performed action
  action: string,                // Action performed
  entityType: string,            // "appointment" | "patient" | "user" | etc.
  entityId: string,              // ID of affected entity
  description: string,           // Human-readable description
  ipAddress: string?,            // User's IP address
  userAgent: string?,            // Browser/app info
  timestamp: timestamp,          // Action timestamp
  metadata: object?              // Additional context data
}
```

**Indexes:**
- `userId` + `timestamp`
- `entityType` + `timestamp`
- `action` + `timestamp`

---

### 12. Settings Collection (`settings`)
**Path:** `/settings/{settingId}`

```javascript
{
  id: string,                    // Setting identifier
  key: string,                   // Setting key name
  value: any,                    // Setting value
  type: string,                  // "system" | "clinic" | "user"
  scope: string,                 // "global" | "clinic" | "user"
  description: string?,          // Setting description
  isPublic: boolean,             // Public visibility
  updatedBy: string,             // Last updater ID
  createdAt: timestamp,          // Creation time
  updatedAt: timestamp           // Last update
}
```

---

## 🔒 Security Rules Summary

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin'];
    }
    
    // Appointments - users see their own, admins see all
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin']);
    }
    
    // Patients - similar to appointments
    match /patients/{patientId} {
      allow read, write: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin']);
    }
    
    // Support tickets - users see their own, admins see all
    match /support_tickets/{ticketId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin']);
    }
    
    // Public read access for FAQs and diseases
    match /faqs/{faqId} {
      allow read: if resource.data.isPublished == true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin'];
    }
    
    match /diseases/{diseaseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin'];
    }
    
    // Admin-only collections
    match /{adminCollection}/{docId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'super_admin'];
      
      // adminCollection includes: clinics, vet_profiles, schedules, settings, activity_logs
    }
  }
}
```

---

## 📊 Data Relationships

### Primary Relationships:
- `users` ↔ `appointments` (userId)
- `users` ↔ `patients` (ownerId)
- `users` ↔ `support_tickets` (userId)
- `users` ↔ `notifications` (userId)
- `clinics` ↔ `appointments` (clinicId)
- `vet_profiles` ↔ `appointments` (vetId)
- `patients` ↔ `appointments` (petName + ownerId lookup)

### Sub-collections:
- `patients/{patientId}/medical_records`
- `support_tickets/{ticketId}/replies`

---

## 🚀 Implementation Priority

### Phase 1 (Core Functionality):
1. `users` - User management
2. `appointments` - Appointment booking
3. `patients` - Patient records
4. `clinics` - Clinic information

### Phase 2 (Extended Features):
5. `support_tickets` - Customer support
6. `notifications` - User notifications
7. `faqs` - Help system
8. `vet_profiles` - Veterinarian profiles

### Phase 3 (Advanced Features):
9. `schedules` - Schedule management
10. `diseases` - Disease database
11. `activity_logs` - Audit trails
12. `settings` - System configuration

---

## 📝 Notes

- All timestamps are stored as Firestore timestamp type
- Use composite indexes for complex queries
- Implement proper pagination for large collections
- Consider data denormalization for frequently accessed fields
- Set up Cloud Functions for complex business logic
- Use Firebase Security Rules for data validation
- Implement offline support with local caching
- Monitor query performance and optimize indexes

This structure provides a comprehensive foundation for the PawSense veterinary management system with room for future expansion.
