// Firestore Data Debug Checklist
// 
// Run your app and check the console logs for these messages:

/* EXPECTED LOG SEQUENCE:

1. When navigating to Skin Disease Library:
   ✅ "SkinDiseaseLibraryPage: Starting data load..."
   ✅ "SkinDiseaseLibraryPage: Fetching diseases, categories, and recent views..."

2. In the service:
   ✅ "SkinDiseaseService: Querying collection: skin_diseases"
   ✅ "SkinDiseaseService: Raw documents fetched: X" (X should be > 0)
   ✅ "SkinDiseaseService: First document data: {your document data}"
   ✅ "SkinDiseaseService: Successfully parsed disease: [Disease Name]"
   ✅ "SkinDiseaseService: Fetched X diseases from Firestore"

3. Back in the page:
   ✅ "SkinDiseaseLibraryPage: Data fetched successfully"
   ✅ "SkinDiseaseLibraryPage: All diseases count: X"
   ✅ "SkinDiseaseLibraryPage: State updated, showing X diseases"

COMMON ISSUES & SOLUTIONS:

Issue 1: "Raw documents fetched: 0"
→ Collection name mismatch
→ Check: Collection is named exactly "skinDiseases" (camelCase)
→ Fix: Rename collection in Firestore or update _collectionName in service

Issue 2: "Error parsing document [id]"
→ Missing or wrong field types in Firestore document
→ Check console for specific field causing error
→ Fix: Verify all required fields exist with correct types:
   - species: ARRAY (not string)
   - categories: ARRAY (not string)
   - symptoms: ARRAY (not string)
   - causes: ARRAY (not string)
   - treatments: ARRAY (not string)
   - isContagious: BOOLEAN (not string)
   - viewCount: NUMBER (not string)
   - createdAt: TIMESTAMP (not string)
   - updatedAt: TIMESTAMP (not string)

Issue 3: "Failed to load skin diseases: [error]"
→ Firestore rules blocking read access
→ Fix: Update Firestore rules to allow read:
   match /skin_diseases/{diseaseId} {
     allow read: if true;
   }

Issue 4: No logs at all
→ Navigation not working
→ Check: Menu drawer link is correct
→ Fix: Verify route is '/skin-disease-library'

FIRESTORE DOCUMENT STRUCTURE VERIFICATION:

Go to Firebase Console → Firestore Database → skinDiseases

Each document MUST have these fields with EXACT types:

Field Name        | Type      | Example Value
------------------|-----------|----------------------------------
id                | string    | (auto-generated)
name              | string    | "Alopecia (Hair Loss)"
description       | string    | "Patchy or generalized hair loss..."
imageUrl          | string    | "" (can be empty)
species           | array     | ["cats"] or ["dogs"] or ["both"]
severity          | string    | "low" or "moderate" or "high"
detectionMethod   | string    | "ai" or "vet_guided" or "both"
symptoms          | array     | ["Symptom 1", "Symptom 2"]
causes            | array     | ["Cause 1", "Cause 2"]
treatments        | array     | ["Treatment 1", "Treatment 2"]
duration          | string    | "Varies"
isContagious      | boolean   | false
categories        | array     | ["allergic"]
viewCount         | number    | 0
createdAt         | timestamp | (use Firestore timestamp)
updatedAt         | timestamp | (use Firestore timestamp)

QUICK FIX: Sample Document for Copy-Paste

1. Go to Firestore Console
2. Collection: skinDiseases
3. Add Document
4. Use Auto-ID or custom ID
5. Add each field manually with correct type:

Step-by-step:
a) Click "Field" → type "name" → Value: "Alopecia (Hair Loss)"
b) Click "+ Add field" → type "description" → Value: "Patchy hair loss..."
c) Click "+ Add field" → type "imageUrl" → Value: "" (empty)
d) Click "+ Add field" → type "species" → CHANGE TYPE TO "array"
   → Click "Add item" → Value: "cats"
e) Click "+ Add field" → type "severity" → Value: "moderate"
f) Click "+ Add field" → type "detectionMethod" → Value: "ai"
g) Click "+ Add field" → type "symptoms" → CHANGE TYPE TO "array"
   → Click "Add item" → Value: "Patchy hair thinning"
   → Click "Add item" → Value: "Skin redness"
h) Click "+ Add field" → type "causes" → CHANGE TYPE TO "array"
   → Click "Add item" → Value: "Allergies"
i) Click "+ Add field" → type "treatments" → CHANGE TYPE TO "array"
   → Click "Add item" → Value: "Vet consultation required"
j) Click "+ Add field" → type "duration" → Value: "Varies"
k) Click "+ Add field" → type "isContagious" → CHANGE TYPE TO "boolean" → Select "false"
l) Click "+ Add field" → type "categories" → CHANGE TYPE TO "array"
   → Click "Add item" → Value: "allergic"
m) Click "+ Add field" → type "viewCount" → CHANGE TYPE TO "number" → Value: 0
n) Click "+ Add field" → type "createdAt" → CHANGE TYPE TO "timestamp"
   → Click clock icon → Select current date/time
o) Click "+ Add field" → type "updatedAt" → CHANGE TYPE TO "timestamp"
   → Click clock icon → Select current date/time

6. Click "Save"

VERIFICATION STEPS:

After adding the document:
1. Hot restart your app (press 'R' in terminal)
2. Navigate to Skin Disease Info
3. Check console logs for the messages listed above
4. If you see "Raw documents fetched: 1" → SUCCESS!
5. If you see parsing errors → Check field types above
6. If you see 0 documents → Check collection name is 'skinDiseases'

FIRESTORE RULES (if needed):

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /skinDiseases/{diseaseId} {
      allow read: if true;  // Allow everyone to read
      allow write: if false; // Disable writes for now
    }
  }
}

NEED MORE HELP?

Check the detailed logs in your console and compare with expected sequence above.
The logs will tell you exactly where the issue is occurring.

*/
