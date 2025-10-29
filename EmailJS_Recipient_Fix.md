# 🔧 EmailJS "Recipients Address is Empty" Fix

## Problem
```
❌ Failed to send OTP email: 422 - The recipients address is empty
```

## Root Cause
Your EmailJS template doesn't have the "To Email" field properly configured to use the `{{to_email}}` variable.

## Solution

### **Fix EmailJS Template Settings**

1. **Go to EmailJS Dashboard**
2. **Navigate to Email Templates**
3. **Find your template** (`template_hgo0lrs`)
4. **Click "Edit Template"**

5. **Configure the "To Email" field**:
   - Look for **"To Email"** or **"Recipient"** field
   - Make sure it's set to: `{{to_email}}`
   - NOT your personal email address

6. **Template Configuration Should Be**:
   ```
   To Email: {{to_email}}
   From Name: PawSense Team
   Subject: {{subject}}
   ```

7. **Save the template**

## **Verification Steps**

### **Check Template Variables**
Your template should use these variables:
- `{{to_email}}` ← **This is critical for recipient**
- `{{to_name}}`
- `{{subject}}`
- `{{otp_code}}`
- `{{purpose}}`
- `{{instructions}}`

### **Test Template**
1. In EmailJS template editor, click **"Test"**
2. Fill in sample data:
   ```json
   {
     "to_email": "test@example.com",
     "to_name": "Test User",
     "subject": "Test OTP",
     "otp_code": "123456",
     "purpose": "test your setup",
     "instructions": "This is a test."
   }
   ```
3. Send test email to verify configuration

## **Common Mistakes**
❌ **Wrong**: Setting To Email to your personal email  
✅ **Correct**: Setting To Email to `{{to_email}}`

❌ **Wrong**: Hardcoding recipient email  
✅ **Correct**: Using variable for dynamic recipients

After fixing this, your Flutter app should successfully send OTP emails! 🐾