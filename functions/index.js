const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function to reset user password after OTP verification
 * This bypasses the need for authentication since it uses Admin SDK
 * Note: This function allows unauthenticated calls because it's for password reset
 */
exports.resetPasswordWithOTP = functions.https.onCall(async (data, context) => {
  try {
    const { email, newPassword, otp } = data;

    // Log the request for debugging
    console.log('Password reset requested for:', email ? email.trim().toLowerCase() : 'no email');
    console.log('OTP provided:', otp);

    // Validate inputs
    if (!email || !newPassword || !otp) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email, new password, and OTP are required'
      );
    }

    // Normalize email
    const normalizedEmail = email.trim().toLowerCase();
    
    // Debug: Check what OTPs exist for this email
    const debugSnapshot = await admin.firestore()
      .collection('otps')
      .where('email', '==', normalizedEmail)
      .get();
    
    console.log('Found OTPs for', normalizedEmail, ':', debugSnapshot.docs.map(doc => ({
      id: doc.id,
      data: doc.data()
    })));

    // Verify OTP from Firestore
    const otpSnapshot = await admin.firestore()
      .collection('otps')
      .where('email', '==', normalizedEmail)
      .where('purpose', '==', 'passwordReset')  // Changed from 'password_reset' to 'passwordReset'
      .where('code', '==', otp)
      .limit(1)
      .get();

    if (otpSnapshot.empty) {
      throw new functions.https.HttpsError(
        'not-found',
        'Invalid or expired OTP'
      );
    }

    const otpDoc = otpSnapshot.docs[0];
    const otpData = otpDoc.data();

    // Check if OTP is expired (10 minutes)
    const otpTimestamp = otpData.createdAt.toDate();
    const now = new Date();
    const diffMinutes = (now - otpTimestamp) / 1000 / 60;

    if (diffMinutes > 10) {
      // Delete expired OTP
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'OTP has expired'
      );
    }

    // Check attempt count
    if (otpData.attemptCount >= 3) {
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'permission-denied',
        'Too many invalid attempts'
      );
    }

    // Get user by email
    let user;
    try {
      user = await admin.auth().getUserByEmail(normalizedEmail);
    } catch (error) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found'
      );
    }

    // Update password using Admin SDK
    await admin.auth().updateUser(user.uid, {
      password: newPassword
    });

    // Delete the OTP after successful password reset
    await otpDoc.ref.delete();

    // Log the password reset
    await admin.firestore().collection('password_reset_logs').add({
      uid: user.uid,
      email: normalizedEmail,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      method: 'otp'
    });

    return {
      success: true,
      message: 'Password updated successfully'
    };

  } catch (error) {
    console.error('Error in resetPasswordWithOTP:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to reset password: ' + error.message
    );
  }
});

/**
 * Cloud Function to verify OTP without updating password
 * Returns a temporary token that can be used to update password
 */
exports.verifyOTP = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp, purpose } = data;

    if (!email || !otp || !purpose) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email, OTP, and purpose are required'
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Verify OTP from Firestore
    const otpSnapshot = await admin.firestore()
      .collection('otps')
      .where('email', '==', normalizedEmail)
      .where('purpose', '==', purpose)
      .where('code', '==', otp)
      .limit(1)
      .get();

    if (otpSnapshot.empty) {
      throw new functions.https.HttpsError(
        'not-found',
        'Invalid or expired OTP'
      );
    }

    const otpDoc = otpSnapshot.docs[0];
    const otpData = otpDoc.data();

    // Check if OTP is expired
    const otpTimestamp = otpData.createdAt.toDate();
    const now = new Date();
    const diffMinutes = (now - otpTimestamp) / 1000 / 60;

    if (diffMinutes > 10) {
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'OTP has expired'
      );
    }

    // Check attempt count
    if (otpData.attemptCount >= 3) {
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'permission-denied',
        'Too many invalid attempts'
      );
    }

    // Mark OTP as verified (but don't delete yet)
    await otpDoc.ref.update({
      verified: true,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: 'OTP verified successfully',
      otpId: otpDoc.id
    };

  } catch (error) {
    console.error('Error in verifyOTP:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify OTP: ' + error.message
    );
  }
});
