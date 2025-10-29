# Two-Step Appointment Completion - Implementation Guide

## Overview
This guide explains how to restructure the appointment completion modal into a two-step process to better handle multiple AI assessment images and provide dedicated training data validation for each image.

## Problem Statement

### Current Issues:
1. **Single Image Assumption**: Current modal assumes only one assessment image
2. **Mixed Validation**: Clinic evaluation and training data validation are combined
3. **No Per-Image Validation**: Can't validate each assessment image separately
4. **Confusing UX**: Users see everything at once, making the form overwhelming

### Solution: Two-Step Modal

**Step 1: Clinic Evaluation**
- Doctor completes appointment details (diagnosis, treatment, prescription)
- Sets follow-up requirements
- Reviews AI predictions (without training data commitment yet)

**Step 2: Training Data Validation** (Per Image)
- Review each assessment image individually
- Validate or correct AI predictions for each image
- Provide feedback specific to each image
- Decide if each image should be used for training

## Architecture

### New Data Structure

```dart
/// Class to track training data validation for each image
class ImageTrainingValidation {
  final String imageUrl;
  final String imageType; // 'original', 'annotated', 'detection'
  bool? isCorrect;
  String? correctDisease;
  String feedback;
  List<Map<String, dynamic>> aiPredictions;
  Map<String, bool> predictionValidation;

  ImageTrainingValidation({
    required this.imageUrl,
    required this.imageType,
    this.isCorrect,
    this.correctDisease,
    this.feedback = '',
    required this.aiPredictions,
    required this.predictionValidation,
  });
}
```

### State Management Updates

```dart
class _AppointmentCompletionModalState extends State<AppointmentCompletionModal> {
  // ... existing fields ...
  
  // NEW: Multi-image training data validation
  List<ImageTrainingValidation> _imageValidations = [];
  int _currentImageIndex = 0;
  
  // NEW: Two-step modal state
  int _currentStep = 1; // 1 = Clinic Evaluation, 2 = Training Data Validation
}
```

### Step Flow

```
[Start]
   ↓
[Step 1: Clinic Evaluation]
   - Doctor enters diagnosis
   - Doctor enters treatment
   - Doctor enters prescription
   - Doctor sets follow-up if needed
   ↓
[Click "Next: Validate Training Data"]
   ↓
[Step 2: Training Data Validation]
   - For each assessment image:
     1. Display image
     2. Show AI predictions
     3. Validate correctness
     4. Select correct disease if wrong
     5. Provide feedback
     6. Navigate to next image →
   ↓
[All images validated]
   ↓
[Click "Complete Appointment"]
   ↓
[Save to Firestore]
   ↓
[End]
```

## Implementation Steps

### Step 1: Update Header with Progress Indicator

```dart
Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.task_alt, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStep == 1 
                        ? 'Step 1: Complete Appointment' 
                        : 'Step 2: Validate Training Data',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentStep == 2 && _imageValidations.isNotEmpty)
                    Text(
                      'Image ${_currentImageIndex + 1} of ${_imageValidations.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Step Progress Indicator
        Row(
          children: [
            _buildStepIndicator(1, 'Clinic Evaluation'),
            Expanded(
              child: Container(
                height: 2,
                color: _currentStep >= 2 ? Colors.white : Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(2, 'Training Data'),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStepIndicator(int step, String label) {
  final isActive = _currentStep == step;
  final isCompleted = _currentStep > step;
  
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted || isActive ? Colors.white : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: AppColors.primary, size: 18)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: isActive ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: isActive || isCompleted ? Colors.white : Colors.white.withOpacity(0.7),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    ],
  );
}
```

### Step 2: Split Content into Two Views

```dart
Widget build(BuildContext context) {
  return Dialog(
    child: Container(
      width: 700,
      constraints: const BoxConstraints(maxHeight: 800),
      child: Column(
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentStep == 1
                      ? _buildStep1ClinicEvaluation()
                      : _buildStep2TrainingDataValidation(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    ),
  );
}
```

