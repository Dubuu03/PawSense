# Firestore Indexes Setup Guide

## 🔥 Required Firestore Indexes for FAQ System

Your FAQ system requires composite indexes in Firestore for efficient querying. Here are all the indexes you need to create:

---

## 📋 Index 1: Clinic FAQs Index

**Collection**: `faqs`  
**Fields to Index**:
1. `clinicId` (Ascending)
2. `isPublished` (Ascending)
3. `createdAt` (Descending)

### Quick Create Link:
Click this link to automatically create the index:

**[Create Clinic FAQs Index](https://console.firebase.google.com/v1/r/project/pawsense-134fc/firestore/indexes?create_composite=Cktwcm9qZWN0cy9wYXdzZW5zZS0xMzRmYy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZmFxcy9pbmRleGVzL18QARoMCghjbGluaWNJZBABGg8KC2lzUHVibGlzaGVkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg)**

Or manually create in Firebase Console:
```
Collection ID: faqs
Fields indexed:
  - clinicId: Ascending
  - isPublished: Ascending  
  - createdAt: Descending
Query scope: Collection
```

---

## 📋 Index 2: Super Admin FAQs Index

**Collection**: `faqs`  
**Fields to Index**:
1. `isSuperAdminFAQ` (Ascending)
2. `isPublished` (Ascending)
3. `createdAt` (Descending)

### Manual Creation Steps:
1. Go to [Firebase Console - Firestore Indexes](https://console.firebase.google.com/project/pawsense-134fc/firestore/indexes)
2. Click "Create Index"
3. Select collection: `faqs`
4. Add fields:
   - Field: `isSuperAdminFAQ`, Order: `Ascending`
   - Field: `isPublished`, Order: `Ascending`
   - Field: `createdAt`, Order: `Descending`
5. Query scope: `Collection`
6. Click "Create"

---

## 📋 Index 3: All Published FAQs Index (Optional but Recommended)

**Collection**: `faqs`  
**Fields to Index**:
1. `isPublished` (Ascending)
2. `createdAt` (Descending)

### Manual Creation Steps:
1. Go to [Firebase Console - Firestore Indexes](https://console.firebase.google.com/project/pawsense-134fc/firestore/indexes)
2. Click "Create Index"
3. Select collection: `faqs`
4. Add fields:
   - Field: `isPublished`, Order: `Ascending`
   - Field: `createdAt`, Order: `Descending`
5. Query scope: `Collection`
6. Click "Create"

---

## 🚀 Quick Setup - All at Once

### Step 1: Create Clinic FAQs Index (REQUIRED)
**This is the one causing your current error!**

👉 **[CLICK HERE TO CREATE](https://console.firebase.google.com/v1/r/project/pawsense-134fc/firestore/indexes?create_composite=Cktwcm9qZWN0cy9wYXdzZW5zZS0xMzRmYy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZmFxcy9pbmRleGVzL18QARoMCghjbGluaWNJZBABGg8KC2lzUHVibGlzaGVkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg)**

### Step 2: Create Super Admin FAQs Index
After the first index is built, create this one manually in Firebase Console.

### Step 3: Wait for Index Building
- Indexes typically take 1-5 minutes to build
- You'll see "Building" status in Firebase Console
- Once status shows "Enabled", you're good to go!

---

## 🎯 Alternative: Use Firebase CLI

If you prefer using the command line:

1. **Install Firebase CLI** (if not already installed):
```bash
npm install -g firebase-tools
```

2. **Login to Firebase**:
```bash
firebase login
```

3. **Create `firestore.indexes.json`** in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "faqs",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "clinicId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isPublished",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "faqs",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isSuperAdminFAQ",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isPublished",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "faqs",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isPublished",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

4. **Deploy the indexes**:
```bash
firebase deploy --only firestore:indexes
```

---

## ⚡ Quick Fix - Single Command

Copy and paste this into your terminal (requires Firebase CLI):

```bash
# Navigate to your project directory
cd /Users/drixnarciso/Documents/Thesis/PawSense

# Deploy indexes
firebase deploy --only firestore:indexes
```

---

## 🔍 Check Index Status

### In Firebase Console:
1. Go to [Firestore Indexes](https://console.firebase.google.com/project/pawsense-134fc/firestore/indexes)
2. Look for your indexes in the list
3. Status should show:
   - 🟡 **Building** - Wait a few minutes
   - 🟢 **Enabled** - Ready to use!
   - 🔴 **Error** - Check configuration

### Using Firebase CLI:
```bash
firebase firestore:indexes
```

---

## 🎬 What to Do Right Now

### Immediate Action (Fix Current Error):
1. **Click this link**: [Create Clinic FAQs Index](https://console.firebase.google.com/v1/r/project/pawsense-134fc/firestore/indexes?create_composite=Cktwcm9qZWN0cy9wYXdzZW5zZS0xMzRmYy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZmFxcy9pbmRleGVzL18QARoMCghjbGluaWNJZBABGg8KC2lzUHVibGlzaGVkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg)
2. Click "Create Index" button
3. Wait 1-5 minutes for index to build
4. Try seeding FAQs again

### After First Index is Created:
1. Manually create the Super Admin FAQs index
2. Optionally create the Published FAQs index
3. Test your FAQ system

---

## 📝 Troubleshooting

### Error: "The query requires an index"
**Solution**: Click the link in the error message or use the link above to create the index.

### Index Taking Too Long
**Typical Build Times**:
- Small dataset (< 100 docs): 1-2 minutes
- Medium dataset (100-1000 docs): 2-5 minutes
- Large dataset (> 1000 docs): 5-15 minutes

If it takes longer than 15 minutes, check Firebase status or contact support.

### Index Shows "Error" Status
**Common Causes**:
1. Field types don't match (e.g., expecting string but got number)
2. Field doesn't exist in all documents
3. Conflicting index definitions

**Solution**: Delete the index and recreate it, ensuring field types are correct.

---

## ✅ Success Indicators

You'll know indexes are working when:
- ✅ No "requires an index" errors in console
- ✅ FAQ queries load without errors
- ✅ Both super admin and clinic FAQs display correctly
- ✅ Seeding completes successfully

---

## 🎉 Summary

**Main Index URL** (click this now):
https://console.firebase.google.com/v1/r/project/pawsense-134fc/firestore/indexes?create_composite=Cktwcm9qZWN0cy9wYXdzZW5zZS0xMzRmYy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZmFxcy9pbmRleGVzL18QARoMCghjbGluaWNJZBABGg8KC2lzUHVibGlzaGVkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg

**Total Indexes Needed**: 2-3
- 1 for clinic FAQs (REQUIRED - causing your error)
- 1 for super admin FAQs (REQUIRED)
- 1 for all published FAQs (OPTIONAL)

**Time to Complete**: 5-10 minutes total

---

**Created**: January 7, 2025  
**Project**: PawSense  
**Firebase Project**: pawsense-134fc
