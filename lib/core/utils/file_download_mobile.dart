/// Mobile/Desktop implementation for file downloads
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> downloadFile(String fileName, List<int> bytes) async {
  try {
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    print('✅ File saved to: $filePath');
    return filePath;
  } catch (e) {
    print('❌ Error saving file: $e');
    return null;
  }
}
