import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class CloudinaryService {
  // Replace with your Cloudinary cloud name and unsigned upload preset
  static const String _cloudName = 'dpygofris';
  static const String _uploadPreset = 'dht7ahxh';

  /// Upload image from bytes (web)
  Future<String> uploadImageFromBytes(
    Uint8List bytes,
    String fileName, {
    required String folder,
  }) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

    try {
      final sanitizedFileName = _sanitizeFileName(fileName);
      final publicId = '${folder.trim()}/$sanitizedFileName';

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = publicId;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$sanitizedFileName.png',
        ),
      );

      final streamed = await request.send();
      final responseStr = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final Map res = jsonDecode(responseStr) as Map;
        return res['secure_url'] as String;
      } else {
        print('❌ Cloudinary upload failed (${streamed.statusCode}): $responseStr');
        throw Exception('Cloudinary upload failed: ${streamed.statusCode}');
      }
    } catch (e) {
      print('❌ Cloudinary upload exception: $e');
      rethrow;
    }
  }

  /// Upload image from local file path (mobile)
  Future<String> uploadImageFromFile(
    String filePath, {
    required String folder,
  }) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

    try {
      final pathParts = filePath.split('/');
      final baseName = pathParts.isNotEmpty ? pathParts.last.split('.').first : 'file_${DateTime.now().millisecondsSinceEpoch}';
      final sanitizedFileName = _sanitizeFileName(baseName);
      final publicId = '${folder.trim()}/$sanitizedFileName';

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = publicId;

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send();
      final responseStr = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final Map res = jsonDecode(responseStr) as Map;
        return res['secure_url'] as String;
      } else {
        print('❌ Cloudinary file upload failed (${streamed.statusCode}): $responseStr');
        throw Exception('Cloudinary upload failed: ${streamed.statusCode}');
      }
    } catch (e) {
      print('❌ Cloudinary upload exception: $e');
      rethrow;
    }
  }

  String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      int start = uploadIndex + 1;
      if (start < segments.length && segments[start].startsWith('v')) start++;
      final publicIdWithExt = segments.sublist(start).join('/');
      final dot = publicIdWithExt.lastIndexOf('.');
      return dot != -1 ? publicIdWithExt.substring(0, dot) : publicIdWithExt;
    } catch (e) {
      print('❌ Failed to extract public ID: $e');
      return null;
    }
  }
}