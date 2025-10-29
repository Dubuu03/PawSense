# Model Training Data Management - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SUPER ADMIN INTERFACE                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  ModelTrainingManagementScreen                                    │  │
│  │  ┌────────────────────────────────────────────────────────────┐  │  │
│  │  │  Header: Title + Stats + Export Button                     │  │  │
│  │  ├────────────────────────────────────────────────────────────┤  │  │
│  │  │  Stats Bar: Total │ Labels │ Validated │ Corrected        │  │  │
│  │  ├────────────────────────────────────────────────────────────┤  │  │
│  │  │  Toolbar: Search │ Pet Filter │ Type Filter │ Select All  │  │  │
│  │  ├───────────────────────────────┬────────────────────────────┤  │  │
│  │  │                               │                            │  │  │
│  │  │  TrainingImageListView        │  TrainingImagePreviewPanel │  │  │
│  │  │  ┌───────────────────────┐    │  ┌──────────────────────┐ │  │  │
│  │  │  │ ☑ Disease Label 1     │    │  │ Image Preview (300px)│ │  │  │
│  │  │  │   ├─☑ image1.jpg      │    │  │ [Click to zoom]      │ │  │  │
│  │  │  │   ├─☑ image2.jpg   ◄──┼────┼──┤                      │ │  │  │
│  │  │  │   └─☐ image3.jpg      │    │  ├──────────────────────┤ │  │  │
│  │  │  ├───────────────────────┤    │  │ Disease Label        │ │  │  │
│  │  │  │ ☐ Disease Label 2     │    │  │ Pet Information      │ │  │  │
│  │  │  ├───────────────────────┤    │  │ Validation Status    │ │  │  │
│  │  │  │ ☐ Disease Label 3     │    │  │ Clinic Diagnosis     │ │  │  │
│  │  │  └───────────────────────┘    │  │ AI Predictions       │ │  │  │
│  │  │                               │  │ Feedback             │ │  │  │
│  │  │                               │  │ Metadata             │ │  │  │
│  │  │                               │  └──────────────────────┘ │  │  │
│  │  └───────────────────────────────┴────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ModelTrainingService                                                   │
│  ├─ fetchAllTrainingData()                                              │
│  │  └─► Query Firestore: model_training_data collection                │
│  │      ├─ Filter: hasImageAssessment = true                            │
│  │      ├─ Order by: validatedAt desc                                   │
│  │      └─ Parse to TrainingImageData objects                           │
│  │                                                                       │
│  └─ exportTrainingImages(selectedByLabel)                               │
│     ├─► For each disease label:                                         │
│     │   ├─ Create folder structure                                      │
│     │   ├─ Download images via HTTP                                     │
│     │   ├─ Add to ZIP archive                                           │
│     │   └─ Generate metadata.json                                       │
│     ├─► Encode ZIP                                                      │
│     └─► Trigger browser download                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Firestore Collection: model_training_data                             │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Document {                                                        │ │
│  │    appointmentId: string                                           │ │
│  │    assessmentResultId: string                                      │ │
│  │    petType: string                                                 │ │
│  │    petBreed: string                                                │ │
│  │    diseaseLabel: string  ◄── Grouping Key                         │ │
│  │    clinicDiagnosis: string                                         │ │
│  │    overallCorrect: boolean                                         │ │
│  │    correctDisease?: string                                         │ │
│  │    canUseForTraining: boolean                                      │ │
│  │    canUseForRetraining: boolean                                    │ │
│  │    hasImageAssessment: boolean                                     │ │
│  │    validatedAt: Timestamp                                          │ │
│  │    aiPredictions: Array<{                                          │ │
│  │      condition: string,                                            │ │
│  │      percentage: number,                                           │ │
│  │      isCorrect: boolean                                            │ │
│  │    }>                                                              │ │
│  │    imageData: {                                                    │ │
│  │      originalImageUrl: string  ◄── Primary Image                  │ │
│  │      annotatedImageUrl?: string                                    │ │
│  │      assessmentImages: Array<{...}>                                │ │
│  │      uniqueFilename: string  ◄── Export Filename                  │ │
│  │      diseaseLabel: string                                          │ │
│  │      correctionType: string                                        │ │
│  │    }                                                               │ │
│  │  }                                                                 │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  Firebase Storage: Images                                              │
│  └─► originalImageUrl, annotatedImageUrl                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         EXPORT OUTPUT                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  training_data_2025-10-22T14-30-52.zip                                 │
│  ├─ contact_dermatitis/                                                │
│  │  ├─ dog_contact_dermatitis_a1b2c3d4_20251022_143052.jpg            │
│  │  ├─ dog_contact_dermatitis_b2c3d4e5_20251022_151233.jpg            │
│  │  └─ metadata.json  ◄── Training Context                            │
│  │     {                                                               │
│  │       "diseaseLabel": "contact_dermatitis",                         │
│  │       "totalImages": 2,                                             │
│  │       "exportedAt": "2025-10-22T14:30:52Z",                         │
│  │       "images": [                                                   │
│  │         {                                                           │
│  │           "id": "doc123",                                           │
│  │           "filename": "dog_contact_...",                            │
│  │           "petType": "Dog",                                         │
│  │           "petBreed": "Golden Retriever",                           │
│  │           "clinicDiagnosis": "...",                                 │
│  │           "overallCorrect": true,                                   │
│  │           "aiPredictions": [...]                                    │
│  │         }                                                           │
│  │       ]                                                             │
│  │     }                                                               │
│  ├─ allergic_dermatitis/                                               │
│  │  ├─ cat_allergic_dermatitis_c3d4e5f6_20251022_160145.jpg           │
│  │  └─ metadata.json                                                   │
│  └─ bacterial_infection/                                               │
│     ├─ dog_bacterial_infection_d4e5f6g7_20251022_112345.jpg            │
│     └─ metadata.json                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Data Collection Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLINIC APPOINTMENT COMPLETION                        │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Vet completes appointment with AI assessment validation               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  1. Review AI predictions                                         │  │
│  │  2. Enter clinic diagnosis and treatment                          │  │
│  │  3. Mark AI assessment as Correct or Incorrect                    │  │
│  │  4. If incorrect, select correct disease from dropdown            │  │
│  │  5. Add optional feedback                                         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA PERSISTENCE                                 │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Firestore Batch Write:                                           │  │
│  │  ├─ Update appointment status to 'completed'                      │  │
│  │  ├─ Update assessment_results with validation                     │  │
│  │  └─ Create model_training_data document ◄── New Collection        │  │
│  │     └─ Includes all validation data + image URLs                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    SUPER ADMIN MANAGEMENT                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  ModelTrainingManagementScreen                                    │  │
│  │  └─ Queries model_training_data collection                        │  │
│  │     └─ Displays grouped by diseaseLabel                           │  │
│  │        └─ Enables selective export                                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         ML TRAINING PIPELINE                            │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  1. Download ZIP file                                             │  │
│  │  2. Extract folders (one per disease)                             │  │
│  │  3. Read metadata.json for context                                │  │
│  │  4. Process images by disease label                               │  │
│  │  5. Use for model training/retraining                             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Hierarchy

