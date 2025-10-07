# FAQ Seeder Usage Guide

## Overview

The FAQ Seeder is a utility to quickly populate your database with sample FAQ data for testing the dynamic FAQ management system.

## How to Use

### Method 1: Using Flutter DevTools Console

1. **Add the seeder import** to your main.dart or any test file:
   ```dart
   import 'package:pawsense/core/utils/faq_seeder.dart';
   ```

2. **Call the seeder** after authentication:
   ```dart
   // Example in a button press or initialization
   await FAQSeeder.seedAllFAQs(
     superAdminId: 'YOUR_SUPER_ADMIN_USER_ID',
     clinicId: 'YOUR_CLINIC_ID',
     clinicAdminId: 'YOUR_CLINIC_ADMIN_USER_ID',
   );
   ```

### Method 2: Create a Temporary Seed Button (Recommended for Testing)

Add this to your Support Screen or any admin screen:

```dart
// In your StatefulWidget
ElevatedButton(
  onPressed: () async {
    final user = await AuthGuard.getCurrentUser();
    if (user != null) {
      if (user.role == 'super_admin') {
        // Seed super admin FAQs
        await FAQSeeder.seedSuperAdminFAQs(user.uid);
      } else if (user.role == 'admin') {
        // Seed clinic FAQs
        await FAQSeeder.seedClinicFAQs(user.uid, user.uid);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample FAQs created!')),
      );
      
      // Refresh the FAQ list
      setState(() {});
    }
  },
  child: Text('Seed Sample FAQs'),
)
```

### Method 3: Firebase Functions (Production)

For production environments, you can create a Firebase Function:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.seedFAQs = functions.https.onCall(async (data, context) => {
  // Verify the caller is a super admin
  if (!context.auth || context.auth.token.role !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only super admins can seed FAQs'
    );
  }

  // Seed logic here
  const { superAdminId, clinicId, clinicAdminId } = data;
  
  // ... seeding logic
  
  return { success: true, message: 'FAQs seeded successfully' };
});
```

## What Gets Created

### Super Admin FAQs (5 items)
1. **How do I use the AI disease detection feature?** (Technology)
2. **How do I create an account?** (Account)
3. **Is my data secure?** (General)
4. **How accurate is the AI diagnosis?** (Technology)
5. **Can I use PawSense for multiple pets?** (General)

### Clinic FAQs (5 items)
1. **How do I schedule an appointment at your clinic?** (Appointments)
2. **What should I do if my pet has an emergency?** (Emergency Care)
3. **What payment methods do you accept?** (Billing)
4. **What vaccinations does my pet need?** (Preventive Care)
5. **What services does your clinic offer?** (Services)

## Clear All FAQs

⚠️ **WARNING**: This will delete ALL FAQs from your database. Use only for testing!

```dart
await FAQSeeder.clearAllFAQs();
```

## Example: Complete Test Flow

```dart
// 1. Clear existing FAQs (optional)
await FAQSeeder.clearAllFAQs();

// 2. Seed new FAQs
await FAQSeeder.seedAllFAQs(
  superAdminId: 'user_12345',
  clinicId: 'clinic_67890',
  clinicAdminId: 'user_67890',
);

// 3. Refresh your UI
setState(() {});
```

## Tips

1. **Get User IDs**: You can get user IDs from Firebase Console > Authentication
2. **Get Clinic IDs**: Clinic IDs are the same as the admin user IDs
3. **Test Different Roles**: Seed FAQs with different user IDs to test role-based access
4. **Custom Data**: Modify the `FAQSeeder` class to add your own sample FAQs

## Troubleshooting

### "Permission Denied" Error
- Make sure your Firestore rules are deployed
- Verify the user has the correct role (super_admin or admin)
- Check that you're authenticated

### FAQs Not Showing
- Refresh the page
- Check that `isPublished` is true
- Verify the Firestore indexes are created
- Look for errors in browser console

### Duplicate FAQs
- Each FAQ gets a unique auto-generated ID
- Run `clearAllFAQs()` first if you want to start fresh

## Production Considerations

1. **Remove Seeder Code**: Don't include seeder code in production builds
2. **Use Proper Migration**: For production, create FAQs through the admin interface
3. **Backup Data**: Always backup before running clearAllFAQs()
4. **Rate Limiting**: Be mindful of Firestore write limits

---

**Note**: This seeder is for development and testing only. In production, clinics should create their own FAQs through the admin interface.
