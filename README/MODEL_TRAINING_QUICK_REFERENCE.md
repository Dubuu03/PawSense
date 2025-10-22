# Model Training Data Management - Quick Reference

## 🚀 Quick Start

### Access the Feature
1. Login as **Super Admin**
2. Click **"Model Training Data"** in sidebar (6th item)
3. Or navigate to: `/super-admin/model-training`

---

## 📊 Dashboard Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ [Icon] Model Training Data Management        [Export Selected]  │
├─────────────────────────────────────────────────────────────────┤
│ [Total: 156] [Labels: 12] [Validated: 98] [Corrected: 58]      │
├─────────────────────────────────────────────────────────────────┤
│ [Search...] [Pet Type ▼] [Type ▼] [Select All] [↻]            │
├───────────────────────────────┬─────────────────────────────────┤
│ List View                     │ Preview Panel                   │
└───────────────────────────────┴─────────────────────────────────┘
```

---

## 🔍 Common Tasks

### Task 1: View All Training Images
1. Page loads with all data automatically
2. Scroll through disease labels
3. Click arrow to expand label and see images

### Task 2: Search for Specific Disease
1. Type disease name in search box (e.g., "contact dermatitis")
2. Results filter instantly
3. Clear search to see all again

### Task 3: Filter by Pet Type
1. Click "Pet Type" dropdown
2. Select: All / Dog / Cat
3. List updates immediately

### Task 4: View Validated Images Only
1. Click "Type" dropdown
2. Select: "Validated"
3. Shows only AI-correct cases

### Task 5: View Corrected Images Only
1. Click "Type" dropdown
2. Select: "Corrected"
3. Shows only AI-incorrect cases that were fixed

### Task 6: Preview Image Details
1. Click any image in the list
2. Preview panel opens on right
3. Scroll to see all details
4. Click preview to zoom full-screen

### Task 7: Export Single Disease
1. Click checkbox next to disease label
2. All images in that label selected
3. Click "Export Selected"
4. ZIP downloads automatically

### Task 8: Export Multiple Diseases
1. Click checkbox for each disease label you want
2. Selected count shows in stats bar
3. Click "Export Selected"
4. ZIP downloads with all selected images grouped

### Task 9: Export Specific Images
1. Expand disease label
2. Click checkbox for individual images
3. Click "Export Selected"
4. Only selected images exported

### Task 10: Export All Filtered Results
1. Apply desired filters (search, pet type, validation type)
2. Click "Select All" button
3. All filtered images selected
4. Click "Export Selected"

---

## 🎯 UI Elements

### Status Badges
- **Green "Valid"**: AI assessment was correct
- **Orange "Fixed"**: AI assessment was incorrect and manually corrected

### Icons
- **📊 Medical Services**: Disease label
- **🐕 Pets**: Dog
- **🐈 Pets**: Cat
- **✓ Check Circle**: Validated
- **✎ Edit**: Corrected
- **🔍 Zoom In**: Click to view full-screen

### Colors
- **Blue**: Info, counts, dog badges
- **Orange**: Warning, corrected status, cat badges
- **Green**: Success, validated status
- **Purple**: Primary, selected items

---

## 📥 Export Details

### Filename Format
```
training_data_2025-10-22T14-30-52.zip
```

### ZIP Contents
```
disease_label_1/
├── dog_disease_apptid_timestamp.jpg
├── cat_disease_apptid_timestamp.jpg
└── metadata.json

disease_label_2/
├── dog_disease_apptid_timestamp.jpg
└── metadata.json
```

### Image Filename Pattern
```
{petType}_{diseaseName}_{appointmentID}_{timestamp}.{ext}

