# Firebase Cloud Functions Deployment Guide

## Setup Instructions

### 1. Initialize Firebase Functions (if not already done)

If you haven't already initialized Firebase Functions in your project:

```bash
# In the project root directory
firebase init functions
```

Select:
- JavaScript (already created)
- Install dependencies with npm (Yes)

### 2. Install Dependencies

```bash
cd functions
npm install
```

### 3. Deploy Cloud Functions

Deploy the functions to Firebase:

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:resetPasswordWithOTP
```

### 4. Test the Deployment

After deployment, you should see output like:
```
✔  functions[resetPasswordWithOTP(us-central1)]: Successful create operation.
Function URL (resetPasswordWithOTP): https://us-central1-YOUR-PROJECT.cloudfunctions.net/resetPasswordWithOTP
```

## Function Details

### `resetPasswordWithOTP`

**Purpose**: Updates user password using Firebase Admin SDK after OTP verification

**Parameters**:
- `email` (string): User's email address
- `newPassword` (string): New password to set
- `otp` (string): OTP code for verification

**Returns**:
```javascript
{
  success: true/false,
  message: "Password updated successfully" / error message
}
```

**Error Codes**:
- `invalid-argument`: Missing required parameters
- `not-found`: Invalid or expired OTP / User not found
- `deadline-exceeded`: OTP has expired (>10 minutes)
- `permission-denied`: Too many invalid attempts
- `internal`: Server error

## Security Notes

1. **OTP Validation**: The function validates OTPs stored in Firestore
2. **Expiration**: OTPs expire after 10 minutes
3. **Attempt Limit**: Maximum 3 attempts per OTP
4. **Admin SDK**: Uses Firebase Admin SDK to bypass authentication requirement
5. **Logging**: Password resets are logged in `password_reset_logs` collection

## Testing Locally

To test functions locally before deploying:

```bash
# Start the Firebase emulator
cd functions
npm run serve

# The function will be available at:
# http://localhost:5001/YOUR-PROJECT/us-central1/resetPasswordWithOTP
```

## Troubleshooting

### Function not found error
- Ensure functions are deployed: `firebase deploy --only functions`
- Check Firebase console: Functions section

### CORS errors
- The function uses `https.onCall` which handles CORS automatically
- No additional configuration needed

### Authentication errors
- Verify Firebase Admin SDK is properly initialized
- Check that the service account has proper permissions

### Region issues
If you need to change the region:
```javascript
exports.resetPasswordWithOTP = functions.region('asia-southeast1').https.onCall(...)
```

## Firebase Console Configuration

1. Go to Firebase Console → Functions
2. Verify the function is deployed
3. Check logs for any errors
4. Monitor usage and performance

## Cost Considerations

- Cloud Functions have a free tier (2M invocations/month)
- Password resets are lightweight operations
- Monitor usage in Firebase Console

## Update flutter app

After deploying, the Flutter app will automatically use the Cloud Functions.
Make sure `cloud_functions` package is added to `pubspec.yaml` (already done).

## Next Steps

After successful deployment:
1. Test password reset flow in the app
2. Monitor Cloud Functions logs
3. Check `password_reset_logs` collection for audit trail
