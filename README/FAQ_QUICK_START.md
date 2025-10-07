# Quick Start Guide - Dynamic FAQ Management

## 🚀 Quick Setup

### Step 1: Seed Sample Data

You can seed sample FAQs with one click using the provided IDs:

**Super Admin ID**: `cQ12UuqtoGWX8vyCGupADdzdfEn1`  
**Clinic ID**: `0FdZe3yuFFR4ZtA6K1mFczfx4zv2`

### Option A: Use the UI Button (Easiest)

1. **Log in as Super Admin** with ID `cQ12UuqtoGWX8vyCGupADdzdfEn1`
2. **Navigate** to Support Center
3. **Click** on "FAQ Management" tab
4. **Click** "Seed Sample FAQs" button
5. ✅ Super Admin FAQs will be created

6. **Log out** and **log in as Clinic Admin** with ID `0FdZe3yuFFR4ZtA6K1mFczfx4zv2`
7. **Navigate** to Support Center
8. **Click** on "FAQ Management" tab
9. **Click** "Seed Sample FAQs" button
10. ✅ Clinic FAQs will be created

### Option B: Use Code (For Testing)

Add this temporary code anywhere in your app (e.g., in a test button):

```dart
import 'package:pawsense/core/utils/faq_seeder.dart';

// Seed both types of FAQs
await FAQSeeder.seedAllFAQs(
  superAdminId: 'cQ12UuqtoGWX8vyCGupADdzdfEn1',
  clinicId: '0FdZe3yuFFR4ZtA6K1mFczfx4zv2',
  clinicAdminId: '0FdZe3yuFFR4ZtA6K1mFczfx4zv2',
);
```

### Option C: Use Flutter DevTools Console

1. **Open** your app in debug mode
2. **Open** Flutter DevTools
3. **Go to** Console tab
4. **Paste** and run:

```dart
import 'package:pawsense/core/utils/faq_seeder.dart';

FAQSeeder.seedAllFAQs(
  superAdminId: 'cQ12UuqtoGWX8vyCGupADdzdfEn1',
  clinicId: '0FdZe3yuFFR4ZtA6K1mFczfx4zv2',
  clinicAdminId: '0FdZe3yuFFR4ZtA6K1mFczfx4zv2',
).then((_) => print('Done!'));
```

## ✅ What Gets Created

### Super Admin FAQs (5 items)
Created by: `cQ12UuqtoGWX8vyCGupADdzdfEn1`

1. **How do I use the AI disease detection feature?** (Technology)
   - Detailed explanation of AI features
   
2. **How do I create an account?** (Account)
   - Sign up process explanation
   
3. **Is my data secure?** (General)
   - Security and privacy information
   
4. **How accurate is the AI diagnosis?** (Technology)
   - AI accuracy details and limitations
   
5. **Can I use PawSense for multiple pets?** (General)
   - Multi-pet account capabilities

### Clinic FAQs (5 items)
Created by: `0FdZe3yuFFR4ZtA6K1mFczfx4zv2`  
Associated with: Clinic `0FdZe3yuFFR4ZtA6K1mFczfx4zv2`

1. **How do I schedule an appointment at your clinic?** (Appointments)
   - Booking process
   
2. **What should I do if my pet has an emergency?** (Emergency Care)
   - Emergency contact information
   
3. **What payment methods do you accept?** (Billing)
   - Payment options
   
4. **What vaccinations does my pet need?** (Preventive Care)
   - Vaccination schedule
   
5. **What services does your clinic offer?** (Services)
   - Service list

## 🔍 Verify It Works

### Check Super Admin FAQs

1. **Log in** as super admin (`cQ12UuqtoGWX8vyCGupADdzdfEn1`)
2. **Navigate** to Support Center → FAQ Management
3. **You should see**: "General App FAQs" header
4. **You should see**: 5 FAQs about general app features

### Check Clinic FAQs

1. **Log in** as clinic admin (`0FdZe3yuFFR4ZtA6K1mFczfx4zv2`)
2. **Navigate** to Support Center → FAQ Management
3. **You should see**: "Clinic FAQs" header
4. **You should see**: 5 FAQs about clinic-specific information

### Check Firestore

1. **Go to** Firebase Console
2. **Navigate** to Firestore Database
3. **Open** `faqs` collection
4. **You should see**: 10 total documents
   - 5 with `isSuperAdminFAQ: true`
   - 5 with `clinicId: 0FdZe3yuFFR4ZtA6K1mFczfx4zv2`

## 🧪 Test CRUD Operations

### Test Create

