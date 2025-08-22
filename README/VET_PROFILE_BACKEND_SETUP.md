# Vet Profile Screen - Backend Integration Setup

This guide will help you set up the backend integration for the Vet Profile screen with Firestore.

## Overview

I've implemented a complete backend integration for your Vet Profile screen using your existing models:

- **VetProfileService**: Handles all Firestore operations
- **Sample Data Utility**: Helps you populate test data
- **Real-time Updates**: Changes are saved to Firestore and cached for performance

## Files Created/Modified

### New Files:
1. `lib/core/services/vet_profile_service.dart` - Backend service
2. `lib/core/utils/firestore_sample_data_util.dart` - Sample data utility  
3. `sample_firestore_data.json` - Manual data reference

### Modified Files:
1. `lib/pages/web/admin/vet_profile_screen.dart` - Updated to use backend

## Features Implemented

### ✅ Data Loading
- Fetches clinic info from `clinics` collection
- Fetches detailed info from `clinicDetails` collection  
- Loads services, certifications, and specializations
- 5-minute caching for performance

### ✅ Real-time Updates
- Toggle emergency availability ✨
- Toggle telemedicine availability ✨
- Enable/disable services ✨
- Delete services ✨

### ✅ Error Handling
- Loading states
- Error messages with retry
- Success/failure notifications

## Quick Setup (Recommended)

### Option A: Use the Built-in Sample Data Button

1. **Login to your app** as an admin user
2. **Navigate to Vet Profile screen** (`/admin/vet-profile`)
3. **You'll see an error** (expected - no data yet)
4. **Click "Add Sample Data"** button
5. **Wait for success message**
6. **The screen will reload** with populated data

### Option B: Manual Firestore Setup

If you prefer to add data manually:

1. **Open Firebase Console**
2. **Go to Firestore Database**
3. **Use the sample data** from `sample_firestore_data.json`
4. **Replace 'your-user-uid'** with your actual user UID
5. **Create the collections** as shown in the JSON file

## Data Structure

The integration uses your existing models:

```
🗂️ Collections Used:
├── users/{userUid}           - User info (UserModel)
├── clinics/{userUid}         - Basic clinic info (Clinic model) 
└── clinicDetails/{docId}     - Detailed info (ClinicDetails model)
    ├── services[]            - Array of ClinicService
    ├── certifications[]      - Array of ClinicCertification  
    └── specialties[]         - Array of strings
```

## Testing the Features

Once data is loaded, you can test:

1. **Emergency Toggle** - Click the emergency availability switch
2. **Telemedicine Toggle** - Click the telemedicine switch  
3. **Service Management** - Toggle services on/off, delete services
4. **Data Persistence** - Refresh page to see changes persist

## Key Backend Functions

### VetProfileService Methods:
- `getVetProfile()` - Loads complete profile data
- `updateEmergencyAvailability(bool)` - Updates emergency status
- `updateTelemedicineAvailability(bool)` - Updates telemedicine status
- `toggleServiceStatus(id, status)` - Enable/disable service
- `deleteService(id)` - Remove service

### Caching Strategy:
- **User data**: 5 minutes (AuthGuard)
- **Profile data**: 5 minutes (VetProfileService)
- **Auto-clear on updates** for real-time consistency

## Sample Data Details

The sample data includes:

### 👨‍⚕️ Doctor Info:
- Dr. Sarah Johnson
- PawSense Veterinary Clinic
- Complete contact information

### 🏥 Services (5 total):
- General Consultation (₱750)
- Skin Scraping & Analysis (₱1200)  
- Vaccination Package (₱950)
- Dental Cleaning (₱2500)
- Emergency Surgery (₱15000)

### 📜 Certifications (3 total):
- DVM - Doctor of Veterinary Medicine
- Certified Animal Dermatologist
- Licensed Veterinary Dentist

### 🎯 Specializations (5 total):
- Small Animal Care
- Dermatology
- Dentistry
- Emergency Medicine
- Surgical Procedures

## Troubleshooting

### Issue: "Error loading profile" 
**Solution**: Click "Add Sample Data" or check Firebase Auth

### Issue: "Failed to add sample data"
**Solution**: Check Firebase permissions and user authentication

### Issue: Changes not saving
**Solution**: Check Firestore security rules allow read/write for authenticated users

### Issue: Compilation errors
**Solution**: Run `flutter clean && flutter pub get`

## Security Rules

Make sure your Firestore security rules allow authenticated users to read/write their own clinic data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read/write their own clinic data  
    match /clinics/{clinicId} {
      allow read, write: if request.auth != null && request.auth.uid == clinicId;
    }
    
    // Users can read/write clinic details for their clinics
    match /clinicDetails/{docId} {
      allow read, write: if request.auth != null && 
        resource.data.clinicId == request.auth.uid;
    }
  }
}
```

## Next Steps

After testing the basic functionality, you can:

1. **Add service creation UI** - Form to add new services
2. **Add certification upload** - File upload for certificates  
3. **Add specialization management** - Add/remove specialties
4. **Add profile editing** - Edit basic clinic information
5. **Add image upload** - Clinic logo and gallery images

## Support

If you encounter any issues:

1. Check the Flutter console for error messages
2. Check Firebase Console for Firestore errors
3. Verify your user is properly authenticated  
4. Make sure Firestore security rules are configured correctly

The integration is fully functional and ready for testing! 🚀
