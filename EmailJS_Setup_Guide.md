# 📧 EmailJS Template Setup Guide

## 🎯 Template Configuration

### Step 1: Create Template in EmailJS
1. ✅ Click **"Create Template"** button in EmailJS (COMPLETED)
2. ✅ Set **Template ID**: `template_hgo0lrs` (COMPLETED)
3. ✅ Set **Template Name**: `PawSense OTP Email` (COMPLETED)

### Step 2: Configure Template Settings

**To Email Field:**
```
{{to_email}}
```

**Subject Field:**
```
{{subject}}
```

**HTML Content:**
Copy the entire content from `emailjs_template_simple.html` file into the HTML content area.

### Step 3: Template Variables (Auto-populated by your Flutter app)

| Variable | Description | Example |
|----------|-------------|---------|
| `{{to_email}}` | Recipient email | `user@example.com` |
| `{{to_name}}` | Recipient name | `John Doe` |
| `{{subject}}` | Email subject | `PawSense - Password Reset Code` |
| `{{otp_code}}` | 6-digit OTP | `123456` |
| `{{purpose}}` | Action purpose | `reset your password` |
| `{{instructions}}` | Usage instructions | `Enter this code in the app...` |

**Note:** App name is hardcoded as "PawSense" in the template.

### Step 4: Test Template

Use these test values to preview:
```json
{
  "to_name": "John Doe",
  "to_email": "test@example.com",
  "subject": "PawSense - Password Reset Code",
  "otp_code": "123456",
  "purpose": "reset your password",
  "instructions": "Enter this code in the app to reset your password. This code will expire in 10 minutes."
}
```

## 🎨 Email Preview

Your OTP email will have:
- ✅ PawSense logo in header and footer
- ✅ Purple gradient branding (#7C3AED)
- ✅ Large, prominent OTP code display
- ✅ Security warnings and instructions
- ✅ Professional footer with company info
- ✅ Mobile-responsive design
- ✅ Pet/veterinary themed styling 🐾

## 🔧 Logo Configuration

The template uses your logo from:
```
https://huggingface.co/datasets/PawSense/logo/resolve/main/logo.png
```

This URL points to your logo hosted on Hugging Face where `logo.png` is stored.

If this URL doesn't work, you can:
1. Upload logo to EmailJS media library
2. Replace the URL in the template
3. Or use a different image hosting service

## ✅ Final Checklist

- [ ] Template ID set to `template_otp`
- [ ] HTML content copied from `emailjs_template_simple.html`
- [ ] Subject field set to `{{subject}}`
- [ ] To email field set to `{{to_email}}`
- [ ] Test email sent successfully
- [ ] Logo displays correctly
- [ ] All variables populate properly

## 🚀 Ready to Use!

Once you complete this setup, your Flutter app will automatically send beautiful, branded OTP emails for:
- Password reset requests
- Email verification during signup
- Any future OTP-based authentication flows