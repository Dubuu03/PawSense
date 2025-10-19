# Unique Disease Filter and Toggle Button Fix

## Summary
Fixed two critical issues with the detection results display:
1. **Unique Disease Filtering**: Now shows only unique diseases in the top 3 detections (no duplicates)
2. **Toggle Button Fix**: Fixed the show/hide bounding boxes button in AI history detail page

## Date
October 18, 2025

---

## Issue 1: Duplicate Diseases in Detection Results

### Problem
The detection results were showing the same disease multiple times in the top 3 list if the AI detected it in different locations with different confidence levels. This was confusing and didn't provide useful information to users.

**Example of the problem:**
```
1. 🟠 Ringworm - 85.3%
2. 🔵 Ringworm - 82.1%  ← Duplicate!
3. 🟢 Ringworm - 78.5%  ← Duplicate!
```

### Solution
Added unique disease name filtering to ensure each disease appears only once in the top 3 results. The system now:
- Sorts all detections by confidence (highest first)
- Tracks which diseases have been shown using a `Set<String>`
- Only adds detections for diseases that haven't been shown yet
- Stops after showing 3 unique diseases

**After the fix:**
```
1. 🟠 Ringworm - 85.3%
2. 🔵 Mange - 72.4%
3. 🟢 Hot Spot - 68.9%
```

### Files Modified

#### 1. `lib/pages/mobile/history/ai_history_detail_page.dart`

**Location:** `_buildDetectionResultItem()` method

**Changes:**
```dart
// OLD: Just took top 3 without checking for duplicates
final detectionsToShow = sortedDetections.take(MAX_DETECTIONS_TO_SHOW).toList();

// NEW: Filter for unique diseases only
final List<Detection> detectionsToShow = [];
final Set<String> seenDiseases = {};

for (final detection in sortedDetections) {
  final formattedLabel = DetectionUtils.formatConditionName(detection.label);
  if (!seenDiseases.contains(formattedLabel)) {
    detectionsToShow.add(detection);
    seenDiseases.add(formattedLabel);
    
    if (detectionsToShow.length >= MAX_DETECTIONS_TO_SHOW) {
      break;
    }
  }
}
```

#### 2. `lib/core/widgets/user/assessment/assessment_step_three.dart`

**Location:** `_buildAssessmentImagesContainer()` method in the image loop

**Changes:**
```dart
// Added Set to track unique diseases
Set<String> seenDiseases = {}; // Track unique disease names

// Added check before processing each detection
final formattedLabel = _formatConditionName(label);

// Skip if we've already seen this disease
if (seenDiseases.contains(formattedLabel)) {
  continue;
}

// After adding a detection
seenDiseases.add(formattedLabel); // Mark this disease as seen
```

**Note:** Assessment step three already had IoU (Intersection over Union) filtering for spatial duplicates. We enhanced it by also checking for unique disease names.

#### 3. `lib/pages/mobile/history/ai_history_detail_page.dart`

**Location:** `_showFullscreenImage()` method

Applied the same unique filtering logic to the fullscreen viewer:
```dart
// Filter for unique diseases only
final List<Detection> uniqueDetections = [];
final Set<String> seenDiseases = {};

for (final detection in sortedDetections) {
  final formattedLabel = DetectionUtils.formatConditionName(detection.label);
  if (!seenDiseases.contains(formattedLabel)) {
    uniqueDetections.add(detection);
    seenDiseases.add(formattedLabel);
    
    if (uniqueDetections.length >= MAX_DETECTIONS_TO_SHOW) {
      break;
    }
  }
}
```

---

## Issue 2: Toggle Button Not Working in AI History Detail

### Problem
The show/hide bounding boxes toggle button in the fullscreen image viewer wasn't working. Clicking it had no effect - the bounding boxes remained visible.

**Root Cause:** The `showingBoundingBoxes` boolean variable was declared inside the `StatefulBuilder.builder()` method, which meant it was reset to the default value (`true`) on every rebuild. When the user clicked the toggle button, it would trigger a rebuild, but the variable would immediately reset back to `true`.

```dart
// WRONG - Variable resets on every rebuild
return StatefulBuilder(
  builder: (context, setDialogState) {
    bool showingBoundingBoxes = detectionsToShow.isNotEmpty; // ← RESETS HERE!
    
    return Dialog(...);
  },
);
```

### Solution
Moved the `showingBoundingBoxes` variable **outside** the builder function so it persists across rebuilds. The variable is now in the proper scope where `setDialogState()` can modify it and have the change persist.

