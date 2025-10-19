import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:http/http.dart' as http;

// Conditional imports for platform compatibility
import 'dart:io' if (dart.library.js) 'io_stub.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) 'io_stub.dart';

class PDFGenerationService {
  // Generate PDF for assessment result
  static Future<Uint8List> generateAssessmentPDF({
    required UserModel user,
    required AssessmentResult assessmentResult,
    Map<String, dynamic>? clinicEvaluation, // Optional clinic evaluation data
  }) async {
    // Debug validation
    _debugValidateAssessmentData(assessmentResult);
    
    final pdf = pw.Document();

    // Load Unicode-compatible fonts
    pw.Font? robotoFont;
    pw.Font? robotoBoldFont;
    pw.ThemeData theme = pw.ThemeData.base(); // Default theme
    
    try {
      // Try to load fonts from the system or use printing package built-in fonts
      robotoFont = await PdfGoogleFonts.notoSansRegular();
      robotoBoldFont = await PdfGoogleFonts.notoSansBold();
      
      // Set theme with Unicode fonts
      theme = pw.ThemeData.withFont(
        base: robotoFont,
        bold: robotoBoldFont,
      );
      print('✅ Unicode fonts loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load Unicode fonts, using default fonts: $e');
      // Keep the default theme if font loading fails
    }

    // Load assessment images (handle both local files and Cloudinary URLs)
    List<pw.ImageProvider> assessmentImages = [];
    for (String imagePath in assessmentResult.imageUrls) {
      try {
        Uint8List? imageBytes;
        
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          // Handle Cloudinary URL with web-compatible HTTP client
          print('Loading image from URL: $imagePath');
          try {
            final response = await http.get(Uri.parse(imagePath));
            
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
              print('✅ Loaded image from URL: $imagePath');
            } else {
              print('❌ Failed to load image from URL: $imagePath (Status: ${response.statusCode})');
            }
          } catch (e) {
            print('❌ HTTP error loading image from URL: $imagePath - $e');
          }
        } else if (!kIsWeb) {
          // Handle local file path (only for non-web platforms)
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              imageBytes = await file.readAsBytes();
              print('✅ Loaded local image: $imagePath');
            } else {
              print('❌ Local file not found: $imagePath');
            }
          } catch (e) {
            print('❌ Error loading local file: $imagePath - $e');
          }
        } else {
          print('❌ Local file paths not supported on web platform: $imagePath');
        }
        
        if (imageBytes != null) {
          assessmentImages.add(pw.MemoryImage(imageBytes));
        }
      } catch (e) {
        print('❌ Error loading image $imagePath: $e');
      }
    }
    // Try loading the PawSense logo from assets (optional)
    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/img/pawsense_logo.png');
      logoBytes = data.buffer.asUint8List();
      print('✅ Loaded PawSense logo for PDF header');
    } catch (e) {
      // Fallback: try legacy logo.png
      try {
        final data = await rootBundle.load('assets/img/logo.png');
        logoBytes = data.buffer.asUint8List();
        print('✅ Loaded fallback logo for PDF header');
      } catch (e) {
        print('⚠️ No logo asset found for PDF header: $e');
        logoBytes = null;
      }
    }

    // Capture generation timestamp for footer
    final DateTime _generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        build: (pw.Context context) {
          return [
            // Header with PawSense title and optional logo
            _buildHeader(logoBytes),
            pw.SizedBox(height: 20),

            // User profile section
            _buildUserProfileSection(user),
            pw.SizedBox(height: 15),

            // Pet assessment details
            _buildPetAssessmentDetails(assessmentResult),
            pw.SizedBox(height: 15),

            // Assessment results with images and bounding boxes (combined section)
            if (assessmentImages.isNotEmpty) ...[
              _buildAssessmentImagesSection(assessmentResult, assessmentImages),
              pw.SizedBox(height: 15),
            ],

            // Clinic Evaluation section (if provided) - MOVED TO LAST
            if (clinicEvaluation != null && _hasClinicEvaluationData(clinicEvaluation))
              ...[
                _buildClinicEvaluationSection(clinicEvaluation),
                pw.SizedBox(height: 20),
              ],

            // Disclaimer
            _buildDisclaimer(),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(context, _generatedAt);
        },
      ),
    );

    return pdf.save();
  }

  // Save PDF to device storage (platform-aware approach)
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      // For web, use the system save dialog via printing package
      try {
        await Printing.layoutPdf(
          name: fileName,
          format: PdfPageFormat.a4,
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
        return 'PDF saved via browser';
      } catch (e) {
        print('Error saving PDF on web: $e');
        rethrow;
      }
    } else {
      // For mobile platforms only
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
        print('Error saving PDF on mobile: $e');
        rethrow;
      }
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

  static pw.Widget _buildHeader(Uint8List? logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null) ...[
            pw.Container(
              width: 72,
              height: 72,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
              ),
            ),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PawSense',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Pet Health Assessment Report',
                  style: pw.TextStyle(
                    fontSize: 13,
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

  static pw.Widget _buildAssessmentImagesSection(AssessmentResult assessmentResult, List<pw.ImageProvider> assessmentImages) {
    // Helper function to remove duplicate detections using IoU
    List<Detection> _removeDuplicateDetections(List<Detection> detections) {
      if (detections.isEmpty) return detections;
      
      final List<Detection> uniqueDetections = [];
      const double IOU_THRESHOLD = 0.5;
      
      // Sort by confidence descending
      final sortedDetections = List<Detection>.from(detections)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      
      for (final detection in sortedDetections) {
        bool isDuplicate = false;
        
        for (final existing in uniqueDetections) {
          // Check if same disease name
          if (detection.label == existing.label) {
            // Check if bounding boxes overlap significantly
            if (detection.boundingBox != null && 
                existing.boundingBox != null &&
                detection.boundingBox!.length >= 4 &&
                existing.boundingBox!.length >= 4) {
              final iou = _calculateIOU(
                detection.boundingBox!,
                existing.boundingBox!,
              );
              
              if (iou > IOU_THRESHOLD) {
                isDuplicate = true;
                break;
              }
            }
          }
        }
        
        if (!isDuplicate) {
          uniqueDetections.add(detection);
        }
      }
      
      return uniqueDetections;
    }
    
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
          pw.Text(
            'Images analyzed: ${assessmentImages.length}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 15),
          
          // Display images with bounding box information
          if (assessmentImages.isNotEmpty) ...[
            ...assessmentImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              
              // Get detection results for this image
              final detectionResult = index < assessmentResult.detectionResults.length 
                  ? assessmentResult.detectionResults[index] 
                  : null;
              
              // Remove duplicates before displaying
              final sortedDetections = detectionResult != null 
                  ? _removeDuplicateDetections(detectionResult.detections)
                  : <Detection>[];
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header with Image number and detection count
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue100,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Image ${index + 1}',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          if (sortedDetections.isNotEmpty)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue700,
                                borderRadius: pw.BorderRadius.circular(10),
                              ),
                              child: pw.Text(
                                '${sortedDetections.length} Detection${sortedDetections.length > 1 ? 's' : ''}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Image and detections side by side
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Image - 65% width
                          pw.Expanded(
                            flex: 65,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 5,
                                verticalRadius: 5,
                                child: pw.Image(
                                  image,
                                  fit: pw.BoxFit.contain,
                                  height: 180,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          // Detections list - 35% width
                          pw.Expanded(
                            flex: 35,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (sortedDetections.isNotEmpty) ...[
                                  pw.Text(
                                    'Detected:',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  ...sortedDetections.asMap().entries.map((detEntry) {
                                    final detIndex = detEntry.key;
                                    final detection = detEntry.value;
                                    final isHighest = detIndex == 0;
                                    
                                    return pw.Container(
                                      margin: const pw.EdgeInsets.only(bottom: 5),
                                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                      decoration: pw.BoxDecoration(
                                        color: isHighest ? PdfColors.blue50 : PdfColors.grey100,
                                        borderRadius: pw.BorderRadius.circular(4),
                                        border: pw.Border.all(
                                          color: isHighest ? PdfColors.blue300 : PdfColors.grey300,
                                          width: 1,
                                        ),
                                      ),
                                      child: pw.Row(
                                        children: [
                                          pw.Container(
                                            width: 6,
                                            height: 6,
                                            decoration: pw.BoxDecoration(
                                              color: isHighest ? PdfColors.blue600 : PdfColors.grey500,
                                              shape: pw.BoxShape.circle,
                                            ),
                                          ),
                                          pw.SizedBox(width: 6),
                                          pw.Expanded(
                                            child: pw.Text(
                                              detection.label,
                                              style: pw.TextStyle(
                                                fontSize: 9,
                                                fontWeight: isHighest ? pw.FontWeight.bold : pw.FontWeight.normal,
                                                color: PdfColors.grey900,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(width: 4),
                                          pw.Text(
                                            '${(detection.confidence * 100).toStringAsFixed(1)}%',
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              fontWeight: pw.FontWeight.bold,
                                              color: isHighest ? PdfColors.blue700 : PdfColors.grey700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ] else ...[
                                  pw.Text(
                                    'No detections',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey600,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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

  // Check if clinic evaluation has any data
  static bool _hasClinicEvaluationData(Map<String, dynamic> clinicEvaluation) {
    final diagnosis = clinicEvaluation['diagnosis'] as String?;
    final treatment = clinicEvaluation['treatment'] as String?;
    final prescription = clinicEvaluation['prescription'] as String?;
    final clinicNotes = clinicEvaluation['clinicNotes'] as String?;
    
    return (diagnosis != null && diagnosis.trim().isNotEmpty) ||
           (treatment != null && treatment.trim().isNotEmpty) ||
           (prescription != null && prescription.trim().isNotEmpty) ||
           (clinicNotes != null && clinicNotes.trim().isNotEmpty);
  }

  // Build clinic evaluation section for PDF
  static pw.Widget _buildClinicEvaluationSection(Map<String, dynamic> clinicEvaluation) {
    final diagnosis = clinicEvaluation['diagnosis'] as String?;
    final treatment = clinicEvaluation['treatment'] as String?;
    final prescription = clinicEvaluation['prescription'] as String?;
    final clinicNotes = clinicEvaluation['clinicNotes'] as String?;
    final completedAt = clinicEvaluation['completedAt'] as DateTime?;
    final isFollowUp = clinicEvaluation['isFollowUp'] as bool? ?? false;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green300, width: 1.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isFollowUp ? 'Previous Visit - Clinic Evaluation' : 'Clinic Evaluation',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              if (completedAt != null)
                pw.SizedBox(height: 4),
              if (completedAt != null)
                pw.Text(
                  'Completed: ${_formatDateTime(completedAt)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.green700,
                  ),
                ),
            ],
          ),
          
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.green300, thickness: 0.6),
          pw.SizedBox(height: 10),
          
          // Evaluation details
          if (diagnosis != null && diagnosis.trim().isNotEmpty) ...[
            _buildEvaluationRow('Diagnosis', diagnosis),
            pw.SizedBox(height: 10),
          ],
          
          if (treatment != null && treatment.trim().isNotEmpty) ...[
            _buildEvaluationRow('Treatment', treatment),
            pw.SizedBox(height: 10),
          ],
          
          if (prescription != null && prescription.trim().isNotEmpty) ...[
            _buildEvaluationRow('Prescription', prescription),
            pw.SizedBox(height: 10),
          ],
          
          if (clinicNotes != null && clinicNotes.trim().isNotEmpty) ...[
            _buildEvaluationRow('Clinic Notes', clinicNotes),
          ],
        ],
      ),
    );
  }

  // Build evaluation row for clinic evaluation section
  static pw.Widget _buildEvaluationRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
            lineSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // Format DateTime for display
  static String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  static pw.Widget _buildFooter(pw.Context context, DateTime generatedAt) {
    final generatedStr = '${generatedAt.day.toString().padLeft(2, '0')}/${generatedAt.month.toString().padLeft(2, '0')}/${generatedAt.year} '
        '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Generated: $generatedStr',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            ' | ',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            'Generated by PawSense - Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
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

  // Calculate Intersection over Union (IoU) for bounding box overlap detection
  static double _calculateIOU(List<double> box1, List<double> box2) {
    try {
      final x1_1 = box1[0];
      final y1_1 = box1[1];
      final x2_1 = box1[2];
      final y2_1 = box1[3];
      
      final x1_2 = box2[0];
      final y1_2 = box2[1];
      final x2_2 = box2[2];
      final y2_2 = box2[3];
      
      // Calculate intersection area
      final xLeft = x1_1 > x1_2 ? x1_1 : x1_2;
      final yTop = y1_1 > y1_2 ? y1_1 : y1_2;
      final xRight = x2_1 < x2_2 ? x2_1 : x2_2;
      final yBottom = y2_1 < y2_2 ? y2_1 : y2_2;
      
      if (xRight < xLeft || yBottom < yTop) {
        return 0.0; // No intersection
      }
      
      final intersectionArea = (xRight - xLeft) * (yBottom - yTop);
      
      // Calculate union area
      final box1Area = (x2_1 - x1_1) * (y2_1 - y1_1);
      final box2Area = (x2_2 - x1_2) * (y2_2 - y1_2);
      final unionArea = box1Area + box2Area - intersectionArea;
      
      if (unionArea <= 0) {
        return 0.0;
      }
      
      return intersectionArea / unionArea;
    } catch (e) {
      print('Error calculating IOU: $e');
      return 0.0;
    }
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