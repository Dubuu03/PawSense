// Example Cloud Function for sending OTP emails
// This is OPTIONAL - your current EmailJS setup works fine

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Configure email transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail', // or your email service
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password
  }
});

// Cloud function to send OTP email
exports.sendOTPEmail = functions.firestore
  .document('otps/{otpId}')
  .onCreate(async (snap, context) => {
    const otpData = snap.data();
    
    const mailOptions = {
      from: 'noreply@pawsense.com',
      to: otpData.email,
      subject: `PawSense - ${otpData.purpose === 'password_reset' ? 'Password Reset' : 'Email Verification'} Code`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Your PawSense OTP Code</h2>
          <p>Your verification code is:</p>
          <div style="font-size: 24px; font-weight: bold; color: #7C3AED; padding: 20px; text-align: center; background: #f3f4f6; border-radius: 8px;">
            ${otpData.code}
          </div>
          <p>This code will expire in 10 minutes.</p>
          <p>Best regards,<br>PawSense Team</p>
        </div>
      `
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('OTP email sent successfully');
    } catch (error) {
      console.error('Error sending OTP email:', error);
    }
  });