# Clinic Recommendation System Setup Guide

## Overview

The PawSense app now includes an intelligent clinic recommendation system that suggests clinics to users based on detected skin diseases. This guide explains how to set up and configure the system.

## Features

✅ **Smart Matching**: Automatically recommends clinics specializing in detected skin diseases  
✅ **Assessment Integration**: Shows recommended clinics after disease detection in assessments  
✅ **Library Integration**: Displays recommended clinics when viewing disease details  
✅ **Multiple Disease Support**: Recommends clinics that treat multiple detected conditions  
✅ **Match Scoring**: Ranks clinics by specialty relevance (Exact Match, Primary, Related, General)

## Architecture

### Components Created

1. **ClinicRecommendationService** (`lib/core/services/clinic/clinic_recommendation_service.dart`)
   - Matches diseases with clinic specialties
   - Scores and ranks clinics by relevance
   - Supports single and multiple disease matching

2. **RecommendedClinicsWidget** (`lib/core/widgets/user/clinic/recommended_clinics_widget.dart`)
   - Reusable UI component for displaying recommended clinics
   - Shows clinic cards with match type badges
   - Handles navigation to booking

3. **Updated Components**:
   - `AssessmentStepThree`: Shows recommended clinics after disease detection
   - `SkinDiseaseDetailPage`: Displays recommended clinics when viewing disease info

## Manual Setup Required

### Step 1: Add `specialties` Field to Clinic Documents

Each clinic in Firestore needs a `specialties` array that lists the skin diseases they treat.

#### Via Firebase Console:

1. Open Firebase Console → Firestore Database
2. Navigate to `clinicDetails` collection
3. For each clinic document, add a new field:
   - **Field name**: `specialties`
   - **Type**: array
   - **Values**: List of skin disease names (strings)

#### Example Structure:

```javascript
{
  id: "clinic_details_ABC123",
  clinicId: "ABC123",
  clinicName: "Happy Paws Veterinary Clinic",
  address: "123 Main Street, Manila",
  phone: "+63 912 345 6789",
  email: "contact@happypaws.com",
  description: "Full-service veterinary clinic",
  
  // ADD THIS FIELD ⬇️
  specialties: [
    "Flea Allergy Dermatitis",
    "Hot Spots",
    "Ringworm",
    "Skin Infections",
    "Allergic Dermatitis",
    "Mange",
    "General Dermatology"
  ],
  
  // Other existing fields...
  operatingHours: "Mon-Fri: 8AM-6PM",
  services: [...],
  certifications: [...],
  isVerified: true,
  isActive: true
}
```

### Step 2: Match Specialties with Disease Names

Ensure the specialty names match the disease names in your `skin_diseases` collection for accurate matching.

#### Common Skin Diseases to Include:

**Parasitic Conditions:**
- Flea Allergy Dermatitis
- Mange (Sarcoptic/Demodectic)
- Tick Infestation
- Lice Infestation

**Fungal Infections:**
- Ringworm
- Yeast Infections
- Malassezia Dermatitis

**Bacterial Infections:**
- Pyoderma
- Hot Spots (Acute Moist Dermatitis)
- Folliculitis
- Impetigo

**Allergic Conditions:**
- Atopic Dermatitis
- Food Allergies
- Contact Dermatitis
- Environmental Allergies

**Autoimmune Disorders:**
- Pemphigus
- Lupus
- Sebaceous Adenitis

**Other Conditions:**
- Alopecia
- Seborrhea
- Acne (Feline/Canine)
- Calluses
- Pressure Sores

### Step 3: Update Existing Clinic Data

If you already have clinics in Firestore, you need to add specialties to them.

#### Batch Update Script (Optional)

You can use the Firebase Admin SDK to batch update clinics:

```javascript
// Run this in Cloud Functions or Firebase Admin SDK
const admin = require('firebase-admin');
const db = admin.firestore();

async function addSpecialtiesToClinics() {
  const clinicsSnapshot = await db.collection('clinicDetails').get();
  
  const updates = [];
  
  clinicsSnapshot.forEach((doc) => {
    // Default specialties for general clinics
    const defaultSpecialties = [
      'General Dermatology',
      'Skin Infections',
      'Allergic Dermatitis',
      'Parasite Control'
    ];
    
    updates.push(
      doc.ref.update({
        specialties: defaultSpecialties
      })
    );
  });
  
  await Promise.all(updates);
  console.log(`Updated ${updates.length} clinics`);
}

addSpecialtiesToClinics();
```

### Step 4: Configure Specialization Levels

Clinics can have different levels of expertise:

#### General Practice
```javascript
specialties: [
  "General Dermatology",
  "Skin Infections",
  "Parasite Control"
]
```

#### Specialized Dermatology Clinic
```javascript
specialties: [
  "Flea Allergy Dermatitis",
  "Atopic Dermatitis",
  "Food Allergies",
  "Contact Dermatitis",
  "Hot Spots",
  "Pyoderma",
  "Yeast Infections",
  "Ringworm",
  "Mange",
  "Seborrhea",
  "Autoimmune Skin Disorders",
  "Advanced Dermatology",
  "Allergy Testing",
  "Immunotherapy"
]
```

#### Emergency Clinic
```javascript
specialties: [
  "Hot Spots",
  "Severe Infections",
  "Allergic Reactions",
  "Emergency Dermatology"
]
```

