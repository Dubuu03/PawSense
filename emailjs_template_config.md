# EmailJS Template Configuration

## Template Settings
- **Template ID**: `template_otp`
- **Template Name**: PawSense OTP Email

## Template Variables (Parameters)
Your Flutter app sends these variables to the template:

```javascript
template_params: {
  'to_email': email.trim().toLowerCase(),
  'to_name': recipientName,
  'subject': subject,
  'otp_code': otp,
  'purpose': purpose,
  'instructions': instructions,
  'app_name': 'PawSense'
}
```

## HTML Template Content
```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
  <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    
    <!-- Header -->
    <div style="text-align: center; margin-bottom: 30px;">
      <h1 style="color: #7C3AED; margin: 0; font-size: 28px;">{{app_name}}</h1>
      <p style="color: #666; margin: 5px 0 0 0;">Veterinary Care & Pet Health</p>
    </div>
    
    <!-- Main Content -->
    <h2 style="color: #333; margin-bottom: 20px;">{{subject}}</h2>
    
    <p style="color: #666; font-size: 16px; line-height: 1.5;">
      Hello <strong>{{to_name}}</strong>,
    </p>
    
    <p style="color: #666; font-size: 16px; line-height: 1.5;">
      You requested to {{purpose}}. Please use the verification code below:
    </p>
    
    <!-- OTP Code Box -->
    <div style="text-align: center; margin: 30px 0;">
      <div style="display: inline-block; background: linear-gradient(135deg, #7C3AED 0%, #5B21B6 100%); color: white; padding: 20px 40px; border-radius: 10px; font-size: 32px; font-weight: bold; letter-spacing: 5px; box-shadow: 0 4px 15px rgba(124, 58, 237, 0.3);">
        {{otp_code}}
      </div>
    </div>
    
    <!-- Instructions -->
    <div style="background-color: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 15px; margin: 20px 0;">
      <p style="color: #92400E; margin: 0; font-size: 14px;">
        <strong>⚠️ Important:</strong> {{instructions}}
      </p>
    </div>
    
    <!-- Footer -->
    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e5e5; text-align: center;">
      <p style="color: #666; font-size: 14px; margin: 0;">
        If you didn't request this code, please ignore this email.
      </p>
      <p style="color: #666; font-size: 14px; margin: 10px 0 0 0;">
        Best regards,<br>
        <strong style="color: #7C3AED;">The PawSense Team</strong>
      </p>
    </div>
    
  </div>
</div>
```

## Subject Line Template
```
{{subject}}
```

## Settings to Configure in EmailJS
1. **Template ID**: `template_otp`
2. **To Email**: `{{to_email}}`
3. **From Name**: `PawSense Team`
4. **Reply To**: Your support email
5. **Subject**: `{{subject}}`
6. **Content**: Use the HTML template above