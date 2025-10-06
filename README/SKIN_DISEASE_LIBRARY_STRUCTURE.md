# Skin Disease Library - Visual Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                      MOBILE APP FLOW                             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Menu Drawer  │
│              │
│ [Skin        │
│  Disease     │──────┐
│  Info]       │      │
└──────────────┘      │
                      │ Navigate: /skin-disease-library
                      ↓
┌────────────────────────────────────────────────────────────────┐
│         SKIN DISEASE LIBRARY PAGE (List View)                  │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  📖 Info Banner                                          │  │
│  │  "Learn about common pet skin conditions..."            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  🔍 Search: "Search skin diseases..."             [×]    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                          │
│  │ 🐾 All  │ │ 🐱 Cats │ │ 🐶 Dogs │  ← Species Toggle        │
│  └─────────┘ └─────────┘ └─────────┘                          │
│                                                                 │
│  RECENT     [ ✨ AI Detectable ]  ← Detection Filter          │
│                                                                 │
│  [ 🦠 Parasitic ] [ 🌼 Allergic ] [ 🧫 Bacterial ]...          │
│  ← Category Filter Chips (Horizontal Scroll)                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Recently viewed                                          │  │
│  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                     │  │
│  │ │ IMG  │ │ IMG  │ │ IMG  │ │ IMG  │  ← Horizontal Scroll│  │
│  │ │Title │ │Title │ │Title │ │Title │                     │  │
│  │ │ AI   │ │ AI   │ │Vet   │ │ AI   │                     │  │
│  │ └──────┘ └──────┘ └──────┘ └──────┘                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ┌─────────────────────────────────────┐                  │  │
│  │ │   [DISEASE IMAGE]                   │                  │  │
│  │ └─────────────────────────────────────┘                  │  │
│  │ Alopecia (Hair Loss)         ✨ AI  ● Moderate  🐱 Cats │  │
│  │ Patchy or generalized hair loss that often...           │  │
│  │                                    Learn More →          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ┌─────────────────────────────────────┐                  │  │
│  │ │   [DISEASE IMAGE]                   │                  │  │
│  │ └─────────────────────────────────────┘                  │  │
│  │ Eosinophilic Plaque      ✨ AI  ● High  🐱 Cats         │  │
│  │ Raised, moist lesions typically on the belly...         │  │
│  │                                    Learn More →          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  [More diseases...]                                            │
│                                                                 │
│  OR: Empty State (if no results)                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         🔍 (large icon)                                   │  │
│  │      No results found for "query"                         │  │
│  │   Try adjusting your filters or search term              │  │
│  │         [Clear Filters]                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                      │
                      │ Tap disease card
                      ↓
┌────────────────────────────────────────────────────────────────┐
│         SKIN DISEASE DETAIL PAGE (Detail View)                 │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ←                                           🔖  ⋯        │  │
│  │                                                           │  │
│  │          [FULL-SCREEN DISEASE IMAGE]                     │  │
│  │                                                           │  │
│  │               ▼ Gradient Overlay ▼                       │  │
│  │  ALLERGIC • HORMONAL                                     │  │
│  │  Alopecia (Hair Loss)                                    │  │
│  │  [Moderate Severity]                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐             │
│  │      🐾              │  │      ⏱️              │             │
│  │    SPECIES           │  │    DURATION          │             │
│  │  Cats & Dogs         │  │     Varies           │             │
│  └─────────────────────┘  └─────────────────────┘             │
│                                                                 │
│  What is this condition?                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Alopecia describes partial or complete hair loss that   │  │
│  │ often reveals flaky or irritated skin beneath the coat. │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Key symptoms to watch for                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ⚠️  Patchy hair thinning                                 │  │
│  │ ⚠️  Skin redness or bumps                                │  │
│  │ ⚠️  Increased grooming                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Common causes                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 💊  Chronic stress                                        │  │
│  │ 💊  Allergies                                             │  │
│  │ 💊  Hormonal imbalance                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Treatment options                                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 💉  Identifying the trigger is essential                 │  │
│  │ 💉  Veterinary consultation required                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        📅  Book vet appointment                          │  │ → /book-appointment
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        ➕  Track Alopecia (Hair Loss)                    │  │ → /assessment
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                      DATA FLOW                                   │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  Firestore DB    │
│  Collection:     │
│  skinDiseases    │
└────────┬─────────┘
         │
         │ Query
         ↓
┌──────────────────────────┐
│ SkinDiseaseService       │
│ - getAllDiseases()       │
│ - getDiseaseById()       │
│ - searchDiseases()       │
│ - getCategories()        │
│ - getRecentlyViewed()    │
└────────┬─────────────────┘
         │
         │ 24-hour Cache (DataCache)
         ↓
