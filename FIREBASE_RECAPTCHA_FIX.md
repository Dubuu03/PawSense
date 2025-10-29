# Firebase Authentication Fix - reCAPTCHA Token Error

## Error Analysis
```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signInWithPassword)
with exception - The supplied auth credential is incorrect, malformed or has expired.
I/FirebaseAuth: Logging in as narcisodrix@gmail.com with empty reCAPTCHA token
```

## Root Cause
Firebase is requiring reCAPTCHA verification but failing because:
1. **SHA-1 certificate not added to Firebase** (most likely)
2. **Email Enumeration Protection enabled** without proper setup
3. **App Check not configured**

---

## SOLUTION 1: Add SHA-1 Certificate to Firebase (Recommended)

### Your SHA-1 Debug Certificate:
```
FB:A2:8B:BD:8B:E7:85:BA:30:94:0B:F1:67:E2:9C:4A:9E:A4:D3:09
```

### Step-by-Step Instructions:

#### 1. Go to Firebase Console
- Open: https://console.firebase.google.com/
- Select your **PawSense** project
- Click the **gear icon** ⚙️ (Project Settings)

#### 2. Navigate to Your Android App
- Scroll down to **"Your apps"** section
- Find your Android app: `com.example.pawsense`
- Click on it to expand settings

#### 3. Add SHA-1 Certificate
- Scroll to **"SHA certificate fingerprints"** section
- Click **"Add fingerprint"**
- Paste this SHA-1:
  ```
  FB:A2:8B:BD:8B:E7:85:BA:30:94:0B:F1:67:E2:9C:4A:9E:A4:D3:09
  ```
- Click **"Save"**

#### 4. Download New google-services.json
- After adding SHA-1, Firebase will update your configuration
- Click **"Download google-services.json"** button
- Replace the old file:
  ```bash
  # Old location: android/app/google-services.json
  # Replace with newly downloaded file
  ```

#### 5. Clean and Rebuild
```bash
cd /Users/drixnarciso/Documents/Thesis/PawSense
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter run
```

---

## SOLUTION 2: Disable Email Enumeration Protection (Temporary)

If Solution 1 doesn't work immediately, try this:

### Steps:
1. Go to Firebase Console
2. Navigate to **Authentication** → **Settings**
3. Click on **"User actions"** tab
4. Find **"Email enumeration protection"**
5. Toggle it **OFF** (temporarily)
6. Try signing in again
7. After SHA-1 is added (Solution 1), you can re-enable it

---

## SOLUTION 3: Configure App Check (Advanced)

If you want to keep security features enabled:

### Add App Check Dependencies

**File**: `android/app/build.gradle.kts`

```kotlin
dependencies {
    // Add App Check for Play Integrity
    implementation("com.google.firebase:firebase-appcheck-playintegrity:17.1.1")
}
```

**File**: `pubspec.yaml`

```yaml
dependencies:
  firebase_app_check: ^0.2.1+8
```

