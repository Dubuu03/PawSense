import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

class PDFGenerationService {
  // Generate PDF for assessment result
  static Future<Uint8List> generateAssessmentPDF({
    required UserModel user,
    required AssessmentResult assessmentResult,
  }) async {
    // Debug validation
    _debugValidateAssessmentData(assessmentResult);
    
    final pdf = pw.Document();

    // Load logo image (you can add this to assets)
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/img/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found, continuing without logo: $e');
    }

    // Load assessment images (handle both local files and Cloudinary URLs)
    List<pw.ImageProvider> assessmentImages = [];
    for (String imagePath in assessmentResult.imageUrls) {
      try {
        Uint8List? imageBytes;
        
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          // Handle Cloudinary URL
          print('Loading image from URL: $imagePath');
          final httpClient = HttpClient();
          try {
            final response = await httpClient.getUrl(Uri.parse(imagePath));
            final httpResponse = await response.close();
            
            if (httpResponse.statusCode == 200) {
              final List<int> bytes = [];
              await for (var chunk in httpResponse) {
                bytes.addAll(chunk);
              }
              imageBytes = Uint8List.fromList(bytes);
              print('✅ Loaded image from URL: $imagePath');
            } else {
              print('❌ Failed to load image from URL: $imagePath (Status: ${httpResponse.statusCode})');
            }
          } finally {
            httpClient.close();
          }
        } else {
          // Handle local file path
          final file = File(imagePath);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
            print('✅ Loaded local image: $imagePath');
          } else {
            print('❌ Local file not found: $imagePath');
          }
        }
        