### Step 3: Build Step 1 (Clinic Evaluation)

```dart
Widget _buildStep1ClinicEvaluation() {
  return Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error Banner
        if (_errorMessage != null) _buildErrorBanner(),
        
        // Section Title
        const Text(
          'Clinic Evaluation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Diagnosis Field
        _buildTextField(
          label: 'Diagnosis',
          controller: _diagnosisController,
          hint: 'Enter the final diagnosis',
          validator: (value) => value?.trim().isEmpty ?? true
              ? 'Please enter a diagnosis'
              : null,
        ),
        const SizedBox(height: 16),
        
        // Treatment Field
        _buildTextField(
          label: 'Treatment Provided',
          controller: _treatmentController,
          hint: 'Describe the treatment',
          validator: (value) => value?.trim().isEmpty ?? true
              ? 'Please describe the treatment'
              : null,
        ),
        const SizedBox(height: 16),
        
        // Prescription Field
        _buildTextField(
          label: 'Prescription',
          controller: _prescriptionController,
          hint: 'Medications and dosage',
          required: false,
        ),
        const SizedBox(height: 16),
        
        // Additional Notes Field
        _buildTextField(
          label: 'Additional Notes',
          controller: _clinicNotesController,
          hint: 'Other observations',
          required: false,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        
        // Follow-up Section
        _buildFollowUpSection(),
        
        // AI Predictions Summary (Read-only preview)
        if (_hasAIAssessment) ...[
          const SizedBox(height: 20),
          _buildAIPredictionsSummary(),
        ],
      ],
    ),
  );
}

Widget _buildAIPredictionsSummary() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.info.withOpacity(0.05),
      border: Border.all(color: AppColors.info.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'AI Predictions Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._aiPredictions.map((pred) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pred['condition'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${(pred['percentage'] as num).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 8),
        const Text(
          'You will validate these predictions in the next step.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
```

### Step 4: Build Step 2 (Training Data Validation)

