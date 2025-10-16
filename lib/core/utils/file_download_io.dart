import 'dart:io';
 
import 'package:path_provider/path_provider.dart';

/// Saves bytes to device local documents directory and returns the saved file path.
Future<String?> downloadFile(String fileName, List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