        if (imageBytes != null) {
          assessmentImages.add(pw.MemoryImage(imageBytes));
        }
      } catch (e) {
        print('❌ Error loading image $imagePath: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            // Header with logo and PawSense title
            _buildHeader(logoImage),
            pw.SizedBox(height: 30),

            // User profile section
            _buildUserProfileSection(user),
            pw.SizedBox(height: 25),

            // Pet assessment details
            _buildPetAssessmentDetails(assessmentResult),
            pw.SizedBox(height: 25),

            // Assessment results
            _buildAssessmentResults(assessmentResult),
            pw.SizedBox(height: 25),

            // Assessment images section
            if (assessmentImages.isNotEmpty)
              _buildAssessmentImagesSection(assessmentResult, assessmentImages),

            pw.SizedBox(height: 30),

            // Disclaimer
            _buildDisclaimer(),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context);
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to device storage (simplified approach)
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      Directory directory;
      
      if (Platform.isAndroid) {
        // For Android, try to save to external storage first
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a Downloads folder in external storage
          directory = Directory('${externalDir.path}/Downloads');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } else {
          // Fallback to application documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      
      print('PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  // Share PDF (This will open system share dialog where user can choose to save to Downloads)
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  // Alternative method: Save PDF using system's save dialog
  static Future<void> saveWithSystemDialog(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4,
        onLayout: (format) => pdfBytes,
      );
    } catch (e) {
      print('Error opening save dialog: $e');
      rethrow;
    }
  }

  // Print PDF
  static Future<void> printPDF(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }

  // Preview PDF
  static Future<void> previewPDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Error previewing PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildHeader(pw.ImageProvider? logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          if (logoImage != null) ...[
            pw.Image(logoImage, width: 60, height: 60),
            pw.SizedBox(width: 20),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PawSense',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Pet Health Assessment Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blue600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildUserProfileSection(UserModel user) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'User Information',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Profile Name:', user.username),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Email:', user.email),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _buildInfoRow('Date:', formattedDate),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPetAssessmentDetails(AssessmentResult assessmentResult) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pet Assessment Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Pet Name:', assessmentResult.petName),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Type:', assessmentResult.petType),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Breed:', assessmentResult.petBreed),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Age:', '${assessmentResult.petAge} months'),
                    pw.SizedBox(height: 8),
                    _buildInfoRow('Weight:', '${assessmentResult.petWeight} kg'),
                  ],
                ),
              ),
            ],
          ),
          if (assessmentResult.symptoms.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            pw.Text(
              'Observed Symptoms:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: assessmentResult.symptoms.map((symptom) => 
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    symptom,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.blue800),
                  ),
                ),
              ).toList(),
            ),
          ],
          if (assessmentResult.notes.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            _buildInfoRow('Additional Notes:', assessmentResult.notes),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentResults(AssessmentResult assessmentResult) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Results',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          // Show detection results by image
          if (assessmentResult.detectionResults.isNotEmpty) ...[
            pw.Text(
              'Detection Results by Image (Highest Confidence Only):',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 10),
            ...assessmentResult.detectionResults.asMap().entries.map((entry) {
              final imageIndex = entry.key;
              final detectionResult = entry.value;
              
              // Get only the highest confidence detection for this image
              Detection? highestDetection;
              if (detectionResult.detections.isNotEmpty) {
                final sortedDetections = List<Detection>.from(detectionResult.detections);
                sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
                highestDetection = sortedDetections.first;
              }
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Image ${imageIndex + 1} Results:',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (highestDetection != null) ...[
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 4,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(
                                highestDetection.label,
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                            pw.Text(
                              '${(highestDetection.confidence * 100).toStringAsFixed(1)}%',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue200,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'Highest',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.blue800,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      pw.Text(
                        'No detections found in this image',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            // Show overall analysis results if available
            if (assessmentResult.analysisResults.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text(
                'Overall Analysis Summary:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              ...assessmentResult.analysisResults.map((result) => 
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          result.condition,
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Text(
                        '${_validatePercentage(result.percentage).toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ],
          ] else if (assessmentResult.analysisResults.isNotEmpty) ...[
            pw.Text(
              'Analysis Results:',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 10),
            ...assessmentResult.analysisResults.map((result) => 
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        result.condition,
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ),
                    pw.Text(
                      '${_validatePercentage(result.percentage).toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ] else ...[
            pw.Text(
              'No specific conditions detected in the analysis.',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAssessmentImagesSection(AssessmentResult assessmentResult, List<pw.ImageProvider> assessmentImages) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assessment Images',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Images analyzed: ${assessmentImages.length}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 15),
          
          // Display actual images in a grid
          if (assessmentImages.isNotEmpty) ...[
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: assessmentImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(8),
                              topRight: pw.Radius.circular(8),
                            ),
                          ),
                          child: pw.Image(
                            image,
                            fit: pw.BoxFit.cover,
                            width: 200,
                            height: 150,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(8),
                            bottomRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          'Image ${index + 1}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No images available for display',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Important Disclaimer',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'This is a preliminary differential analysis based on visual assessment using AI technology. '
            'The results should not be considered as a final diagnosis. For a confirmed diagnosis and '
            'proper treatment plan, please consult a licensed veterinarian immediately. PawSense is not '
            'responsible for any medical decisions made based on this assessment.',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.red700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Generated by PawSense - Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }

  // Helper method to validate percentage values and prevent infinity/NaN errors
  static double _validatePercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      print('Warning: Invalid percentage value detected: $percentage, using 0.0 instead');
      return 0.0;
    }
    return percentage.clamp(0.0, 100.0);
  }

  // Debug method to validate assessment data before PDF generation
  static void _debugValidateAssessmentData(AssessmentResult assessment) {
    print('=== PDF Generation Debug ===');
    print('Pet Name: ${assessment.petName}');
    print('Analysis Results Count: ${assessment.analysisResults.length}');
    
    for (int i = 0; i < assessment.analysisResults.length; i++) {
      final result = assessment.analysisResults[i];
      print('Result $i: ${result.condition} - ${result.percentage}%');
      if (result.percentage.isNaN || result.percentage.isInfinite) {
        print('WARNING: Invalid percentage detected in result $i');
      }
    }
    
    print('Detection Results Count: ${assessment.detectionResults.length}');
    print('Image URLs Count: ${assessment.imageUrls.length}');
    print('===========================');
  }
}