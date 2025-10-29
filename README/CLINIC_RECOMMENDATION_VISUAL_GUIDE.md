# Quick Visual Guide: Clinic Recommendations

## 🎯 What This Feature Does

Automatically suggests veterinary clinics that specialize in treating detected skin diseases.

---

## 📱 User Flows

### Flow 1: From Assessment

```
┌─────────────────────────────────────┐
│  STEP 1: Pet Assessment             │
│  User completes 3-step assessment   │
└───────────────┬─────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  STEP 2: AI Detection               │
│  System detects "Flea Allergy       │
│  Dermatitis" with 85% confidence    │
└───────────────┬─────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  STEP 3: Results + Recommendations  │
│                                     │
│  📊 Differential Analysis Results   │
│  • Flea Allergy Dermatitis: 85%    │
│                                     │
│  ⚠️ Severity: MODERATE              │
│  When to Seek Help: [details]      │
│                                     │
│  🏥 RECOMMENDED CLINICS ✨          │
│  ┌─────────────────────────────┐   │
│  │ 🏥 PetCare Plus Clinic      │   │
│  │ ✓ Exact Specialty Match     │   │
│  │ 📍 123 Main St, Manila      │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🏥 Vet Dermatology Center   │   │
│  │ ✓ Primary Specialty          │   │
│  │ 📍 456 Ave, Quezon City     │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Download PDF] [Book] [Complete]   │
└───────────────┬─────────────────────┘
                ↓
        [Tap Clinic Card]
                ↓
┌─────────────────────────────────────┐
│  Book Appointment Page              │
│  ✓ Clinic Pre-Selected             │
│  ✓ Assessment Data Linked           │
└─────────────────────────────────────┘
```

### Flow 2: From Disease Library

```
┌─────────────────────────────────────┐
│  Skin Disease Library               │
│  User browses diseases              │
└───────────────┬─────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  Select "Hot Spots"                 │
└───────────────┬─────────────────────┘
                ↓
┌─────────────────────────────────────┐
│  Disease Detail Page                │
│                                     │
│  🖼️ [Disease Image]                │
│                                     │
│  ℹ️ What is this condition?        │
│  Hot spots (acute moist dermatitis) │
│  are inflamed, infected areas...    │
│                                     │
│  ⚠️ Key Symptoms:                  │
│  • Red, inflamed patches            │
│  • Excessive licking                │
│                                     │
│  🏥 RECOMMENDED CLINICS ✨          │
│  ┌─────────────────────────────┐   │
│  │ 🏥 Emergency Vet Clinic     │   │
│  │ ✓ Exact Specialty Match     │   │
│  │ 📍 789 Road, Manila         │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🏥 Skin Care Vet Hospital   │   │
│  │ ✓ Primary Specialty          │   │
│  │ 📍 101 Street, Makati       │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Book Appointment] [Track Condition]│
└───────────────┬─────────────────────┘
                ↓
        [Tap Clinic or Book]
                ↓
┌─────────────────────────────────────┐
│  Book Appointment Page              │
│  ✓ Clinic Pre-Selected             │
└─────────────────────────────────────┘
```

---

## 🎨 UI Components

### Recommended Clinics Widget

```
┌────────────────────────────────────────────┐
│ 🎯 Recommended Clinics                     │
│    Specializing in Flea Allergy Dermatitis│
├────────────────────────────────────────────┤
│                                            │
│ ┌──────────────────────────────────────┐  │
│ │  🏥   Happy Paws Clinic             →│  │
│ │       ✓ Exact Specialty Match        │  │
│ │       📍 123 Main St, Manila         │  │
│ │       📞 +63 912 345 6789            │  │
│ └──────────────────────────────────────┘  │
│                                            │
│ ┌──────────────────────────────────────┐  │
│ │  🏥   Pet Dermatology Center        →│  │
│ │       ✓ Primary Specialty            │  │
│ │       📍 456 Avenue, Quezon City     │  │
│ │       📞 +63 917 888 7777            │  │
│ └──────────────────────────────────────┘  │
│                                            │
│ ┌──────────────────────────────────────┐  │
│ │  🏥   General Vet Clinic            →│  │
│ │       ✓ Related Specialty            │  │
│ │       📍 789 Road, Pasig             │  │
│ │       📞 +63 915 222 3333            │  │
│ └──────────────────────────────────────┘  │
│                                            │
│        → View 5 more clinics               │
└────────────────────────────────────────────┘
```

### Match Type Badges

