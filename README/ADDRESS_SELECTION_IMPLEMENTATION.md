# Address Selection System Implementation

## Overview
Successfully implemented a structured address selection system for PawSense that uses Philippine address data (region, province, municipality, barangay) with cascading dropdowns.

## Changes Made

### 1. Created Address Service (`lib/core/services/shared/address_service.dart`)
- **Purpose**: Load and parse Philippine address data from JSON file
- **Features**:
  - Singleton pattern for efficient data management
  - Lazy loading of address data from assets
  - Methods to retrieve regions, provinces, municipalities, and barangays
  - Cascading data retrieval based on selections
  - Address formatting utility
- **Models**:
  - `RegionData`: Contains region code and name
  - `ProvinceData`: Contains province name
  - `MunicipalityData`: Contains municipality/city name
  - `BarangayData`: Contains barangay name

### 2. Created Address Selector Modal (`lib/core/widgets/shared/address_selector_modal.dart`)
- **Purpose**: Interactive modal for selecting structured addresses
- **Features**:
  - Four cascading dropdowns (Region → Province → Municipality → Barangay)
  - Real-time preview of selected address
  - Loading states for each dropdown
  - Validation to ensure all fields are selected
  - Clean, user-friendly UI with Material Design
  - Returns formatted address string and individual components

### 3. Updated Sign-Up Page (`lib/pages/mobile/auth/sign_up_page.dart`)
- **Changes**:
  - Replaced free-text address field with address selector button
  - Added `AddressSelectorModal` import
  - Created `_buildAddressSelectorField()` method
  - Button shows "Tap to select address" when empty
  - Displays full formatted address once selected
  - Maintains error state handling
  - Uses same styling as other form fields

### 4. Updated Edit Profile Page (`lib/pages/mobile/edit_profile_page.dart`)
- **Changes**:
  - Replaced free-text address field with address selector
  - Added `AddressSelectorModal` import
  - Created `_buildAddressSelectorField()` method
  - Shows current address if already set
  - Button displays "Edit" when address exists, "Select" when empty
  - Includes location icon and styled edit button
  - Maintains validation and error handling

### 5. Updated pubspec.yaml
- **Changes**:
  - Added JSON file to assets:
    ```yaml
    - assets/philippine_provinces_cities_municipalities_and_barangays_2019v2.json
    ```

## User Experience

### Sign-Up Flow
1. User clicks on the address field
2. Modal opens with four dropdowns
3. User selects Region (e.g., "NCR")
4. Province dropdown populates based on region
5. User selects Province (e.g., "NATIONAL CAPITAL REGION - MANILA")
6. Municipality dropdown populates
7. User selects Municipality (e.g., "CITY OF MANILA")
8. Barangay dropdown populates
9. User selects Barangay (e.g., "ERMITA")
10. Preview shows: "ERMITA, CITY OF MANILA, NATIONAL CAPITAL REGION - MANILA, NCR"
11. User clicks "Confirm"
12. Address field displays the formatted address

### Edit Profile Flow
1. Current address is displayed in the address field
2. User clicks the field or "Edit" button
3. Same modal opens for address selection
4. User can change any part of the address
5. New address replaces the old one upon confirmation

## Address Format
The final address is formatted as:
```
Barangay, Municipality, Province, Region
```

Example:
```
ERMITA, CITY OF MANILA, NATIONAL CAPITAL REGION - MANILA, NCR
```

## Technical Details

### Data Flow
1. **Service Layer**: `AddressService` loads JSON once and caches it
2. **UI Layer**: Modal makes async calls to service for each dropdown
3. **State Management**: Local state in modal tracks selections
4. **Parent Integration**: Modal returns formatted address via `Navigator.pop()`

### Performance Considerations
- JSON data is loaded once and cached
- Data is only loaded when needed (lazy loading)
- Dropdowns are populated asynchronously with loading indicators
- Efficient sorting and filtering of options

### Error Handling
- Try-catch blocks for JSON loading failures
- Null safety throughout the codebase
- User-friendly error messages via SnackBar
- Validation ensures all fields are selected before confirmation

## Benefits

1. **Data Consistency**: All addresses follow the same structure
2. **No Typos**: Users select from predefined options
3. **Better UX**: Clear, guided selection process
4. **Easy Validation**: Address is guaranteed to be complete and valid
5. **Database Friendly**: Structured data can be queried efficiently
6. **Future-Ready**: Can easily add analytics or mapping features

## Testing Recommendations

1. Test with different regions to ensure data loads correctly
2. Verify that cascading dropdowns clear properly when changing selections
3. Test error handling by simulating JSON load failures
4. Verify address formatting is correct for all combinations
5. Test on different screen sizes for responsive layout
6. Verify existing user addresses display correctly in edit profile

## Future Enhancements (Optional)

1. Add search/filter capability in dropdowns
2. Cache recently selected addresses for quick re-selection
3. Add GPS-based location detection
4. Store address components separately in database for better querying
5. Add address validation against delivery service coverage areas
6. Support for international addresses
