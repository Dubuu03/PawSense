# Skin Disease Information Library - Implementation Guide

## Overview

The Skin Disease Information Library feature provides users with a comprehensive, searchable database of pet skin conditions. This implementation follows the established PawSense architecture patterns and integrates seamlessly with the mobile user interface.

## Architecture

### Component Structure

```
lib/
├── core/
│   ├── models/
│   │   └── skin_disease/
│   │       └── skin_disease_model.dart      # Data model
│   ├── services/
│   │   └── user/
│   │       └── skin_disease_service.dart    # Business logic & Firestore
│   └── widgets/
│       └── shared/
│           └── skin_disease/
│               ├── skin_disease_card.dart          # List item card
│               ├── category_chip.dart              # Filter chip
│               └── skin_disease_empty_state.dart   # Empty state
└── pages/
    └── mobile/
        ├── skin_disease_library_page.dart   # Main list screen
        └── skin_disease_detail_page.dart    # Detail screen
```

## Features Implemented

### 1. Skin Disease Library (List View)
- **Location**: `/skin-disease-library`
- **Access**: Via menu drawer "Skin Disease Info"
- **Features**:
  - Search by name, description, or symptoms
  - Filter by species (All/Cats/Dogs)
  - Filter by category (Parasitic, Allergic, etc.)
  - Filter by AI detection capability
  - Recently viewed diseases section
  - Pull-to-refresh support
  - 24-hour caching for performance

### 2. Disease Detail View
- **Navigation**: Tap any disease card
- **Features**:
  - Full-screen image header
  - Species, duration, and severity badges
  - Detailed description
  - Key symptoms list
  - Common causes list
  - Treatment options list
  - Quick action buttons:
    - Book vet appointment
    - Track condition (links to assessment)

### 3. Caching & Performance
- **Cache Duration**: 24 hours (configurable)
- **Cache Keys**: 
  - All diseases with filters
  - Individual diseases
  - Categories list
  - Recently viewed
- **Auto-invalidation**: On view count updates

## Database Schema

### Firestore Collection: `skinDiseases`

Each document contains:

```dart
{
  "id": String,                    // Auto-generated
  "name": String,                  // e.g., "Alopecia (Hair Loss)"
  "description": String,           // Full description
  "imageUrl": String,              // Cloudinary or Firebase Storage URL
  "species": List<String>,         // ["cats", "dogs", "both"]
  "severity": String,              // "low", "moderate", "high"
  "detectionMethod": String,       // "ai", "vet_guided", "both"
  "symptoms": List<String>,        // Array of symptom strings
  "causes": List<String>,          // Array of cause strings
  "treatments": List<String>,      // Array of treatment strings
  "duration": String,              // e.g., "Varies", "2-4 weeks"
  "isContagious": bool,           // true/false
  "categories": List<String>,      // ["parasitic", "allergic", etc.]
  "viewCount": int,               // Auto-incremented
  "createdAt": Timestamp,         // Auto-set
  "updatedAt": Timestamp          // Auto-updated
}
```

## How to Add/Edit Disease Information

### Option 1: Firestore Console (Recommended for Now)

1. Open Firebase Console: https://console.firebase.google.com
2. Navigate to your project
3. Go to Firestore Database
4. Find the `skin_diseases` collection
5. Click "Add Document" or select existing document

**Example Document:**

```json
{
  "name": "Alopecia (Hair Loss)",
  "description": "Alopecia describes partial or complete hair loss that often reveals flaky or irritated skin beneath the coat.",
  "imageUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/alopecia.jpg",
  "species": ["cats", "dogs"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": [
    "Patchy hair thinning",
    "Skin redness or bumps",
    "Increased grooming"
  ],
  "causes": [
    "Allergy / Stress",
    "Hormonal imbalance",
    "Parasitic infection"
  ],
  "treatments": [
    "Identify and treat underlying cause",
    "Veterinary consultation required",
    "Possible medication or dietary changes"
  ],
  "duration": "Varies",
  "isContagious": false,
  "categories": ["allergic", "hormonal"],
  "viewCount": 0,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Option 2: Using Service Methods (For Admin Panel - Future)

The service includes CRUD methods for future admin panel integration:

```dart
final service = SkinDiseaseService();

// Create new disease
final id = await service.createDisease(diseaseModel);

// Update existing disease
await service.updateDisease(id, updatedModel);