## How the Matching Works

### Matching Algorithm

The recommendation system uses a sophisticated scoring algorithm:

1. **Exact Match (100 points)**: Specialty name exactly matches disease name
2. **Contains Match (75 points)**: Specialty contains the full disease name
3. **Reverse Contains (70 points)**: Disease name contains the specialty
4. **All Words Match (50 points)**: All disease words appear in specialty
5. **Partial Match (25 points per word)**: Some disease words match

### Example Matching:

**Detected Disease**: "Flea Allergy Dermatitis"

| Clinic Specialty | Score | Match Type |
|-----------------|-------|------------|
| "Flea Allergy Dermatitis" | 100 | Exact Specialty Match |
| "Flea Allergy Treatment" | 75 | Primary Specialty |
| "Allergy Dermatitis" | 50 | Related Specialty |
| "Dermatology" | 25 | General Practice |

### Multiple Disease Matching

When multiple diseases are detected:
- Clinics treating multiple detected conditions get higher scores
- Scores are cumulative across diseases
- UI shows how many conditions the clinic treats

## User Experience

### In Assessment Results (Step 3)

After disease detection:
1. ✅ "Recommended Clinics" section appears
2. 📍 Shows top 3 specialized clinics
3. 🏷️ Displays match type badge (Exact, Primary, Related)
4. 👆 Tap to book appointment with pre-selected clinic

### In Disease Library

When viewing disease details:
1. 📚 User views disease information
2. 🏥 "Recommended Clinics" section shows relevant clinics
3. 📅 Tap "Book Appointment" to book with specialized clinic

## Testing the Feature

### Test Checklist

- [ ] Clinics have `specialties` array in Firestore
- [ ] Specialty names match disease names
- [ ] Assessment shows recommended clinics after detection
- [ ] Disease detail page shows recommended clinics
- [ ] Clinics are ranked by relevance
- [ ] Match type badges display correctly
- [ ] Tapping clinic navigates to booking with clinic preselected
- [ ] Works with single disease detection
- [ ] Works with multiple disease detection
- [ ] Handles cases with no matching clinics gracefully

### Test Scenarios

#### Scenario 1: Single Disease Detection
1. Complete pet assessment
2. AI detects "Flea Allergy Dermatitis"
3. Verify recommended clinics section appears
4. Verify clinics specializing in FAD are ranked first
5. Tap a clinic and verify booking page opens with clinic selected

#### Scenario 2: Multiple Diseases
1. Complete assessment with multiple detections
2. Verify clinics treating multiple conditions show "Treats X conditions"
3. Verify cumulative scoring ranks multi-specialty clinics higher

#### Scenario 3: Disease Library Flow
1. Navigate to Skin Disease Library
2. Select a disease (e.g., "Hot Spots")
3. View disease detail page
4. Verify recommended clinics section shows relevant clinics
5. Tap "Book Appointment" from clinic card

## Troubleshooting

### No Clinics Appearing

**Issue**: Recommended clinics section doesn't show

**Solutions**:
- ✅ Check that clinics have `specialties` field in Firestore
- ✅ Verify specialty names match disease names (case-insensitive)
- ✅ Check Firebase console logs for errors
- ✅ Ensure clinics have `status: 'approved'` and `isVisible: true`

### Wrong Clinics Recommended

**Issue**: Irrelevant clinics appearing

**Solutions**:
- ✅ Review and refine clinic `specialties` arrays
- ✅ Use more specific specialty names
- ✅ Remove generic terms if clinic is truly specialized

### Loading Takes Too Long

**Issue**: "Finding specialized clinics..." shows for too long

**Solutions**:
- ✅ Add indexes in Firestore for `status` and `isVisible` fields
- ✅ Consider caching clinic data
- ✅ Limit the number of clinics queried

## Future Enhancements

### Planned Features

1. **Distance-Based Ranking**: Factor in clinic proximity to user
2. **Rating Integration**: Include clinic ratings in recommendations
3. **Availability Check**: Only show clinics with available appointments
4. **Price Range Filter**: Allow users to filter by estimated cost
5. **Insurance Network**: Highlight in-network clinics
6. **Veterinary Expertise**: Show veterinarian credentials
7. **Patient Reviews**: Display reviews from similar cases

### Admin Dashboard Integration

Future updates will include:
- Admin panel to manage clinic specialties
- Bulk specialty assignment tool
- Specialty verification workflow
- Analytics on recommendation performance

## Data Schema

### ClinicDetails Document

```typescript
{
  id: string,
  clinicId: string,
  clinicName: string,
  address: string,
  phone: string,
  email: string,
  description: string,
  
  // Specialties array - REQUIRED for recommendations
  specialties: string[],
  
  // Other fields
  operatingHours: string,
  services: ClinicService[],
  certifications: ClinicCertification[],
  licenses: ClinicLicense[],
  isVerified: boolean,
  isActive: boolean,
  createdAt: Date,
  updatedAt: Date
}
```

## Support

For questions or issues:
- 📧 Check Firebase console logs
- 🐛 Review error messages in Flutter debug console
- 📝 Verify Firestore data structure matches schema
- 💬 Consult development team

---

**Setup Date**: October 30, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for Production (after manual setup)
