# Debug Sign-In Issues Guide

## Current Error Analysis

### Error Message:
```
E/RecaptchaCallWrapper: The supplied auth credential is incorrect, malformed or has expired.
```

### This Error Means:
1. **Wrong email or password** being entered
2. **Email doesn't exist** in Firebase Authentication
3. **Password has been changed** and old password is being used
4. **Account has been deleted** from Firebase Auth

---

## Debugging Steps

### Step 1: Check if Account Exists in Firebase

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project (PawSense)
3. Navigate to **Authentication** → **Users**
4. Search for the email: `narcisodrix@gmail.com`
5. Check:
   - ✅ Does the user exist?
   - ✅ What sign-in provider? (Email/Password or Google)
   - ✅ Is the email verified in Firebase Auth?

### Step 2: Check Firestore User Data

1. In Firebase Console, go to **Firestore Database**
2. Navigate to `users` collection
3. Find the document with email `narcisodrix@gmail.com`
4. Check the following fields:
   ```javascript
   {
     "uid": "...",
     "email": "narcisodrix@gmail.com",
     "emailVerified": true/false/null,  // Check this!
     "emailVerifiedAt": timestamp,
     "isActive": true,
     "role": "user"
   }
   ```

### Step 3: Test Different Scenarios

#### Scenario A: Account Signed Up with Email/Password
```dart
// The account MUST have gone through OTP verification
// Check: userData.emailVerified should be true
```

**How to fix if emailVerified is missing:**
```javascript
// In Firestore, manually update the user document:
{
  "emailVerified": true,
  "emailVerifiedAt": new Date()
}
```

#### Scenario B: Account Signed Up with Google
```dart
// Google accounts are auto-verified
// Check: Firebase Auth emailVerified should be true
```

**The system will auto-migrate Google users on first sign-in**

#### Scenario C: Legacy Account (Before Fix)
```dart
// Account created before emailVerified field was added
// System will check Firebase Auth emailVerified
// If true, will auto-migrate to Firestore
```

---

## Common Issues & Solutions

### Issue 1: "The supplied auth credential is incorrect"

**Cause**: Wrong password or email doesn't exist

**Solutions**:
1. ✅ **Reset password** using "Forgot Password" flow
2. ✅ **Try Google Sign-In** if account was created with Google
3. ✅ **Check email spelling** (narcisodrix@gmail.com vs narciso.drix@gmail.com)
4. ✅ **Verify account exists** in Firebase Console

### Issue 2: "No AppCheckProvider installed"

**Cause**: Warning (not blocking) - App Check not configured

**Solution** (Optional - not required for sign-in to work):
```dart
// In main.dart, add:
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug, // Use .playIntegrity for production
);
```

### Issue 3: "Email not verified" error

**Cause**: User didn't complete OTP verification or emailVerified field is false

**Solutions**:
1. ✅ **Complete OTP verification** during sign-up
2. ✅ **Manually set emailVerified to true** in Firestore (for existing users)
3. ✅ **Use verify email flow** in app

### Issue 4: Legacy users can't sign in

**Cause**: emailVerified field doesn't exist in Firestore

**Solution**: System auto-handles this!
- If Firebase Auth emailVerified = true → auto-migrates
- If Firebase Auth emailVerified = false → shows "verify email" error

---

## Testing Your Specific Account (narcisodrix@gmail.com)

### Step-by-Step Test:

1. **Check Firebase Console**:
   ```
   Firebase Auth → Users → Search: narcisodrix@gmail.com
   - Provider: Email/Password or Google.com?
   - Email verified: ✓ or ✗?
   ```

2. **Check Firestore**:
   ```javascript
   Firestore → users → Find email: narcisodrix@gmail.com
   {
     "emailVerified": ??? // Check this value
   }
   ```

3. **Test Sign-In with Debug Logs**:
   ```bash
   # Run app and watch logs
   flutter run
   
   # Look for these debug messages:
   🔐 AuthService.signInWithEmail: Attempting sign-in for narcisodrix@gmail.com
   ✅ AuthService: Firebase Auth sign-in successful
   📄 AuthService: User data fetched from Firestore
   👤 AuthService: User found - Email: ..., Role: ...
   ✉️ AuthService: Email verification check - Firestore: ..., Firebase Auth: ...
   ```