// Delete disease
await service.deleteDisease(id);
```

## Sample Diseases (Placeholder Data)

Here are 9 sample diseases you can add to get started:

### 1. Alopecia (Hair Loss) - CATS
```json
{
  "name": "Alopecia (Hair Loss)",
  "description": "Patchy or generalized hair loss that often reveals flaky or irritated skin beneath the coat.",
  "imageUrl": "",
  "species": ["cats"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": ["Patchy hair thinning", "Skin redness or bumps", "Increased grooming"],
  "causes": ["Chronic stress", "Allergies", "Hormonal imbalance", "Underlying infections"],
  "treatments": ["Identifying the trigger is essential for preventing recurrence"],
  "duration": "Varies",
  "isContagious": false,
  "categories": ["allergic"],
  "viewCount": 0
}
```

### 2. Eosinophilic Plaque - CATS
```json
{
  "name": "Eosinophilic Plaque",
  "description": "Raised, moist lesions typically on the belly or thighs that signal an inflammatory allergic response.",
  "imageUrl": "",
  "species": ["cats"],
  "severity": "high",
  "detectionMethod": "ai",
  "symptoms": ["Raised lesions", "Moist appearance", "Often on belly/thighs"],
  "causes": ["Allergic reaction", "Environmental triggers", "Food sensitivities"],
  "treatments": ["Anti-inflammatory medication", "Identify allergen", "Veterinary care required"],
  "duration": "2-4 weeks with treatment",
  "isContagious": false,
  "categories": ["allergic"],
  "viewCount": 0
}
```

### 3. Miliary Dermatitis - CATS
```json
{
  "name": "Miliary Dermatitis",
  "description": "Tiny crusted bumps across the back or neck that feel like millet seeds and itch intensely.",
  "imageUrl": "",
  "species": ["cats"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": ["Tiny bumps", "Intense itching", "Crusty texture"],
  "causes": ["Flea allergy", "Food allergy", "Bacterial infection"],
  "treatments": ["Flea control", "Antibiotics if infected", "Allergy management"],
  "duration": "1-3 weeks",
  "isContagious": false,
  "categories": ["parasitic", "allergic"],
  "viewCount": 0
}
```

### 4. Hotspots (Acute Moist Dermatitis) - DOGS
```json
{
  "name": "Hotspots",
  "description": "Red, moist, irritated patches that appear suddenly and spread quickly if untreated.",
  "imageUrl": "",
  "species": ["dogs"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": ["Red moist patches", "Rapid spreading", "Intense itching", "Hair loss"],
  "causes": ["Moisture retention", "Allergies", "Poor grooming", "Insect bites"],
  "treatments": ["Clean and dry area", "Topical antibiotics", "Prevent licking/scratching"],
  "duration": "3-7 days with treatment",
  "isContagious": false,
  "categories": ["bacterial"],
  "viewCount": 0
}
```

### 5. Ringworm - BOTH
```json
{
  "name": "Ringworm",
  "description": "A fungal infection causing circular, scaly patches with hair loss, often with a red ring.",
  "imageUrl": "",
  "species": ["both"],
  "severity": "moderate",
  "detectionMethod": "vet_guided",
  "symptoms": ["Circular patches", "Hair loss", "Scaly skin", "Red ring border"],
  "causes": ["Fungal infection", "Contact with infected animals", "Contaminated environment"],
  "treatments": ["Antifungal medication", "Topical treatment", "Environmental decontamination"],
  "duration": "2-4 weeks",
  "isContagious": true,
  "categories": ["fungal"],
  "viewCount": 0
}
```

### 6. Flea Infestation - BOTH
```json
{
  "name": "Flea Infestation",
  "description": "Excessive scratching, visible fleas or flea dirt, and potential hair loss from allergic reactions.",
  "imageUrl": "",
  "species": ["both"],
  "severity": "high",
  "detectionMethod": "vet_guided",
  "symptoms": ["Excessive scratching", "Visible fleas", "Black flea dirt", "Red irritated skin"],
  "causes": ["Direct flea contact", "Environmental contamination", "Untreated pets"],
  "treatments": ["Flea treatment medication", "Environmental cleaning", "Preventive treatment"],
  "duration": "1-2 weeks",
  "isContagious": true,
  "categories": ["parasitic"],
  "viewCount": 0
}
```

### 7. Yeast Infection (Malassezia) - DOGS
```json
{
  "name": "Yeast Infection",
  "description": "Greasy, smelly skin with dark discoloration, often in ear canals and skin folds.",
  "imageUrl": "",
  "species": ["dogs"],
  "severity": "moderate",
  "detectionMethod": "vet_guided",
  "symptoms": ["Greasy skin", "Unpleasant odor", "Dark discoloration", "Itching"],
  "causes": ["Moisture in skin folds", "Allergies", "Immune system issues"],
  "treatments": ["Antifungal shampoo", "Medication", "Keep area dry", "Address underlying allergies"],
  "duration": "2-3 weeks",
  "isContagious": false,
  "categories": ["fungal"],
  "viewCount": 0
}
```

### 8. Mange (Sarcoptic) - DOGS
```json
{
  "name": "Mange",
  "description": "Intense itching with hair loss, crusty skin, and thickened patches, caused by mites.",
  "imageUrl": "",
  "species": ["dogs"],
  "severity": "high",
  "detectionMethod": "vet_guided",
  "symptoms": ["Intense itching", "Hair loss", "Crusty skin", "Thickened patches"],
  "causes": ["Sarcoptic mite infestation", "Contact with infected animals"],
  "treatments": ["Prescription medication", "Medicated baths", "Environmental treatment"],
  "duration": "4-6 weeks",
  "isContagious": true,
  "categories": ["parasitic"],
  "viewCount": 0
}
```

### 9. Pyoderma (Bacterial Infection) - DOGS
```json
{
  "name": "Pyoderma",
  "description": "Pustules, crusts, and circular lesions with hair loss, indicating bacterial skin infection.",
  "imageUrl": "",
  "species": ["dogs"],
  "severity": "moderate",
  "detectionMethod": "ai",
  "symptoms": ["Pustules", "Crusty lesions", "Circular patterns", "Hair loss"],
  "causes": ["Bacterial overgrowth", "Allergies", "Compromised skin barrier"],
  "treatments": ["Antibiotics", "Medicated shampoo", "Address underlying cause"],
  "duration": "2-4 weeks",
  "isContagious": false,
  "categories": ["bacterial"],
  "viewCount": 0
}
```

## Category Types

Available categories (add as needed):
- `parasitic` - Flea, mite, tick-related
- `allergic` - Allergy-induced conditions
- `bacterial` - Bacterial infections
- `fungal` - Fungal/yeast infections
- `viral` - Virus-caused conditions
- `autoimmune` - Immune system disorders
- `hormonal` - Hormone-related issues

## Image Guidelines

### Recommended Image Sources:
1. **Cloudinary** (Recommended)
   - Upload to your PawSense Cloudinary account
   - Use transformations for optimization
   - Example URL: `https://res.cloudinary.com/pawsense/image/upload/v1/skinDiseases/alopecia.jpg`

2. **Firebase Storage**
   - Upload to `gs://your-project.appspot.com/skinDiseases/`
   - Get public URL

3. **Placeholder Images**
   - Leave `imageUrl` empty - app shows default medical icon

### Image Specifications:
- **Aspect Ratio**: 16:9 preferred
- **Resolution**: 1280x720 or higher
- **Format**: JPG or PNG
- **Size**: < 500KB (Cloudinary will optimize)

## Cache Management

### Manual Cache Clear (For Testing)

```dart
final service = SkinDiseaseService();
service.clearCache(); // Clears all cached disease data
```

### Automatic Cache Invalidation

Cache is automatically invalidated when:
- A disease is created, updated, or deleted
- View count is incremented
- Cache TTL (24 hours) expires

## Testing the Feature

### 1. Add Sample Data
1. Go to Firestore Console
2. Create `skinDiseases` collection (if not exists)
3. Add at least 3-5 diseases using samples above
4. Set `createdAt` and `updatedAt` to current timestamp

### 2. Test Navigation
1. Open PawSense mobile app
2. Tap hamburger menu (top left)
3. Tap "Skin Disease Info"
4. Verify library page loads

### 3. Test Filters
- Search for disease names
- Toggle Cats/Dogs/All
- Select different categories
- Toggle "AI Detectable"
- Verify empty state appears when no results

### 4. Test Detail View
- Tap any disease card
- Verify all sections display correctly
- Tap "Book vet appointment" (navigates to booking)
- Tap "Track condition" (navigates to assessment)
- Tap back button

### 5. Test Performance
- Pull to refresh
- Navigate away and back (should use cache)
- Wait 24 hours and verify fresh data loaded

## Future Enhancements

### Admin Panel Integration
- CRUD interface for diseases
- Bulk import via CSV
- Image upload directly in app
- Preview before publish

### User Features
- Bookmark favorite diseases
- Share disease info
- Track symptoms for pet
- AI detection integration with camera

### Analytics
- Track popular diseases
- Search analytics
- User engagement metrics

## Troubleshooting

### No diseases showing
1. Check Firestore: Collection `skinDiseases` exists and has documents
2. Check console logs: Look for "SkinDiseaseService:" messages
3. Check internet connection
4. Try pull-to-refresh

### Images not loading
1. Verify `imageUrl` is valid and publicly accessible
2. Check CORS settings if using external URLs
3. Clear cache and reload

### Filters not working
1. Check data format in Firestore matches schema
2. Verify `species` and `categories` are arrays
3. Check console for errors

## Code Maintenance

### Adding New Filter Categories
1. Update `getCategories()` in service (optional)
2. Update category icons in `CategoryChip` widget
3. Add to database schema documentation

### Modifying Cache Duration
```dart
// In skin_disease_service.dart
static const Duration _cacheDuration = Duration(hours: 24); // Change here
```

### Customizing UI
- Colors: `lib/core/utils/app_colors.dart`
- Spacing: `lib/core/utils/constants_mobile.dart`
- Card design: `lib/core/widgets/shared/skin_disease/skin_disease_card.dart`
- Detail layout: `lib/pages/mobile/skin_disease_detail_page.dart`

## Questions & Support

For questions about this implementation, refer to:
- **Phase 1 Analysis**: Project architecture patterns
- **Firebase Console**: Database management
- **Cloudinary Docs**: Image optimization
- **Flutter Docs**: Widget customization

---

**Last Updated**: 2024-01-01  
**Version**: 1.0.0  
**Author**: PawSense Development Team