**File**: `lib/main.dart`

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use .playIntegrity for production
  );
  
  // Rest of your initialization...
  runApp(const PawSenseApp());
}
```

---

## Quick Verification Steps

### After Applying Solution 1:

1. **Verify SHA-1 is added**:
   - Go to Firebase Console
   - Project Settings → Your Android App
   - Check if SHA-1 is listed under "SHA certificate fingerprints"

2. **Verify google-services.json is updated**:
   ```bash
   cat android/app/google-services.json | grep "firebase_url"
   # Should show your project URL
   ```

3. **Clean build and test**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Watch logs**:
   ```
   # Should NOT see "empty reCAPTCHA token" anymore
   # Should see successful authentication
   ```

---

## Understanding the Warnings

### ✅ Can be ignored:
```
W/System: Ignoring header X-Firebase-Locale because its value was null.
```
This is harmless - just means locale header is not set.

### ⚠️ Should fix (but not blocking):
```
W/LocalRequestInterceptor: Error getting App Check token; using placeholder token instead.
```
This is a warning that App Check is not configured. Not required for basic auth to work.

### ❌ Must fix (blocking sign-in):
```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signInWithPassword)
```
This is the actual error blocking sign-in. Fixed by adding SHA-1.

---

## Why This Happens

### Firebase Email Enumeration Protection
Firebase has a security feature that prevents attackers from discovering which emails are registered by:
1. Requiring reCAPTCHA verification for authentication attempts
2. Using App Check to verify requests come from your app
3. Validating the app signature using SHA-1 certificate

### Without SHA-1:
- Firebase can't verify the request comes from your legitimate app
- reCAPTCHA token remains empty
- Authentication is blocked for security reasons

### With SHA-1:
- Firebase verifies your app's signature
- Generates proper reCAPTCHA token
- Authentication proceeds normally ✅

---

## Testing After Fix

### Expected Success Logs:
```
I/flutter: 🔐 Attempting sign-in with email: narcisodrix@gmail.com
I/flutter: 🔐 AuthService.signInWithEmail: Attempting sign-in for narcisodrix@gmail.com
I/flutter: ✅ AuthService: Firebase Auth sign-in successful
I/flutter: 📄 AuthService: User data fetched from Firestore
I/flutter: 👤 AuthService: User found - Email: narcisodrix@gmail.com, Role: user
I/flutter: ✉️ AuthService: Email verification check - Firestore: true, Firebase Auth: true
I/flutter: ✅ AuthService: Email verified - proceeding with sign-in
I/flutter: ✅ Sign-in successful for user: <uid>
```

### No More Errors:
- ❌ "empty reCAPTCHA token" - Gone
- ❌ "auth credential is incorrect" - Gone
- ✅ Sign-in works!

---

## Additional Notes

### For Production Release:
When building for release, you'll need to add the **release SHA-1** as well:

```bash
# Generate release keystore (if you haven't)
keytool -genkey -v -keystore ~/pawsense-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pawsense

# Get release SHA-1
keytool -list -v -keystore ~/pawsense-release-key.jks -alias pawsense | grep "SHA1"
```

Then add that SHA-1 to Firebase as well.

### For Multiple Developers:
Each developer needs to add their debug SHA-1:
```bash
# Each developer runs this and adds their SHA-1 to Firebase
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1"
```

---

## Troubleshooting

### If SHA-1 doesn't work immediately:
1. Wait 5-10 minutes for Firebase to propagate changes
2. Download new google-services.json
3. Do a complete clean:
   ```bash
   flutter clean
   cd android && ./gradlew clean
   cd ..
   flutter pub get
   flutter run
   ```

### If you get "google-services.json is missing":
```bash
# Make sure file is in correct location
ls -la android/app/google-services.json

# If missing, download from Firebase Console
```

### If still not working:
1. Check Firebase Console for any error messages
2. Verify package name matches: `com.example.pawsense`
3. Ensure Firebase Authentication is enabled for Email/Password
4. Try disabling Email Enumeration Protection temporarily

---

## Summary

**MAIN FIX**: Add SHA-1 certificate to Firebase Console

**Your SHA-1**: `FB:A2:8B:BD:8B:E7:85:BA:30:94:0B:F1:67:E2:9C:4A:9E:A4:D3:09`

**Steps**:
1. ✅ Go to Firebase Console → Project Settings
2. ✅ Add SHA-1 certificate
3. ✅ Download new google-services.json
4. ✅ Replace old file
5. ✅ Clean build: `flutter clean && flutter pub get`
6. ✅ Run: `flutter run`
7. ✅ Test sign-in

**Expected Result**: Sign-in works without reCAPTCHA errors! 🎉

---

**Created**: October 30, 2025
**Issue**: Empty reCAPTCHA token / Auth credential error
**Solution**: Add SHA-1 certificate to Firebase
**Status**: ✅ Solution provided - Ready to implement
