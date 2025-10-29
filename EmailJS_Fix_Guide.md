# 🔧 EmailJS Browser Restriction Fix

## Problem
```
❌ Failed to send OTP email: 403 - API calls are disabled for non-browser applications
```

## Solution Steps

### 1. **Update EmailJS Account Settings** (Main Solution)
1. Go to your EmailJS dashboard
2. Navigate to **Account** → **General** (top right menu)
3. Scroll down to find **"Security"** or **"API Restrictions"** section
4. Look for **"Restrict API calls to browser applications"** 
5. **UNCHECK/DISABLE** this setting ✅
6. Click **"Save"** or **"Update"**

### 2. **Alternative: Check Service-Level Settings** (If available)
1. Go to **Email Services** → **Gmail (service_pawsense)**
2. Click **"Edit Service"**
3. Look for any **"CORS"** or **"Allowed Domains"** settings
4. If found, add `*` to allow all origins
   (Note: This option may not be available in all EmailJS plans)

### 3. **Add User-Agent Header (If needed)**
Update your Flutter email service to include a browser-like User-Agent:

```dart
final response = await http.post(
  Uri.parse(_emailJSUrl),
  headers: {
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (compatible; PawSense/1.0)',
  },
  body: jsonEncode({...}),
);
```

### 4. **Test After Changes**
1. Make the settings changes in EmailJS
2. Wait 2-3 minutes for changes to propagate
3. Test the OTP flow again in your Flutter app

## Expected Result
After fixing, you should see:
```
✅ OTP email sent successfully to user@example.com
```

Instead of the 403 error.