```
ModelTrainingManagementScreen (Main Container)
├─ Header
│  ├─ Icon + Title + Description
│  └─ Export Button (with loading state)
├─ Stats Bar
│  ├─ Total Images Stat Card
│  ├─ Disease Labels Stat Card
│  ├─ Validated Stat Card
│  ├─ Corrected Stat Card
│  └─ Selected Count Badge
├─ Toolbar
│  ├─ Search TextField
│  ├─ Pet Type Dropdown
│  ├─ Validation Type Dropdown
│  ├─ Select All / Deselect All Button
│  └─ Refresh IconButton
└─ Content Area (Row)
   ├─ TrainingImageListView (60% width)
   │  ├─ Column Headers
   │  └─ List of Disease Labels
   │     └─ For each label:
   │        ├─ Label Row (with checkbox, expand icon, stats)
   │        └─ If expanded:
   │           └─ Image Rows (with thumbnail, checkbox, metadata)
   └─ TrainingImagePreviewPanel (40% width)
      ├─ Header (with close button)
      ├─ Image Preview Section (with zoom)
      ├─ Disease Label Section
      ├─ Pet Information Card
      ├─ Validation Status Card
      ├─ Clinic Diagnosis Card
      ├─ AI Predictions Card (with progress bars)
      ├─ Feedback Card
      └─ Metadata Card
```

## State Management

```
ModelTrainingManagementScreen State
├─ _groupedImages: Map<String, List<TrainingImageData>>
│  └─ Key: Disease label
│     └─ Value: List of images for that disease
├─ _allLabels: List<String>
│  └─ Sorted list of all disease labels
├─ _selectedImage: TrainingImageData?
│  └─ Currently selected image for preview
├─ _selectedImageIds: Set<String>
│  └─ IDs of all selected images (for export)
├─ _expandedLabels: Set<String>
│  └─ Labels that are currently expanded
├─ _isLoading: bool
│  └─ Initial data load state
├─ _isExporting: bool
│  └─ Export operation in progress
├─ _errorMessage: String?
│  └─ Error display
├─ _searchQuery: String
│  └─ Search filter value
├─ _filterPetType: String
│  └─ Pet type filter (All/Dog/Cat)
├─ _filterValidationType: String
│  └─ Validation filter (All/Validated/Corrected)
└─ Stats
   ├─ _totalImages: int
   ├─ _validatedImages: int
   └─ _correctedImages: int
```

## Key Functions Flow

### Load Data
```
_loadTrainingData()
    │
    ├─► ModelTrainingService.fetchAllTrainingData()
    │   │
    │   ├─► Query Firestore
    │   ├─► Parse documents to TrainingImageData
    │   └─► Filter for images with valid URLs
    │
    ├─► Group by diseaseLabel
    ├─► Sort labels alphabetically
    ├─► Calculate statistics
    └─► Update UI state
```

### Export Selected
```
_exportSelected()
    │
    ├─► Validate selection (not empty)
    ├─► Collect selected images by label
    │
    ├─► ModelTrainingService.exportTrainingImages()
    │   │
    │   ├─► For each disease label:
    │   │   ├─ Create folder in archive
    │   │   ├─ Download images via HTTP
    │   │   ├─ Add images with unique filenames
    │   │   └─ Generate metadata.json
    │   │
    │   ├─► Create ZIP archive
    │   └─► Trigger browser download
    │
    └─► Show success/error notification
```

### Filter & Search
```
_getFilteredLabels()
    │
    ├─► Apply search query (label name)
    ├─► Apply pet type filter
    ├─► Apply validation type filter
    └─► Return filtered list
```

---

**Legend**:
- `►` = Function call / Action
- `├─` = Branch / Option
- `└─` = End of branch
- `◄──` = Important field/feature
- `│` = Connection/Flow
