import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:image_picker/image_picker.dart';

/// Google Drive upload response model
class GoogleDriveUploadResult {
  final String fileId;
  final String fileName;
  final String webViewLink;
  final String webContentLink;
  final String? thumbnailLink;
  final DateTime createdTime;

  const GoogleDriveUploadResult({
    required this.fileId,
    required this.fileName,
    required this.webViewLink,
    required this.webContentLink,
    this.thumbnailLink,
    required this.createdTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'webViewLink': webViewLink,
      'webContentLink': webContentLink,
      'thumbnailLink': thumbnailLink,
      'createdTime': createdTime.toIso8601String(),
    };
  }

  factory GoogleDriveUploadResult.fromMap(Map<String, dynamic> map) {
    return GoogleDriveUploadResult(
      fileId: map['fileId'] ?? '',
      fileName: map['fileName'] ?? '',
      webViewLink: map['webViewLink'] ?? '',
      webContentLink: map['webContentLink'] ?? '',
      thumbnailLink: map['thumbnailLink'],
      createdTime: DateTime.parse(map['createdTime']),
    );
  }
}

/// Service for handling Google Drive operations using Service Account authentication
class GoogleDriveService {
  static const String _folderId = '1_bvOevbYnmHnEgy7wzCT8eoL9EWVLqjN';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  drive.DriveApi? _driveApi;
  AutoRefreshingAuthClient? _authClient;
  final ImagePicker _imagePicker = ImagePicker();
  String? _sharedDriveId; // Will be determined from folder

  /// Initialize the Google Drive API with Service Account authentication
  Future<void> _initializeApi() async {
    try {
      if (_driveApi != null) return; // Already initialized

      // Load service account credentials
      final credentialsJson = await rootBundle.loadString(
        'assets/google_service_account.json',
      );
      
      final credentials = json.decode(credentialsJson);
      
      // Create service account credentials
      final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
      
      // Create authenticated client
      _authClient = await clientViaServiceAccount(
        accountCredentials,
        _scopes,
      );
      
      // Initialize Drive API
      _driveApi = drive.DriveApi(_authClient!);
      
      // Detect if folder is in a shared drive
      await _detectSharedDrive();
      
      print('Google Drive API initialized successfully');
    } catch (e) {
      print('Error initializing Google Drive API: $e');
      throw Exception('Failed to initialize Google Drive API: $e');
    }
  }

  /// Detect if the target folder is in a shared drive
  Future<void> _detectSharedDrive() async {
    try {
      // Get folder information
      final folder = await _driveApi!.files.get(
        _folderId,
        supportsAllDrives: true,
        $fields: 'id,name,parents,driveId',
      ) as drive.File;
      
      if (folder.driveId != null) {
        _sharedDriveId = folder.driveId;
        print('Detected shared drive: ${folder.driveId}');
        print('Using shared drive mode for uploads');
      } else {
        print('Using regular Google Drive folder');
        print('Warning: Service Accounts may have storage quota issues with regular folders');
      }
    } catch (e) {
      print('Error detecting shared drive: $e');
      // Continue without shared drive support
    }
  }

  /// Pick an image from the device
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return pickedFile;
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload an image file to Google Drive
  Future<GoogleDriveUploadResult> uploadImage({
    required XFile imageFile,
    required String fileName,
    String? description,
    Map<String, String>? properties,
  }) async {
    await _initializeApi();
    
    try {
      // Read file bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();
      
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId]
        ..description = description
        ..properties = properties;

      // Create media upload
      final media = drive.Media(
        Stream.fromIterable([fileBytes]),
        fileBytes.length,
        contentType: _getMimeType(imageFile.name),
      );

      // Upload file
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        supportsAllDrives: true,
        $fields: 'id,name,webViewLink,webContentLink,thumbnailLink,createdTime',
      );

      // Make file publicly viewable (optional - adjust permissions as needed)
      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        uploadedFile.id!,
        supportsAllDrives: true,
      );

      return GoogleDriveUploadResult(
        fileId: uploadedFile.id!,
        fileName: uploadedFile.name!,
        webViewLink: uploadedFile.webViewLink!,
        webContentLink: uploadedFile.webContentLink!,
        thumbnailLink: uploadedFile.thumbnailLink,
        createdTime: uploadedFile.createdTime!,
      );
    } catch (e) {
      print('Error uploading image to Google Drive: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image from file bytes (for web platforms)
  Future<GoogleDriveUploadResult> uploadImageFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    String? description,
    Map<String, String>? properties,
  }) async {
    await _initializeApi();
    
    try {
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId]
        ..description = description
        ..properties = properties;

      // Create media upload
      final media = drive.Media(
        Stream.fromIterable([fileBytes]),
        fileBytes.length,
        contentType: _getMimeType(fileName),
      );

      // Upload file
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        supportsAllDrives: true,
        $fields: 'id,name,webViewLink,webContentLink,thumbnailLink,createdTime',
      );

      // Make file publicly viewable
      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        uploadedFile.id!,
        supportsAllDrives: true,
      );

      return GoogleDriveUploadResult(
        fileId: uploadedFile.id!,
        fileName: uploadedFile.name!,
        webViewLink: uploadedFile.webViewLink!,
        webContentLink: uploadedFile.webContentLink!,
        thumbnailLink: uploadedFile.thumbnailLink,
        createdTime: uploadedFile.createdTime!,
      );
    } catch (e) {
      print('Error uploading image bytes to Google Drive: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete a file from Google Drive
  Future<void> deleteFile(String fileId) async {
    await _initializeApi();
    
    try {
      await _driveApi!.files.delete(
        fileId,
        supportsAllDrives: true,
      );
      print('File deleted successfully: $fileId');
    } catch (e) {
      print('Error deleting file from Google Drive: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get file information from Google Drive
  Future<drive.File?> getFileInfo(String fileId) async {
    await _initializeApi();
    
    try {
      return await _driveApi!.files.get(
        fileId,
        supportsAllDrives: true,
        $fields: 'id,name,webViewLink,webContentLink,thumbnailLink,createdTime,size',
      ) as drive.File;
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  /// Generate a shareable link for a file
  String generateShareableLink(String fileId) {
    return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
  }

  /// Check if the service is configured to use a shared drive
  bool get isUsingSharedDrive => _sharedDriveId != null;

  /// Get the shared drive ID if available
  String? get sharedDriveId => _sharedDriveId;

  /// Get MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Dispose resources
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
  }
}

/// Singleton instance of GoogleDriveService
final GoogleDriveService googleDriveService = GoogleDriveService();