┌──────────────────────────┐
│ SkinDiseaseModel         │
│ - id                     │
│ - name                   │
│ - description            │
│ - imageUrl               │
│ - species: []            │
│ - severity               │
│ - symptoms: []           │
│ - etc.                   │
└────────┬─────────────────┘
         │
         │ Display
         ↓
┌──────────────────────────┐
│ UI Widgets               │
│ - SkinDiseaseCard        │
│ - CategoryChip           │
│ - RecentDiseaseCard      │
│ - EmptyState             │
└──────────────────────────┘
         │
         │ Render
         ↓
┌──────────────────────────┐
│ Pages                    │
│ - LibraryPage            │
│ - DetailPage             │
└──────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                 COMPONENT HIERARCHY                              │
└─────────────────────────────────────────────────────────────────┘

SkinDiseaseLibraryPage (StatefulWidget)
│
├─ UserAppBar
│  └─ Menu button, Logo, Profile
│
├─ Info Banner (Container)
│  └─ Icon + Text
│
├─ Search Bar (TextField)
│  └─ Search icon + Input + Clear button
│
├─ Species Toggle (Row of buttons)
│  ├─ All button
│  ├─ Cats button
│  └─ Dogs button
│
├─ Filter Section
│  ├─ "RECENT" text + AI toggle
│  └─ Category chips (Horizontal ListView)
│     └─ CategoryChip widgets
│
├─ Recently Viewed Section (optional)
│  └─ Horizontal ListView
│     └─ RecentDiseaseCard widgets
│
└─ Disease List (SliverList)
   ├─ SkinDiseaseCard
   ├─ SkinDiseaseCard
   └─ ... or EmptyState


SkinDiseaseDetailPage (StatelessWidget)
│
├─ SliverAppBar
│  ├─ Back button
│  ├─ Bookmark button
│  ├─ Share button
│  └─ FlexibleSpaceBar
│     ├─ Disease image
│     ├─ Gradient overlay
│     └─ Title + Category + Severity
│
├─ Info Badges (Row)
│  ├─ Species badge
│  └─ Duration badge
│
├─ Description Section
│  └─ "What is this condition?" text
│
├─ Symptoms Section (optional)
│  └─ List of symptoms with icons
│
├─ Causes Section (optional)
│  └─ List of causes with icons
│
├─ Treatments Section (optional)
│  └─ List of treatments with icons
│
└─ Action Buttons
   ├─ "Book vet appointment" button
   └─ "Track [Disease]" button


┌─────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT                              │
└─────────────────────────────────────────────────────────────────┘

LibraryPage State:
├─ _allDiseases: List<SkinDiseaseModel>
├─ _filteredDiseases: List<SkinDiseaseModel>
├─ _recentDiseases: List<SkinDiseaseModel>
├─ _categories: List<String>
├─ _isLoading: bool
├─ _selectedSpecies: String ('All', 'Cats', 'Dogs')
├─ _selectedCategory: String?
├─ _selectedDetectionMethod: String? ('ai' or null)
└─ _searchQuery: String

Methods:
├─ _loadData() - Fetch from service
├─ _applyFilters() - Filter diseases based on state
├─ _clearFilters() - Reset all filters
├─ _onSearchChanged(query) - Update search
├─ _onSpeciesChanged(species) - Update species filter
├─ _onCategorySelected(category) - Toggle category
├─ _onDetectionMethodToggled() - Toggle AI filter
└─ _navigateToDetail(disease) - Navigate to detail page


┌─────────────────────────────────────────────────────────────────┐
│                      THEMING                                     │
└─────────────────────────────────────────────────────────────────┘

Colors (AppColors):
├─ primary: #7C3AED (Purple) - Buttons, links, selections
├─ background: #F8F9FA (Light gray) - Page background
├─ white: #FFFFFF - Cards, containers
├─ textPrimary: #1A1D29 - Main text
├─ textSecondary: #6B7280 - Secondary text
├─ textTertiary: #9CA3AF - Tertiary text
├─ border: #F3F4F6 - Borders, dividers
├─ success: #10B981 - Low severity
├─ warning: #F59E0B - Moderate severity
└─ error: #EF4444 - High severity

Typography:
├─ Font Family: Poppins
├─ Title: 16px, weight 600
├─ Subtitle: 13px, weight 400
├─ Body: 14px, weight 400
└─ Caption: 11-12px, weight 500-600

Spacing (Mobile):
├─ Margin: 20px
├─ Padding: 16px
├─ Card spacing: 16px bottom
├─ Border radius: 12-16px
└─ Shadows: Subtle 0.06 opacity
```

This visual structure should help understand how all the components work together!
