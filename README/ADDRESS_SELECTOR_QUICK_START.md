# Address Selector - Quick Start Guide

## How to Use

### For Sign-Up Page

```dart
// The address field is now a button that opens the address selector modal
_buildAddressSelectorField()
```

**User Experience:**
- Tap the address field
- Select Region from dropdown
- Select Province (auto-populated based on region)
- Select Municipality (auto-populated based on province)
- Select Barangay (auto-populated based on municipality)
- See preview of complete address
- Click "Confirm" to save

### For Edit Profile Page

```dart
// Same implementation with "Edit" button when address exists
_buildAddressSelectorField()
```

**User Experience:**
- Current address is displayed
- Tap the field or click "Edit" button
- Follow same selection process
- New address replaces old one

## Code Examples

### Opening the Address Selector Modal

```dart
final result = await showDialog<Map<String, String>>(
  context: context,
  barrierDismissible: true,
  builder: (context) => const AddressSelectorModal(),
);

if (result != null && mounted) {
  setState(() {
    _addressController.text = result['formattedAddress'] ?? '';
    _fieldErrors['address'] = null;
  });
}
```

### Result Format

The modal returns a `Map<String, String>` with the following keys:
- `region`: e.g., "NCR"
- `province`: e.g., "NATIONAL CAPITAL REGION - MANILA"
- `municipality`: e.g., "CITY OF MANILA"
- `barangay`: e.g., "ERMITA"
- `formattedAddress`: e.g., "ERMITA, CITY OF MANILA, NATIONAL CAPITAL REGION - MANILA, NCR"

## Using Address Service Directly

If you need to use the address service in other parts of the app:

```dart
import 'package:pawsense/core/services/shared/address_service.dart';

final addressService = AddressService();

// Get all regions
final regions = await addressService.getRegions();

// Get provinces for a specific region
final provinces = await addressService.getProvinces('NCR');

// Get municipalities for a region and province
final municipalities = await addressService.getMunicipalities(
  'NCR',
  'NATIONAL CAPITAL REGION - MANILA',
);

// Get barangays
final barangays = await addressService.getBarangays(
  'NCR',
  'NATIONAL CAPITAL REGION - MANILA',
  'CITY OF MANILA',
);

// Format address
final formatted = addressService.formatAddress(
  region: 'NCR',
  province: 'NATIONAL CAPITAL REGION - MANILA',
  municipality: 'CITY OF MANILA',
  barangay: 'ERMITA',
);
// Result: "ERMITA, CITY OF MANILA, NATIONAL CAPITAL REGION - MANILA, NCR"
```

## Styling Customization

The address selector field uses these colors from `AppColors`:
- `primary`: For icons and buttons
- `error`: For validation errors
- `textPrimary`: For main text
- `textSecondary`: For placeholder text
- `white`: For background
- `border`: For borders

To customize, modify the colors in `lib/core/utils/app_colors.dart`.

## Validation

Address validation is automatic:
- Empty address triggers error: "Address is required"
- Modal ensures all fields are selected before confirming
- Error state is shown with red border and error text

## Common Issues & Solutions

### Issue: "Failed to load address data"
**Solution**: Ensure the JSON file is in assets and pubspec.yaml includes:
```yaml
assets:
  - assets/philippine_provinces_cities_municipalities_and_barangays_2019v2.json
```

### Issue: Dropdowns not populating
**Solution**: Check that previous selections are made correctly. Each dropdown depends on the previous one.

### Issue: Modal not closing after confirm
**Solution**: Ensure all four fields (region, province, municipality, barangay) are selected.

## Performance Tips

1. The service uses a singleton pattern - data is loaded once and cached
2. Data is loaded lazily (only when needed)
3. Dropdowns populate asynchronously with loading indicators
4. Lists are sorted alphabetically for easy browsing

## Accessibility

The address selector supports:
- Keyboard navigation in dropdowns
- Screen reader compatibility
- Clear visual feedback for selections
- Loading states with indicators
- Error messages with sufficient contrast
