import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';

class AssessmentStepTwo extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AssessmentStepTwo({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<AssessmentStepTwo> createState() => _AssessmentStepTwoState();
}

class _AssessmentStepTwoState extends State<AssessmentStepTwo> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _showPreparationTips = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing photos if available
    if (widget.assessmentData['photos'] != null) {
      final photoList = widget.assessmentData['photos'] as List;
      _selectedImages = photoList.cast<XFile>();
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
        widget.onDataUpdate('photos', _selectedImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        widget.onDataUpdate('photos', _selectedImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to upload photos: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onDataUpdate('photos', _selectedImages);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take or Upload Photos',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'Capture multiple photos for better differential analysis.',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                
                // Pet Type Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingMedium,
                    vertical: kSpacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: kSpacingXSmall),
                      Text(
                        'Scanning: ${widget.assessmentData['selectedPetType'] ?? 'Dog'}',
                        style: kMobileTextStyleServiceTitle.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Photo Capture Buttons
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Take Photo',
                    icon: Icons.camera_alt,
                    onPressed: _isLoading ? null : _takePhoto,
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _uploadPhotos,
                    icon: Icon(Icons.upload),
                    label: Text('Upload Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kButtonRadius),
                      ),
                      minimumSize: Size(double.infinity, kButtonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Photos Section
          if (_selectedImages.isNotEmpty) ...[
            Container(
              width: double.infinity, // Full width
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photos (${_selectedImages.length})',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpacingMedium),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_selectedImages.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _selectedImages.length - 1 ? kSpacingSmall : 0,
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kBorderRadius),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(kBorderRadius),
                                  child: Image.network(
                                    _selectedImages[index].path,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.background,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              color: AppColors.textSecondary,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${index + 1}',
                                              style: kMobileTextStyleLegend.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: AppColors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpacingMedium),
          ],
          
          // Preparation Tips (Collapsible)
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showPreparationTips = !_showPreparationTips),
                  child: Container(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    child: Row(
                      children: [
                        Text(
                          'Preparation Tips',
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                      
                        Icon(
                          _showPreparationTips ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showPreparationTips) ...[
                  const Divider(height: 1, color: AppColors.primary),
                  Padding(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    child: Column(
                      children: [
                        _buildTip(Icons.wb_sunny, 'Use natural light'),
                        _buildTip(Icons.straighten, 'Hold 10-15 cm away'),
                        _buildTip(Icons.pets, 'Keep pet calm'),
                        _buildTip(Icons.cleaning_services, 'Clean affected area'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Text(
              'This is a preliminary differential analysis. For a confirmed diagnosis, please consult a licensed veterinarian.',
              style: kMobileTextStyleLegend.copyWith(
                color: AppColors.info,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingSmall),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: kSpacingSmall),
          Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