---

## Quick Fix for Existing Accounts

If you have existing accounts that can't sign in, you have 3 options:

### Option 1: Manual Firestore Update (Fastest)
```javascript
// In Firebase Console → Firestore → users collection
// For each user document, add:
{
  "emailVerified": true,
  "emailVerifiedAt": new Date()
}
```

### Option 2: Let Auto-Migration Handle It
- Users with Firebase Auth emailVerified = true will auto-migrate
- Users with Firebase Auth emailVerified = false need to verify email

### Option 3: Create Migration Script (Recommended for many users)
```dart
// Create a one-time migration function
Future<void> migrateExistingUsers() async {
  final users = await FirebaseFirestore.instance.collection('users').get();
  
  for (var doc in users.docs) {
    final data = doc.data();
    
    // Skip if already has emailVerified field
    if (data.containsKey('emailVerified')) continue;
    
    // Get Firebase Auth user
    final authUser = await FirebaseAuth.instance.userChanges().first;
    
    // Update with Firebase Auth verification status
    await doc.reference.update({
      'emailVerified': authUser?.emailVerified ?? false,
      'emailVerifiedAt': authUser?.emailVerified == true 
          ? FieldValue.serverTimestamp() 
          : null,
    });
  }
}
```

---

## Recommended Actions NOW

### For narcisodrix@gmail.com:

1. **Check if it's a Google account**:
   - If yes → Try signing in with Google button
   - If no → Continue below

2. **Check password**:
   - Try "Forgot Password" to reset
   - Use the new password to sign in

3. **Check Firestore**:
   - Go to Firebase Console
   - Firestore → users → find narcisodrix@gmail.com
   - Manually add:
     ```javascript
     {
       "emailVerified": true,
       "emailVerifiedAt": firebase.firestore.FieldValue.serverTimestamp()
     }
     ```

4. **Try signing in again**:
   - Run the app with `flutter run`
   - Watch console logs for debug messages
   - Report back what you see!

---

## Console Log Interpretation

### Success Flow:
```
🔐 AuthService.signInWithEmail: Attempting sign-in for narcisodrix@gmail.com
✅ AuthService: Firebase Auth sign-in successful
📄 AuthService: User data fetched from Firestore
👤 AuthService: User found - Email: narcisodrix@gmail.com, Role: user
✉️ AuthService: Email verification check - Firestore: true, Firebase Auth: true
✅ AuthService: Email verified - proceeding with sign-in
✅ Sign-in successful for user: <uid>
```

### Email Not Verified:
```
🔐 AuthService.signInWithEmail: Attempting sign-in for narcisodrix@gmail.com
✅ AuthService: Firebase Auth sign-in successful
📄 AuthService: User data fetched from Firestore
👤 AuthService: User found - Email: narcisodrix@gmail.com, Role: user
✉️ AuthService: Email verification check - Firestore: false, Firebase Auth: false
❌ AuthService: Email not verified - blocking sign-in
```

### Legacy User Auto-Migration:
```
🔐 AuthService.signInWithEmail: Attempting sign-in for narcisodrix@gmail.com
✅ AuthService: Firebase Auth sign-in successful
📄 AuthService: User data fetched from Firestore
👤 AuthService: User found - Email: narcisodrix@gmail.com, Role: user
✉️ AuthService: Email verification check - Firestore: null, Firebase Auth: true
🔄 AuthService: Legacy user - Using Firebase Auth emailVerified: true
🔄 AuthService: Migrating legacy user to new verification system...
✅ AuthService: Migrated email verification status for legacy user: <uid>
✅ AuthService: Email verified - proceeding with sign-in
```

---

## Next Steps

1. Run the app: `flutter run`
2. Try signing in with narcisodrix@gmail.com
3. **Copy and share the console logs** (look for 🔐 emoji)
4. Check Firebase Console for the account status
5. Report back with findings!

---

**Created**: October 30, 2025
**Status**: ✅ Enhanced with debug logging
