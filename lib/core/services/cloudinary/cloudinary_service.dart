import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:typed_data';

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dpygofris',     // Cloudinary cloud name
    'dht7ahxh',      // unsigned upload preset
    cache: false,
  );

  /// Upload image from Uint8List bytes (for Flutter web)
  Future<String> uploadImageFromBytes(
    Uint8List bytes, 
    String fileName, {
    required String folder,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('❌ Cloudinary upload failed: $e');
      throw Exception('Cloudinary upload failed: $e');
    }
  }

  /// Upload image from file path (for mobile platforms)
  Future<String> uploadImageFromFile(
    String filePath, {
    required String folder,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('❌ Cloudinary upload failed: $e');
      throw Exception('Cloudinary upload failed: $e');
    }
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      // Example URL: https://res.cloudinary.com/dpygofris/image/upload/v1234567890/folder/filename.jpg
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index after 'upload' and version (if present)
      int startIndex = pathSegments.indexOf('upload') + 1;
      if (startIndex < pathSegments.length && pathSegments[startIndex].startsWith('v')) {
        startIndex++; // Skip version number
      }
      
      // Join remaining segments and remove file extension
      final publicIdWithExtension = pathSegments.sublist(startIndex).join('/');
      final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
      
      return lastDotIndex != -1 
          ? publicIdWithExtension.substring(0, lastDotIndex)
          : publicIdWithExtension;
    } catch (e) {
      print('❌ Failed to extract public ID: $e');
      return null;
    }
  }

  /// Note: cloudinary_public package doesn't support deletion
  /// For deletion, you would need to use Cloudinary Admin API
  /// or handle it server-side
}