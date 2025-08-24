import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:image_picker/image_picker.dart';

/// Alternative Google Drive service using OAuth for regular Google Drive folders
/// Use this if you don't have Google Workspace (Shared Drives)
class GoogleDriveOAuthService {
  static const String _folderId = '1_bvOevbYnmHnEgy7wzCT8eoL9EWVLqjN';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];
  
  drive.DriveApi? _driveApi;
  AutoRefreshingAuthClient? _authClient;
  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize with OAuth credentials (requires user consent)
  Future<void> initializeWithOAuth({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      if (_driveApi != null) return; // Already initialized

      // Create OAuth credentials
      final identifier = ClientId(clientId, clientSecret);
      
      // This will open a browser for user consent
      _authClient = await clientViaUserConsent(
        identifier,
        _scopes,
        _prompt,
      );
      
      // Initialize Drive API
      _driveApi = drive.DriveApi(_authClient!);
      
      print('Google Drive OAuth API initialized successfully');
    } catch (e) {
      print('Error initializing Google Drive OAuth API: $e');
      throw Exception('Failed to initialize Google Drive OAuth API: $e');
    }
  }

  /// Prompt function for OAuth consent
  void _prompt(String url) {
    print('Please open the following URL in your browser:');
    print(url);
    print('After authorization, the authentication will complete automatically.');
  }

  /// Upload image bytes to Google Drive using OAuth
  Future<String?> uploadImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
    String? description,
    Map<String, String>? properties,
  }) async {
    if (_driveApi == null) {
      throw Exception('Google Drive API not initialized. Call initializeWithOAuth first.');
    }
    
    try {
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId]
        ..description = description
        ..properties = properties;

      // Create media upload
      final media = drive.Media(
        Stream.fromIterable([imageBytes]),
        imageBytes.length,
        contentType: mimeType,
      );

      // Upload file (no supportsAllDrives needed for regular Drive)
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id,name,webViewLink,webContentLink,thumbnailLink,createdTime',
      );

      // Make file publicly viewable
      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        uploadedFile.id!,
      );

      print('File uploaded successfully: ${uploadedFile.id}');
      return uploadedFile.id;
    } catch (e) {
      print('Error uploading image bytes to Google Drive: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Pick and upload image
  Future<String?> pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final imageBytes = await pickedFile.readAsBytes();
      final fileName = 'clinic_document_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return await uploadImageBytes(
        imageBytes: imageBytes,
        fileName: fileName,
        mimeType: 'image/jpeg',
        description: 'Clinic document uploaded via PawSense',
      );
    } catch (e) {
      print('Error picking and uploading image: $e');
      throw Exception('Failed to pick and upload image: $e');
    }
  }

  /// Delete a file from Google Drive
  Future<void> deleteFile(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Google Drive API not initialized.');
    }
    
    try {
      await _driveApi!.files.delete(fileId);
      print('File deleted successfully: $fileId');
    } catch (e) {
      print('Error deleting file from Google Drive: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
  }
}

/// Usage example:
/// ```dart
/// final oauthService = GoogleDriveOAuthService();
/// await oauthService.initializeWithOAuth(
///   clientId: 'your-client-id.googleusercontent.com',
///   clientSecret: 'your-client-secret',
/// );
/// 
/// final fileId = await oauthService.pickAndUploadImage();
/// print('Uploaded file ID: $fileId');
/// ```
