import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service class for sending OTP emails
/// Uses EmailJS service for sending emails without a backend
class EmailService {
  static const String _emailJSServiceId = 'service_pawsense';
  static const String _emailJSTemplateId = 'template_hgo0lrs';
  static const String _emailJSUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Sends an OTP email for password reset
  Future<bool> sendPasswordResetOTP({
    required String email,
    required String otp,
    required String recipientName,
  }) async {
    return await _sendOTPEmail(
      email: email,
      otp: otp,
      recipientName: recipientName,
      subject: 'PawSense - Password Reset Code',
      purpose: 'reset your password',
      instructions: 'Enter this code in the app to reset your password. This code will expire in 10 minutes.',
    );
  }

  /// Sends an OTP email for email verification
  Future<bool> sendEmailVerificationOTP({
    required String email,
    required String otp,
    required String recipientName,
  }) async {
    return await _sendOTPEmail(
      email: email,
      otp: otp,
      recipientName: recipientName,
      subject: 'PawSense - Email Verification Code',
      purpose: 'verify your email address',
      instructions: 'Enter this code in the app to verify your email address. This code will expire in 10 minutes.',
    );
  }

  /// Generic method to send OTP emails
  Future<bool> _sendOTPEmail({
    required String email,
    required String otp,
    required String recipientName,
    required String subject,
    required String purpose,
    required String instructions,
  }) async {
    try {
      // Get EmailJS public key from environment variables
      final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'];
      if (publicKey == null || publicKey.isEmpty) {
        debugPrint('❌ EmailJS public key not found in environment variables');
        return false;
      }

      final response = await http.post(
        Uri.parse(_emailJSUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (compatible; PawSense/1.0; +https://pawsense.app)',
          'Origin': 'https://pawsense.app',
          'Referer': 'https://pawsense.app',
        },
        body: jsonEncode({
          'service_id': _emailJSServiceId,
          'template_id': _emailJSTemplateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email.trim().toLowerCase(),
            'to_name': recipientName,
            'subject': subject,
            'otp_code': otp,
            'purpose': purpose,
            'instructions': instructions,
            'support_email': 'support@pawsense.com',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ OTP email sent successfully to $email');
        return true;
      } else {
        debugPrint('❌ Failed to send OTP email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending OTP email: $e');
      return false;
    }
  }

  /// Fallback method using a simple email template
  /// This creates a basic HTML email that can be sent via any email service
  String generateOTPEmailHTML({
    required String recipientName,
    required String otp,
    required String purpose,
    required String instructions,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PawSense - OTP Verification</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #8B4FC3 0%, #A855F7 100%);
            padding: 40px 30px;
            text-align: center;
            color: white;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .tagline {
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            color: #333;
            margin-bottom: 20px;
        }
        .otp-section {
            background-color: #f8f9fa;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
            border-left: 4px solid #8B4FC3;
        }
        .otp-title {
            font-size: 16px;
            color: #666;
            margin-bottom: 15px;
        }
        .otp-code {
            font-size: 32px;
            font-weight: bold;
            color: #8B4FC3;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
            background-color: white;
            padding: 15px 30px;
            border-radius: 8px;
            border: 2px dashed #8B4FC3;
            display: inline-block;
        }
        .instructions {
            font-size: 14px;
            color: #666;
            line-height: 1.6;
            margin: 20px 0;
        }
        .security-notice {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .security-title {
            font-weight: bold;
            color: #856404;
            margin-bottom: 5px;
        }
        .security-text {
            font-size: 13px;
            color: #856404;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e9ecef;
        }
        .footer-text {
            font-size: 12px;
            color: #999;
            line-height: 1.5;
        }
        .support-link {
            color: #8B4FC3;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🐾 PawSense</div>
            <div class="tagline">Your Pet Care Companion</div>
        </div>
        
        <div class="content">
            <div class="greeting">Hello $recipientName,</div>
            
            <p>You requested to $purpose for your PawSense account. Please use the verification code below:</p>
            
            <div class="otp-section">
                <div class="otp-title">Your Verification Code</div>
                <div class="otp-code">$otp</div>
            </div>
            
            <div class="instructions">
                $instructions
            </div>
            
            <div class="security-notice">
                <div class="security-title">🔒 Security Notice</div>
                <div class="security-text">
                    • Never share this code with anyone<br>
                    • PawSense will never ask for this code via phone or email<br>
                    • If you didn't request this code, please ignore this email
                </div>
            </div>
            
            <p>If you're having trouble, please contact our support team at <a href="mailto:support@pawsense.com" class="support-link">support@pawsense.com</a></p>
            
            <p>Thank you for using PawSense!</p>
        </div>
        
        <div class="footer">
            <div class="footer-text">
                This email was sent by PawSense<br>
                © 2024 PawSense. All rights reserved.
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Alternative method using Firebase Cloud Functions (if you have it set up)
  /// This would require a Cloud Function endpoint
  Future<bool> sendOTPViaCloudFunction({
    required String email,
    required String otp,
    required String recipientName,
    required String purpose,
  }) async {
    try {
      // This would be your Cloud Function URL
      const cloudFunctionUrl = 'https://your-region-your-project.cloudfunctions.net/sendOTPEmail';
      
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp,
          'recipientName': recipientName,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        debugPrint('❌ Cloud Function error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error calling Cloud Function: $e');
      return false;
    }
  }
}