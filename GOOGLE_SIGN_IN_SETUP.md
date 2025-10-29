# Google Sign-In Setup Guide for PawSense

## Overview
This guide explains how to set up Google Sign-In for the PawSense mobile app.

## Prerequisites
- Firebase project with Authentication enabled
- Google Sign-In provider enabled in Firebase Console
- Flutter app with google_sign_in package (already added)

## Firebase Console Configuration

### 1. Enable Google Sign-In Provider
1. Go to Firebase Console → Authentication → Sign-in method
2. Click on "Google" provider
3. Enable the provider
4. Add your project's support email
5. Save the configuration

### 2. Add SHA-1 Fingerprint (Android)
For Google Sign-In to work on Android, you need to add your app's SHA-1 fingerprint:

#### Get Debug SHA-1 Fingerprint:
```bash
# For macOS/Linux:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For Windows:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Get Release SHA-1 Fingerprint:
```bash
# If you have a release keystore:
keytool -list -v -keystore /path/to/your/release-keystore.keystore -alias your-alias
```

#### Add SHA-1 to Firebase:
1. Go to Firebase Console → Project Settings
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Click "Add fingerprint" and paste your SHA-1 fingerprint
5. Click "Save"

### 3. Download google-services.json
1. In Firebase Console → Project Settings → Your apps
2. Click on your Android app
3. Download the `google-services.json` file
4. Place it in `android/app/` directory (should already be there)

## iOS Configuration

### 1. Download GoogleService-Info.plist
1. In Firebase Console → Project Settings → Your apps
2. Click on your iOS app
3. Download the `GoogleService-Info.plist` file
4. Add it to your iOS project in Xcode

### 2. Add URL Scheme
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project → Runner → Info
3. Add a new URL Scheme with your reversed client ID
4. You can find the reversed client ID in `GoogleService-Info.plist`

## Code Implementation

The Google Sign-In functionality has been implemented with:

### 1. Dependencies Added
- `google_sign_in: ^6.1.5` added to pubspec.yaml

### 2. AuthService Updated
- Added `signInWithGoogle()` method to handle Google authentication
- Automatic user data creation/update for Google users
- Proper error handling for Google Sign-In

### 3. UI Components
- `GoogleSignInButton` widget created for consistent styling
- Added to sign-in page with loading states
- Divider with "or" text for visual separation

### 4. Sign-In Page Updated
- Google Sign-In button added below email/password form
- Loading state management for Google Sign-In
- Error handling with user-friendly messages

## Testing

### Debug Testing
1. Make sure you've added the debug SHA-1 fingerprint to Firebase
2. Run the app on a physical device or emulator with Google services
3. Test the Google Sign-In flow

### Release Testing
1. Add your release SHA-1 fingerprint to Firebase
2. Build and test the release version
3. Verify the Google Sign-In works in production

## Important Notes

1. **Physical Device Required**: Google Sign-In may not work properly on some emulators
2. **Google Services**: Ensure the device has Google Play Services installed
3. **Network Required**: Google Sign-In requires internet connection
4. **SHA-1 Fingerprints**: Must be correctly configured in Firebase Console
5. **Package Name**: Must match exactly between Firebase and your app

## Troubleshooting

### Common Issues:

1. **Error: "Sign in cancelled by user"**
   - User tapped outside the Google sign-in popup
   - Handle gracefully in the app

2. **Error: "DEVELOPER_ERROR"**
   - SHA-1 fingerprint not added to Firebase Console
   - Wrong package name configuration

3. **Error: "NETWORK_ERROR"**
   - No internet connection
   - Google Play Services not available

4. **No Google accounts available**
   - Device doesn't have Google accounts added
   - Google Play Services not properly configured

### Debug Steps:
1. Check Firebase Console configuration
2. Verify SHA-1 fingerprints are added
3. Ensure google-services.json/GoogleService-Info.plist are up to date
4. Test on physical device with Google services
5. Check app package name matches Firebase configuration

## Success Indicators

When properly configured, users should be able to:
1. Tap the "Continue with Google" button
2. See Google account selection popup
3. Sign in successfully and be redirected to home page
4. Have their user data automatically created in Firestore
5. Sign in again without issues on subsequent attempts