1. Click "Add FAQ" button
2. Fill in:
   - Category: Select from dropdown
   - Question: "Test question for FAQ?"
   - Answer: "This is a test answer with more than 20 characters to pass validation."
3. Click "Create FAQ"
4. ✅ Should see success message
5. ✅ FAQ should appear in list

### Test Edit

1. Expand an existing FAQ
2. Click "Edit" button
3. Modify the question or answer
4. Click "Update FAQ"
5. ✅ Should see success message
6. ✅ Changes should be visible

### Test Delete

1. Expand an FAQ
2. Click "Delete" button
3. Confirm deletion
4. ✅ FAQ should be removed from list
5. ✅ Should see success message

### Test Role Separation

1. **As super admin**: Try to access clinic FAQs
   - ✅ Should only see "General App FAQs"
   - ✅ Cannot see clinic FAQs

2. **As clinic admin**: Try to access super admin FAQs
   - ✅ Should only see "Clinic FAQs"
   - ✅ Cannot see super admin FAQs

## 🔒 Security Verification

### Test Permissions

1. **Super admin** tries to:
   - ✅ Create super admin FAQ (should work)
   - ❌ Create clinic FAQ (should fail)
   - ✅ Edit own super admin FAQ (should work)
   - ❌ Edit clinic FAQ (should fail)

2. **Clinic admin** tries to:
   - ✅ Create clinic FAQ (should work)
   - ❌ Create super admin FAQ (should fail)
   - ✅ Edit own clinic FAQ (should work)
   - ❌ Edit other clinic's FAQ (should fail)

## 📊 Expected Firestore Structure

```
faqs/
├── {auto-id-1}/
│   ├── id: "auto-id-1"
│   ├── question: "How do I use the AI disease detection feature?"
│   ├── answer: "To use the AI disease detection..."
│   ├── category: "Technology"
│   ├── views: 0
│   ├── helpfulVotes: 0
│   ├── clinicId: null
│   ├── isSuperAdminFAQ: true
│   ├── createdAt: "2025-01-07T..."
│   ├── createdBy: "cQ12UuqtoGWX8vyCGupADdzdfEn1"
│   └── isPublished: true
│
├── {auto-id-2}/
│   ├── id: "auto-id-2"
│   ├── question: "How do I schedule an appointment..."
│   ├── answer: "Scheduling an appointment is easy..."
│   ├── category: "Appointments"
│   ├── views: 0
│   ├── helpfulVotes: 0
│   ├── clinicId: "0FdZe3yuFFR4ZtA6K1mFczfx4zv2"
│   ├── isSuperAdminFAQ: false
│   ├── createdAt: "2025-01-07T..."
│   ├── createdBy: "0FdZe3yuFFR4ZtA6K1mFczfx4zv2"
│   └── isPublished: true
│
└── ... (8 more documents)
```

## 🛠️ Troubleshooting

### Issue: "Seed Sample FAQs" button not working

**Solution**:
```dart
// Check console for errors
// Verify user is authenticated
final user = await AuthGuard.getCurrentUser();
print('User: ${user?.uid}, Role: ${user?.role}');
```

### Issue: FAQs not appearing after seeding

**Solution**:
1. Pull down to refresh the list
2. Check Firestore Console for data
3. Verify `isPublished` is true
4. Check browser console for errors

### Issue: Permission denied

**Solution**:
1. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
2. Verify user role in Firestore
3. Check authentication token

### Issue: Indexes not created

**Solution**:
1. Open browser console
2. Look for Firestore index creation links
3. Click links to auto-create indexes
4. Wait 1-2 minutes for indexes to build

## 🎯 Success Checklist

- [ ] Seeded super admin FAQs
- [ ] Seeded clinic FAQs
- [ ] Super admin sees 5 general app FAQs
- [ ] Clinic admin sees 5 clinic FAQs
- [ ] Can create new FAQ
- [ ] Can edit existing FAQ
- [ ] Can delete FAQ
- [ ] Role separation works
- [ ] Firestore has 10 documents
- [ ] Firestore rules deployed
- [ ] Firestore indexes created
- [ ] No console errors

## 🎉 You're Ready!

Once all items in the checklist are complete, your dynamic FAQ management system is fully operational!

### Next Steps:
1. Remove the "Seed Sample FAQs" button before production
2. Create your own FAQs through the admin interface
3. Monitor FAQ views and helpful votes
4. Update FAQs based on user feedback

---

**Your IDs for Reference:**
- Super Admin: `cQ12UuqtoGWX8vyCGupADdzdfEn1`
- Clinic: `0FdZe3yuFFR4ZtA6K1mFczfx4zv2`

Happy FAQ managing! 🚀
