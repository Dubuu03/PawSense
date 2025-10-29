// Stub implementation for non-web platforms
import 'dart:typed_data';

/// Stub implementation - not supported on mobile platforms
void downloadFile(Uint8List data, String filename, String mimeType) {
  throw UnsupportedError('File download is only supported on web platform');
}
