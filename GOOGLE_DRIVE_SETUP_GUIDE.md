# Google Drive Integration Setup Guide

## Overview
This guide will help you set up and test the Google Drive integration for PawSense clinic document management.### Troubleshooting

### Common Issues
1. **403 Error - Service Accounts do not have storage quota**: 
   - **Solution**: You MUST use a Shared Drive (Google Workspace feature). Regular Google Drive folders don't work with Service Accounts.
   - Create a Shared Drive and move your folder there, then add the service account as a member.

2. **Authentication Error**: Check service account JSON file placement and permissions

3. **Permission Denied**: Ensure service account has access to the Shared Drive with proper permissions

4. **File Upload Failed**: Check internet connection and folder ID

5. **Missing Dependencies**: Run `flutter pub get`Prerequisites
1. Google Cloud Console project with Drive API enabled
2. Service Account JSON key file
3. Google Drive folder with proper permissions

## Setup Steps

### 1. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select your project
3. Enable the Google Drive API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"

### 2. Service Account Setup
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "Service Account"
3. Fill in service account details
4. Skip role assignment for now
5. Click "Done"
6. Click on the created service account
7. Go to "Keys" tab
8. Click "Add Key" > "Create new key" > "JSON"
9. Download the JSON file
10. Rename it to `google_service_account.json`
11. Place it in `assets/` folder

### 3. Google Drive Shared Drive Setup ⚠️ **IMPORTANT**
**Note**: Service Accounts cannot upload to regular Google Drive folders due to storage quota limitations. You MUST use a Shared Drive (Google Workspace feature).

#### Option A: Use Shared Drive (Recommended)
1. **Create a Shared Drive** (requires Google Workspace):
   - Go to [Google Drive](https://drive.google.com/)
   - Click "Shared drives" in the left sidebar
   - Click "New" > "Shared drive"
   - Name it "PawSense Documents" (or similar)
   - Click "Create"

2. **Create folder in Shared Drive**:
   - Open your new Shared Drive
   - Create a folder named "Clinic Documents"
   - Copy the folder ID from the URL (the long string after `/folders/`)

3. **Add Service Account to Shared Drive**:
   - Right-click on the Shared Drive name
   - Click "Manage members"
   - Click "Add members"
   - Enter your service account email (found in the JSON file)
   - Set role to "Contributor" or "Content manager"
   - Click "Send"

#### Option B: Use OAuth Delegation (Alternative)
If you don't have Google Workspace, you'll need to implement OAuth delegation instead of Service Account authentication. This requires user consent for each upload.

### 4. Testing the Implementation

#### Test Google Drive Service
```dart
// Test basic connectivity
final driveService = GoogleDriveService();
await driveService.initialize();

// Test image upload
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.gallery);
if (image != null) {
  final bytes = await image.readAsBytes();
  final result = await driveService.uploadImage(
    fileName: 'test_image.jpg',
    imageBytes: bytes,
    mimeType: 'image/jpeg',
  );
  print('Upload result: $result');
}
```

#### Test Document Management Service
```dart
// Test certification upload with image
final docService = DocumentManagementService();

final certification = ClinicCertification(
  id: 'test_cert_1',
  clinicId: 'test_clinic',
  certificationType: 'Business License',
  issuingAuthority: 'Local Government',
  issueDate: DateTime.now(),
  expiryDate: DateTime.now().add(Duration(days: 365)),
  status: CertificationStatus.active,
);

final result = await docService.uploadCertificationWithImage(
  certification: certification,
  imageBytes: imageBytes,
  fileName: 'business_license.jpg',
);
```

#### Test License Upload
```dart
// Test license upload
final license = ClinicLicense(
  id: 'test_license_1',
  clinicId: 'test_clinic',
  licenseNumber: 'VET2024001',
  licenseType: 'Veterinary Practice License',
  issuingAuthority: 'Department of Agriculture',
  issueDate: DateTime.now(),
  expiryDate: DateTime.now().add(Duration(days: 1095)), // 3 years
  status: LicenseStatus.active,
);

final result = await docService.uploadLicenseWithImage(
  license: license,
  imageBytes: imageBytes,
  fileName: 'vet_license.jpg',
);
```

### 5. Testing in Signup Flow
1. Navigate to the clinic signup page
2. Go to step 3 (Document Upload)
3. Try uploading certification images
4. Try adding license information with images
5. Complete the signup process

## File Structure
```
lib/core/
├── models/
│   ├── clinic_certification_model.dart ✅
│   ├── clinic_license_model.dart ✅
│   └── models.dart ✅
├── services/
│   ├── google_drive/
│   │   └── google_drive_service.dart ✅
│   └── documents/
│       └── document_management_service.dart ✅
└── widgets/
    └── examples/
        └── google_drive_upload_example.dart ✅

assets/
└── google_service_account.json (you need to add this)

pubspec.yaml ✅ (dependencies added)
```

## Key Features Implemented
- ✅ Service Account authentication
- ✅ Image upload to specific Google Drive folder
- ✅ File metadata management
- ✅ Permission handling
- ✅ Error handling and user feedback
- ✅ Integration with Firestore
- ✅ Unified document management service
- ✅ Updated signup UI with image upload
- ✅ Support for both certifications and licenses

## Troubleshooting

### Common Issues
1. **Authentication Error**: Check service account JSON file placement and permissions
2. **Permission Denied**: Ensure service account has access to the Drive folder
3. **File Upload Failed**: Check internet connection and folder ID
4. **Missing Dependencies**: Run `flutter pub get`

### Debug Mode
The services include print statements for debugging. Check the console for detailed logs:
- Authentication status
- Upload progress
- Error messages
- File IDs and metadata

### Production Considerations
- Remove debug print statements
- Add proper error logging
- Implement retry mechanisms
- Add progress indicators for large uploads
- Consider file size limits

## Next Steps
1. Test with real Google Service Account credentials
2. Verify uploads appear in correct Drive folder
3. Test document retrieval and display
4. Implement document deletion if needed
5. Add bulk upload capabilities
6. Implement document validation (file types, sizes)

## Support
If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify Google Cloud Console settings
3. Confirm service account permissions
4. Test with a simple image upload first
5. Ensure all dependencies are properly installed