```
┌─────────────────────────────┐
│ ✓ Exact Specialty Match     │  🟢 Green
└─────────────────────────────┘

┌─────────────────────────────┐
│ ✓ Primary Specialty          │  🔵 Blue
└─────────────────────────────┘

┌─────────────────────────────┐
│ ✓ Related Specialty          │  🟡 Yellow
└─────────────────────────────┘

┌─────────────────────────────┐
│ ✓ General Practice           │  ⚪ Gray
└─────────────────────────────┘
```

### Multiple Disease Match

```
┌──────────────────────────────────────┐
│  🏥   Multi-Specialty Vet Center   →│
│       ✓ Primary Specialty            │
│       ✅ Treats 3 detected conditions│
│       📍 999 Boulevard, Manila       │
│       📞 +63 919 111 2222            │
└──────────────────────────────────────┘
```

---

## 🔧 Backend Data Structure

### Firestore: clinicDetails Collection

```javascript
{
  id: "clinic_details_ABC123",
  clinicId: "ABC123",
  clinicName: "Happy Paws Veterinary Clinic",
  address: "123 Main Street, Manila",
  phone: "+63 912 345 6789",
  email: "contact@happypaws.com",
  
  // ✨ KEY FIELD FOR RECOMMENDATIONS
  specialties: [
    "Flea Allergy Dermatitis",
    "Hot Spots",
    "Ringworm",
    "Mange",
    "Skin Infections",
    "Allergic Dermatitis"
  ],
  
  // Other fields...
  services: [...],
  certifications: [...],
  isVerified: true,
  isActive: true
}
```

---

## 📊 Matching Algorithm

### Score Calculation

```
Disease: "Flea Allergy Dermatitis"

CLINIC A
Specialty: "Flea Allergy Dermatitis"
Match: EXACT → Score: 100
Badge: "Exact Specialty Match" 🟢

CLINIC B
Specialty: "Flea Allergy Treatment"
Match: CONTAINS → Score: 75
Badge: "Primary Specialty" 🔵

CLINIC C
Specialty: "Allergy Dermatitis"
Match: ALL WORDS → Score: 50
Badge: "Related Specialty" 🟡

CLINIC D
Specialty: "Dermatology Services"
Match: PARTIAL → Score: 25
Badge: "General Practice" ⚪
```

### Ranking

```
Results sorted by score (descending):
1. Clinic A (100) - Exact Match
2. Clinic B (75)  - Primary
3. Clinic C (50)  - Related
4. Clinic D (25)  - General
```

---

## ✅ Manual Setup Steps

### Step 1: Open Firebase Console
```
https://console.firebase.google.com
→ Select Project: PawSense
→ Firestore Database
```

### Step 2: Navigate to clinicDetails
```
Collections → clinicDetails
```

### Step 3: Add Specialties to Each Clinic
```
For EACH clinic document:
1. Click document
2. Add field
3. Field name: "specialties"
4. Type: array
5. Click "Add array item"
6. Add disease names (one per item)
7. Save
```

### Example Input:
```
Field: specialties
Type: array
Items:
  [0]: "Flea Allergy Dermatitis"
  [1]: "Hot Spots"
  [2]: "Ringworm"
  [3]: "Mange"
  [4]: "Skin Infections"
```

---

## 🧪 Testing Guide

### Test 1: Single Disease
```
1. Go to Assessment
2. Select pet → Add symptoms → Upload photos
3. Wait for AI detection
4. ✓ Verify "Recommended Clinics" appears
5. ✓ Check clinics are relevant
6. ✓ Tap clinic → Verify booking opens
7. ✓ Check clinic is preselected
```

### Test 2: Multiple Diseases
```
1. Upload multiple affected areas
2. AI detects 2-3 diseases
3. ✓ Verify clinics treating multiple conditions
4. ✓ Check "Treats X conditions" label
5. ✓ Verify scoring favors multi-specialty
```

### Test 3: Disease Library
```
1. Open Skin Disease Library
2. Select any disease
3. View detail page
4. ✓ Verify "Recommended Clinics" shows
5. ✓ Tap clinic card
6. ✓ Verify navigation to booking
```

---

## 🎯 Success Metrics

After setup, you should see:

✅ Recommended clinics appear in assessment results  
✅ Recommended clinics appear in disease detail pages  
✅ Match type badges display correctly  
✅ Clinics ranked by relevance (best matches first)  
✅ Tapping clinic navigates to booking with preselection  
✅ Loading states show while fetching  
✅ Graceful handling when no matches found  

---

## 📞 Need Help?

If recommendations don't show:
1. Check Firestore for `specialties` field
2. Verify specialty names match disease names
3. Check Firebase console logs for errors
4. Ensure clinics have `status: 'approved'`
5. Ensure clinics have `isVisible: true`

---

**Quick Reference**: See `CLINIC_RECOMMENDATION_SYSTEM_SETUP.md` for detailed documentation.