```dart
Widget _buildStep2TrainingDataValidation() {
  if (_imageValidations.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No assessment images available for validation',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  final currentValidation = _imageValidations[_currentImageIndex];
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Error Banner
      if (_errorMessage != null) _buildErrorBanner(),
      
      // Image Counter and Navigation
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Image ${_currentImageIndex + 1} of ${_imageValidations.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentImageIndex > 0
                    ? () => setState(() => _currentImageIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Previous image',
              ),
              IconButton(
                onPressed: _currentImageIndex < _imageValidations.length - 1
                    ? () => setState(() => _currentImageIndex++)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Next image',
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Image Display
      _buildImageDisplay(currentValidation.imageUrl),
      const SizedBox(height: 20),
      
      // AI Predictions Validation
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.05),
          border: Border.all(color: AppColors.info.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Predictions for this Image',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Individual prediction checkboxes
            ...currentValidation.aiPredictions.asMap().entries.map((entry) {
              final index = entry.key;
              final pred = entry.value;
              return CheckboxListTile(
                value: currentValidation.predictionValidation[index.toString()] ?? false,
                onChanged: (value) {
                  setState(() {
                    currentValidation.predictionValidation[index.toString()] = value ?? false;
                  });
                },
                title: Text(pred['condition']),
                subtitle: Text('Confidence: ${(pred['percentage'] as num).toStringAsFixed(1)}%'),
                dense: true,
              );
            }).toList(),
            
            const Divider(),
            
            // Overall Assessment
            const Text(
              'Overall Assessment:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Correct'),
                    value: true,
                    groupValue: currentValidation.isCorrect,
                    onChanged: (value) {
                      setState(() {
                        currentValidation.isCorrect = value;
                        if (value == true) {
                          currentValidation.correctDisease = null;
                        }
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Incorrect'),
                    value: false,
                    groupValue: currentValidation.isCorrect,
                    onChanged: (value) {
                      setState(() {
                        currentValidation.isCorrect = value;
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
            
            // Correct Disease Selection (if incorrect)
            if (currentValidation.isCorrect == false) ...[
              const SizedBox(height: 12),
              _buildDiseaseDropdown(currentValidation),
            ],
            
            // Feedback
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Feedback (Optional)',
                hintText: 'Additional comments about this image',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                currentValidation.feedback = value;
              },
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildImageDisplay(String imageUrl) {
  return GestureDetector(
    onTap: () => _showImageZoomDialog(imageUrl),
    child: Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      Text('Failed to load image'),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Step 5: Update Footer Based on Current Step

```dart
Widget _buildFooter() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button (only in step 2)
        if (_currentStep == 2)
          TextButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _currentStep = 1;
                      _currentImageIndex = 0;
                    });
                  },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Clinic Evaluation'),
          )
        else
          const SizedBox(),
        
        // Right side buttons
        Row(
          children: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            
            if (_currentStep == 1)
              // Next button
              ElevatedButton.icon(
                onPressed: _validateStep1AndProceed,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Validate Training Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              // Complete button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCompletion,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Saving...' : 'Complete Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

void _validateStep1AndProceed() {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  // Validate follow-up details if needed
  if (_needsFollowUp) {
    if (_followUpDate == null) {
      setState(() => _errorMessage = 'Please select a follow-up date');
      return;
    }
    if (_followUpTime == null) {
      setState(() => _errorMessage = 'Please select a follow-up time');
      return;
    }
  }
  
  // Clear error and proceed to step 2
  setState(() {
    _errorMessage = null;
    _currentStep = 2;
  });
}
```

### Step 6: Update Save Method to Handle Multiple Images

```dart
Future<void> _saveCompletion() async {
  // Validate all images have been assessed
  for (var i = 0; i < _imageValidations.length; i++) {
    final validation = _imageValidations[i];
    if (validation.isCorrect == null) {
      setState(() {
        _errorMessage = 'Please validate all images (Image ${i + 1} is missing validation)';
        _currentImageIndex = i;
      });
      return;
    }
    
    if (validation.isCorrect == false && 
        (validation.correctDisease == null || validation.correctDisease!.isEmpty)) {
      setState(() {
        _errorMessage = 'Please select the correct disease for Image ${i + 1}';
        _currentImageIndex = i;
      });
      return;
    }
  }
  
  setState(() => _isSaving = true);
  
  try {
    final batch = FirebaseFirestore.instance.batch();
    
    // 1. Update appointment (same as before)
    // ...
    
    // 2. Store validation data for EACH image
    for (var validation in _imageValidations) {
      final validationRef = FirebaseFirestore.instance
          .collection('model_training_data')
          .doc();
      
      final cleanedCorrectDisease = validation.isCorrect == false && validation.correctDisease != null
          ? _cleanDiseaseName(validation.correctDisease!)
          : null;
      
      batch.set(validationRef, {
        'appointmentId': widget.appointment.id,
        'assessmentResultId': widget.appointment.assessmentResultId,
        'petType': widget.appointment.pet.type,
        'petBreed': widget.appointment.pet.breed,
        'clinicDiagnosis': _diagnosisController.text.trim(),
        'overallCorrect': validation.isCorrect,
        'feedback': validation.feedback,
        'correctDisease': cleanedCorrectDisease,
        'validatedAt': Timestamp.now(),
        'validatedBy': widget.appointment.clinicId,
        'canUseForTraining': validation.isCorrect == true,
        'canUseForRetraining': validation.isCorrect == false && cleanedCorrectDisease != null,
        'imageData': {
          'originalImageUrl': validation.imageUrl,
          'imageType': validation.imageType,
          'diseaseLabel': cleanedCorrectDisease ?? _diagnosisController.text.trim(),
          'petType': widget.appointment.pet.type,
          'correctionType': validation.isCorrect == false ? 'manual_correction' : 'validation',
          'uniqueFilename': _generateUniqueFilename(
            diseaseName: cleanedCorrectDisease ?? _diagnosisController.text.trim()
          ),
        },
        'hasImageAssessment': true,
        'trainingDataType': 'image_assessment',
        'aiPredictions': validation.aiPredictions.asMap().entries.map((entry) {
          return {
            'condition': entry.value['condition'],
            'percentage': entry.value['percentage'],
            'colorHex': entry.value['colorHex'],
            'isCorrect': validation.predictionValidation[entry.key.toString()] ?? false,
          };
        }).toList(),
      });
    }
    
    await batch.commit();
    
    if (!mounted) return;
    
    Navigator.of(context).pop();
    widget.onCompleted();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Appointment completed! ${_imageValidations.length} images validated for training.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  } catch (e) {
    print('Error saving completion: $e');
    
    if (!mounted) return;
    
    setState(() {
      _errorMessage = 'Failed to complete appointment: ${e.toString()}';
      _isSaving = false;
    });
  }
}
```

## Benefits

### For Clinics:
✅ **Clearer workflow**: Separate medical evaluation from AI training feedback
✅ **Per-image validation**: Can assess each image individually
✅ **Better organization**: Step-by-step process is less overwhelming
✅ **Image navigation**: Easy to review multiple images with prev/next buttons

### For AI Training:
✅ **Higher quality data**: Each image validated individually
✅ **Better metadata**: Know which specific images are correct/incorrect
✅ **Granular feedback**: Per-image comments improve model training
✅ **Accurate labeling**: Correct disease selected for each image separately

### For Users:
✅ **Progress visibility**: Clear step indicator shows where they are
✅ **Validation required**: Can't skip validation accidentally
✅ **Better UX**: Not overwhelming with all fields at once
✅ **Easy navigation**: Previous/Next for multiple images

## Database Impact

### Before (Single Entry):
```javascript
model_training_data/
  └── {docId}
      ├── imageData: {
      │     originalImageUrl: "image1.jpg",
      │     annotatedImageUrl: "annotated1.jpg"
      │   }
      └── overallCorrect: true
```

### After (Multiple Entries):
```javascript
model_training_data/
  ├── {docId1}
  │   ├── imageData: {
  │   │     originalImageUrl: "image1.jpg",
  │   │     imageType: "original"
  │   │   }
  │   └── overallCorrect: true
  ├── {docId2}
  │   ├── imageData: {
  │   │     originalImageUrl: "image2.jpg",
  │   │     imageType: "detection"
  │   │   }
  │   └── overallCorrect: false
  │   └── correctDisease: "Ringworm"
  └── {docId3}
      ├── imageData: {
      │     originalImageUrl: "image3.jpg",
      │     imageType: "annotated"
      │   }
      └── overallCorrect: true
```

**Benefit**: Each image has its own training data entry, allowing for more granular AI model improvement.

## Testing Checklist

- [ ] Step 1 form validation works correctly
- [ ] Can't proceed to Step 2 without completing Step 1
- [ ] Step progress indicator updates correctly
- [ ] Can navigate between images in Step 2
- [ ] Previous/Next buttons disable at boundaries
- [ ] Image counter shows correct numbers
- [ ] Can go back to Step 1 and edit
- [ ] All images must be validated before saving
- [ ] Error messages show for incomplete validations
- [ ] Multiple training data entries created correctly
- [ ] Export groups images properly by disease
- [ ] UI responsive on different screen sizes

## Migration Notes

### Existing Appointments:
- Old appointments with single validation will continue to work
- New appointments will create multiple training data entries
- Both formats supported in model training export

### Gradual Rollout:
1. Deploy new modal code
2. Monitor for issues with Step 1
3. Enable Step 2 for clinics with AI assessments
4. Collect feedback and iterate

---

## Summary

The two-step modal provides a much better user experience for handling multiple assessment images and ensures higher quality training data by validating each image individually. The implementation separates concerns (clinical evaluation vs. AI training) and provides clear progress indicators for users.

This approach scales well as your AI assessment capabilities expand to include more images per appointment.