```dart
// CORRECT - Variable persists across rebuilds
bool showingBoundingBoxes = detectionsToShow.isNotEmpty; // ← Declared outside

showDialog(
  context: context,
  barrierColor: Colors.black87,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        // Variable is accessible here and persists
        return Dialog(...);
      },
    );
  },
);
```

### Files Modified

**File:** `lib/pages/mobile/history/ai_history_detail_page.dart`

**Location:** `_showFullscreenImage()` method

**Changes:**
```dart
// State variable must be outside the builder to persist across rebuilds
bool showingBoundingBoxes = detectionsToShow.isNotEmpty; // Show by default if detections exist

showDialog(
  context: context,
  barrierColor: Colors.black87,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          // ... UI code ...
          
          // Toggle button now works properly
          IconButton(
            onPressed: () {
              setDialogState(() {
                showingBoundingBoxes = !showingBoundingBoxes;
              });
            },
            // ... icon configuration ...
          ),
        );
      },
    );
  },
);
```

---

## How It Works Now

### Detection Results Display

1. **Sorting**: All detections are sorted by confidence (highest first)
2. **Unique Filtering**: Uses a `Set<String>` to track which diseases have been shown
3. **Selection**: Takes up to 3 unique diseases with the highest confidence
4. **Display**: Shows them with rank-based color coding:
   - 🟠 **Orange** - Highest confidence (1st)
   - 🔵 **Blue** - Second highest (2nd)
   - 🟢 **Green** - Third highest (3rd)

### Fullscreen Toggle Button

1. **Default State**: Bounding boxes are visible by default if detections exist
2. **Toggle Action**: User clicks the eye icon button
3. **State Update**: `setDialogState()` toggles the boolean
4. **UI Update**: 
   - Bounding boxes appear/disappear
   - Button icon changes (eye vs eye-off)
   - Button color changes (blue when active, gray when inactive)
   - Detection info badge appears/disappears

---

## Testing Recommendations

### Unique Disease Filtering
1. ✅ Test with an image that has the same disease detected multiple times
2. ✅ Verify only one instance of each disease appears in top 3
3. ✅ Verify the highest confidence instance is selected
4. ✅ Test with images having 1, 2, or 3+ unique diseases
5. ✅ Verify the filtering works in both:
   - Assessment step three (during assessment)
   - AI history detail page (viewing past assessments)

### Toggle Button
1. ✅ Click the toggle button and verify bounding boxes disappear
2. ✅ Click again and verify they reappear
3. ✅ Verify the button icon changes (eye ↔ eye-off)
4. ✅ Verify the button color changes (blue ↔ gray)
5. ✅ Verify the detection info badge appears/disappears
6. ✅ Test with images having 0, 1, 2, or 3 detections
7. ✅ Verify the toggle persists while zooming/panning the image

---

## Technical Details

### Unique Detection Algorithm

**Time Complexity:** O(n) where n = number of detections
- Single pass through sorted detections
- Set lookup is O(1) average case
- Very efficient even with many detections

**Space Complexity:** O(k) where k = unique diseases (max 3)
- Only stores seen disease names
- Minimal memory footprint

### StatefulBuilder Pattern

**Correct Pattern:**
```dart
// State outside builder
Type stateVariable = initialValue;

StatefulBuilder(
  builder: (context, setState) {
    // Use stateVariable here
    // Modifications via setState persist
  },
)
```

**Incorrect Pattern:**
```dart
StatefulBuilder(
  builder: (context, setState) {
    // State inside builder - WRONG!
    Type stateVariable = initialValue; // Resets every rebuild
  },
)
```

---

## User Benefits

1. ✨ **Clearer Results**: No duplicate diseases in detection results
2. 🎯 **More Informative**: See 3 different conditions instead of the same one 3 times
3. 🔄 **Working Toggle**: Can now actually hide/show bounding boxes as needed
4. 👁️ **Better Control**: Choose when to see detailed detection overlays
5. 📊 **Accurate Ranking**: Top 3 unique diseases by confidence level
6. 🎨 **Consistent Experience**: Same behavior across assessment and history views

---

## Related Documentation

- See `BOUNDING_BOX_IMPROVEMENTS.md` for the original bounding box implementation
- See `ACCURATE_BOUNDING_BOX_FIX.md` for bounding box positioning details
- See detection processing in `lib/core/utils/detection_utils.dart`
