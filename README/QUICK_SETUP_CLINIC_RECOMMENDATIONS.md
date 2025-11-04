# 🚀 QUICK SETUP CARD - Clinic Recommendations

## 1️⃣ Open Firebase Console
```
https://console.firebase.google.com
→ Select PawSense Project
→ Firestore Database
```

## 2️⃣ Navigate to Clinic
```
Collections → clinicDetails → [Pick any clinic]
```

## 3️⃣ Add Specialties Field
```
Click: "+ Add field"

Field name: specialties
Type:       array

Add these items:
[0] Flea Allergy Dermatitis
[1] Hot Spots
[2] Ringworm
[3] Mange
[4] General Dermatology

Click: "Update"
```

## 4️⃣ Check Clinic is Visible
```
Collections → clinics → [Same clinic by userId]

Verify:
✓ status: "approved"
✓ isVisible: true
```

## 5️⃣ Test in App

### Test Method A: Assessment
```
1. Start Pet Assessment
2. Complete steps 1-2 (upload photo)
3. In Step 3 results → Look for "Recommended Clinics"
```

### Test Method B: Disease Library
```
1. Open Skin Disease Library
2. Tap "Flea Allergy Dermatitis" or "Hot Spots"
3. Scroll down → See "Recommended Clinics"
```

---

## 📋 Copy-Paste Template

Use this for quick testing:

### For General Clinics:
```
Flea Allergy Dermatitis
Hot Spots
Ringworm
Mange
General Dermatology
```

### For Specialized Clinics:
```
Flea Allergy Dermatitis
Atopic Dermatitis
Contact Dermatitis
Hot Spots
Pyoderma
Ringworm
Mange
Yeast Infections
Food Allergies
Seborrhea
```

---

## ✅ Success Checklist

- [ ] Added `specialties` array to clinic document
- [ ] Added at least 3 disease names
- [ ] Verified clinic status is "approved"
- [ ] Verified clinic isVisible is true
- [ ] Tested in app assessment flow
- [ ] Saw "Recommended Clinics" section appear

---

## 🐛 Troubleshooting

**Not showing?**
1. Check Flutter console for errors
2. Verify exact disease name spelling
3. Ensure clinic has `status: 'approved'`
4. Ensure clinic has `isVisible: true`

**Wrong clinic showing?**
- Disease names must match exactly
- Check capitaliza tion (system is case-insensitive but exact match scores higher)

---

## 📸 Visual Guide

### Firebase Console Steps:

```
Step 1: Find clinic document
┌─────────────────────────────────────┐
│ clinicDetails                       │
│ └─ clinic_details_ABC123            │
│    ├─ clinicName: "Happy Paws"      │
│    ├─ address: "123 Main St"        │
│    └─ [+ Add field] ← CLICK HERE    │
└─────────────────────────────────────┘

Step 2: Add field dialog
┌─────────────────────────────────────┐
│ Field name: specialties             │
│ Field type: array          [v]      │
│                                     │
│ [Add array item]                    │
└─────────────────────────────────────┘

Step 3: Add disease names
┌─────────────────────────────────────┐
│ specialties (array)                 │
│ [0]: Flea Allergy Dermatitis        │
│ [1]: Hot Spots                      │
│ [2]: Ringworm                       │
│ [+ Add array item]                  │
│                                     │
│ [Cancel]  [Update]                  │
└─────────────────────────────────────┘
```

---

## 🎯 Expected Result in App

### In Assessment Step 3:
```
┌────────────────────────────────────┐
│ 📊 Differential Analysis Results   │
│ • Flea Allergy Dermatitis: 85%    │
│                                    │
│ 🏥 RECOMMENDED CLINICS             │
│ ┌──────────────────────────────┐  │
│ │ 🏥 Happy Paws Clinic        │  │
│ │ ✓ Exact Specialty Match     │  │
│ │ 📍 123 Main St, Manila      │  │
│ └──────────────────────────────┘  │
└────────────────────────────────────┘
```

### In Disease Library:
```
┌────────────────────────────────────┐
│ Flea Allergy Dermatitis            │
│                                    │
│ [Disease Info...]                  │
│                                    │
│ 🏥 RECOMMENDED CLINICS             │
│ ┌──────────────────────────────┐  │
│ │ 🏥 Happy Paws Clinic        │  │
│ │ ✓ Exact Specialty Match     │  │
│ └──────────────────────────────┘  │
│                                    │
│ [Book Appointment]                 │
└────────────────────────────────────┘
```

---

**Time Estimate:** 5-10 minutes for first clinic  
**Need Help?** Check main setup guide: CLINIC_RECOMMENDATION_SYSTEM_SETUP.md
