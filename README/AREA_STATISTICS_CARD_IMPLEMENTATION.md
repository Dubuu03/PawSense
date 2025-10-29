# Area Statistics Card Implementation

## Overview
Added a Statistics Container on the home page that displays the most common disease in the user's area based on their saved address.

## Implementation Details

### 1. Disease Statistics Service
**File:** `lib/core/services/user/disease_statistics_service.dart`

Features:
- Extracts city/municipality and province from user address
- Address format: "BARANGAY, CITY/MUNICIPALITY, PROVINCE, REGION"
- Queries all users in the same area
- Aggregates assessment results to find most common disease
- Calculates disease count, total cases, and percentage

### 2. Area Statistics Card Widget
**File:** `lib/core/widgets/user/home/area_statistics_card.dart`

Features:
- Displays most common disease in user's area
- Shows three key statistics:
  - **Cases**: Number of detections of the disease
  - **Prevalence**: Percentage of cases
  - **Total**: Total assessments in the area
- Beautiful UI with gradient background
- Loading states, error states, and empty states
- Consistent design matching Pet Container style

### 3. Home Page Integration
**File:** `lib/pages/mobile/home_page.dart`

- Added between Pet Info Card and Health Snapshot
- Proper spacing maintained (kMobileSizedBoxHuge)
- Automatic loading on page load

## UI Design

### Color Scheme
- Primary color for disease name and cases
- Warning color for prevalence
- Text secondary for total cases
- Info color for information banner

### Layout
- Card with white background and shadow
- Header with icon and title
- Disease information in gradient box
- Three-column statistics layout
- Information banner at bottom

## Data Flow

1. User opens home page
2. Widget loads current user's address
3. Service extracts city/municipality from address
4. Service queries all users in same area
5. Service aggregates assessment results
6. Widget displays most common disease with statistics

## Example Output

```
┌──────────────────────────────────────┐
│ 📊 Area Statistics                  │
│ Most common disease in your area    │
├──────────────────────────────────────┤
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 💊 Ringworm                      │ │
│ │ 📍 in TUGUEGARAO CITY           │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌─────┐  ┌──────────┐  ┌──────────┐│
│ │ 45  │  │  65.2%   │  │    69    ││
│ │Cases│  │Prevalence│  │  Total   ││
│ └─────┘  └──────────┘  └──────────┘│
│                                      │
│ ℹ️  Based on 69 pet assessments     │
└──────────────────────────────────────┘
```

## States

### Loading State
- Shows circular progress indicator
- "Loading statistics..." message

### Error State
- Error icon
- Error message
- Occurs when address is not set or query fails

### No Data State
- Analytics icon
- "No disease data available in your area yet" message

### Success State
- Disease name in title case
- Location (city/municipality)
- Three statistics cards
- Information banner

## Performance Considerations

- Uses Firestore batch queries (max 10 users per query)
- Caches user queries
- Asynchronous loading with loading states
- Handles missing or malformed addresses gracefully

## Future Enhancements

1. Add time range filter (last month, 3 months, year)
2. Show top 3 diseases instead of just one
3. Add trend indicators (increasing/decreasing)
4. Enable comparison with neighboring areas
5. Add interactive charts
6. Cache statistics for better performance