Example:
dog_contact_dermatitis_a1b2c3d4_20251022_143052.jpg
```

### Metadata JSON
Contains:
- Disease label
- Total images
- Export timestamp
- Per-image details:
  - Pet info (type, breed)
  - Clinic diagnosis
  - Validation status
  - AI predictions
  - Timestamps

---

## ⚡ Shortcuts & Tips

### Selection Shortcuts
- **Single click**: Select one image
- **Double-click label**: Select all images in that label
- **Click label checkbox**: Select/deselect entire label
- **"Select All" button**: Select all filtered results
- **"Deselect All" button**: Clear all selections

### Viewing Shortcuts
- **Click image**: Open preview panel
- **Click preview**: Open full-screen zoom
- **ESC**: Close preview/zoom
- **Click outside**: Close full-screen zoom

### Filtering Tips
- Combine filters for precise results
- Search is case-insensitive
- Filters don't re-query database (instant)
- Clear filters to see everything again

---

## 🔧 Troubleshooting

### No Images Showing
**Problem**: List is empty  
**Solution**: 
1. Check if clinics have completed appointments with AI assessments
2. Verify filters aren't too restrictive
3. Click refresh button (↻)

### Export Button Disabled
**Problem**: Can't click Export  
**Solution**: Select at least one image first

### Image Won't Preview
**Problem**: Broken image icon  
**Solution**: Image URL may be invalid - skip and report to tech team

### Export Failed
**Problem**: Error message after clicking Export  
**Solution**:
1. Check internet connection
2. Try selecting fewer images
3. Refresh page and try again

### Slow Loading
**Problem**: Page takes long to load  
**Solution**: 
1. Large dataset - be patient
2. Use filters to reduce visible data
3. Close preview panel if open

---

## 📋 Data Validation

### What Makes Good Training Data?
- ✅ Clear, focused image
- ✅ Validated by veterinarian
- ✅ Correct disease label
- ✅ Complete metadata

### What to Avoid Exporting?
- ❌ Blurry or poor quality images
- ❌ Images with incorrect labels
- ❌ Duplicate images
- ❌ Images without proper validation

---

## 🎓 Understanding the Data

### AI Assessment Status
- **Validated**: Veterinarian confirmed AI was correct
- **Corrected**: Veterinarian corrected AI's mistake

### Training vs Retraining
- **canUseForTraining**: Good examples (AI was correct)
- **canUseForRetraining**: Learning examples (AI was wrong)

### Image Types
- **Original**: Raw image from assessment
- **Annotated**: Image with detection boxes (if available)

---

## 📞 Support

### Common Questions

**Q: How often is data updated?**  
A: Real-time - new data appears as clinics complete appointments

**Q: Can I delete images?**  
A: Not currently - contact development team

**Q: How many images can I export at once?**  
A: No hard limit, but recommend < 500 at a time

**Q: Where do exports download?**  
A: Your browser's default download folder

**Q: Can I re-export the same images?**  
A: Yes, select and export as many times as needed

---

## 🔐 Permissions

**Required Role**: `super_admin`  
**Required Permission**: `view_all_data`

---

## 📊 Statistics Explained

### Total Images
- Count of all images with valid URLs
- Includes validated and corrected

### Disease Labels
- Number of unique disease classifications
- Dynamically updates with new data

### Validated
- Images where AI assessment was correct
- Green badge images
- Good for reinforcement training

### Corrected
- Images where AI was wrong and corrected
- Orange badge images
- Good for correction training

---

## 🎨 Visual Guide

### List View Layout
```
☑ Disease Label (15)        [Dog] [Valid]
  ├─☑ [thumbnail] image1.jpg - Golden Retriever • 10/22/25
  ├─☑ [thumbnail] image2.jpg - Labrador • 10/21/25
  └─☐ [thumbnail] image3.jpg - Poodle • 10/20/25
```

### Preview Panel Sections
1. **Image Preview** - Large view with zoom
2. **Disease Label** - Primary classification
3. **Pet Information** - Type, breed
4. **Validation Status** - Correct/corrected
5. **Clinic Diagnosis** - Vet's assessment
6. **AI Predictions** - Original AI analysis
7. **Feedback** - Vet comments
8. **Metadata** - IDs, timestamps

---

**Last Updated**: October 22, 2025  
**Version**: 1.0.0
