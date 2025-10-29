// Web-specific implementation for model training downloads
import 'dart:html' as html;
import 'dart:typed_data';

/// Download a file in the browser
void downloadFile(Uint8List data, String filename, String mimeType) {
  final blob = html.Blob([data], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
