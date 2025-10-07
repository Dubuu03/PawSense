# Dynamic FAQ Management System

## Overview

The PawSense FAQ management system has been completely revamped to be dynamic and role-based. Each clinic can now manage their own FAQs, and super admins can manage general app FAQs that are visible to all users.

## Features

### 1. **Role-Based FAQ Management**

#### Super Admin FAQs
- **Purpose**: General questions about the PawSense app
- **Visibility**: Visible to all users across all clinics
- **Management**: Only super admins can create, edit, and delete
- **Examples**:
  - How to use the AI disease detection feature
  - Account management questions
  - General app navigation

#### Clinic FAQs
- **Purpose**: Clinic-specific questions
- **Visibility**: Visible to patients of that specific clinic
- **Management**: Only the clinic admin can create, edit, and delete their own FAQs
- **Examples**:
  - Clinic-specific appointment booking procedures
  - Payment methods accepted by that clinic
  - Clinic hours and emergency contacts

### 2. **Complete CRUD Operations**

✅ **Create**: Add new FAQs with category, question, and detailed answer
✅ **Read**: View FAQs in an organized, expandable list
✅ **Update**: Edit existing FAQ content and publication status
✅ **Delete**: Remove FAQs with confirmation dialog

### 3. **Enhanced Features**

- **Categories**: Organize FAQs by category (General, Appointments, Emergency Care, Technology, Billing, Preventive Care, Services, Account)
- **View Tracking**: Track how many times each FAQ is viewed
- **Helpful Votes**: Users can mark FAQs as helpful
- **Publication Status**: Draft and publish FAQs (edit mode only)
- **Real-time Updates**: FAQs update in real-time using Firestore streams
- **Search & Filter**: Easy-to-use interface with categorization

## Architecture

### Models

**File**: `lib/core/models/support/faq_item_model.dart`

```dart
class FAQItemModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int views;
  final int helpfulVotes;
  final String? clinicId;        // null for super admin FAQs
  final bool isSuperAdminFAQ;    // true for general app FAQs
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;        // user ID who created
  final bool isPublished;
  final bool isExpanded;         // UI state
}
```

### Service Layer

**File**: `lib/core/services/support/faq_service.dart`

Key methods:
- `getClinicFAQs(String clinicId)` - Get FAQs for a specific clinic
- `getSuperAdminFAQs()` - Get general app FAQs
- `getFAQsForCurrentUser()` - Get FAQs based on user role
- `getPublicFAQs({String? clinicId})` - Get all public FAQs (super admin + clinic specific)
- `createFAQ()` - Create a new FAQ
- `updateFAQ()` - Update existing FAQ
- `deleteFAQ()` - Delete an FAQ
- `incrementViews()` - Track FAQ views
- `incrementHelpfulVotes()` - Track helpful votes
- `streamFAQsForCurrentUser()` - Real-time FAQ updates

### UI Components

#### 1. FAQ List (`faq_list.dart`)
- Displays all FAQs for the current admin
- Add new FAQ button
- Refresh functionality
- Empty state when no FAQs exist
- Edit and delete actions

#### 2. FAQ Item (`faq_item.dart`)
- Expandable FAQ card
- Category badge with color coding
- View and helpful vote counts
- Edit and delete buttons
- Smooth animations

#### 3. FAQ Management Modal (`faq_management_modal.dart`)
- Create/Edit FAQ form
- Category selection dropdown
- Question and answer text fields
- Publication status toggle (edit mode)
- Form validation
- Loading states

## Firestore Structure

### Collection: `faqs`

```javascript
{
  id: string,                    // Auto-generated document ID
  question: string,              // FAQ question
  answer: string,                // Detailed answer
  category: string,              // Category name
  views: number,                 // View count
  helpfulVotes: number,          // Helpful votes count
  clinicId: string?,             // null for super admin FAQs
  isSuperAdminFAQ: boolean,      // true for general app FAQs
  createdAt: string,             // ISO 8601 timestamp
  updatedAt: string?,            // ISO 8601 timestamp
  createdBy: string,             // User ID who created
  isPublished: boolean           // Publication status
}
```

### Indexes Needed

For optimal performance, create these composite indexes in Firestore:

1. **Super Admin FAQs**
   ```
   Collection: faqs
   Fields: isSuperAdminFAQ (Ascending), isPublished (Ascending), createdAt (Descending)
   ```

2. **Clinic FAQs**
   ```
   Collection: faqs
   Fields: clinicId (Ascending), isPublished (Ascending), createdAt (Descending)
   ```

## Security Rules

**File**: `firestore.rules`

```javascript
match /faqs/{faqId} {
  // Anyone can read published FAQs
  allow read: if resource.data.isPublished == true;
  
  // Super admins can create super admin FAQs, admins can create clinic FAQs
  allow create: if request.auth != null && 
                  (request.resource.data.isSuperAdminFAQ == true && 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin') ||
                  (request.resource.data.isSuperAdminFAQ == false && 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
  
  // Only creators can update/delete their own FAQs
  allow update, delete: if request.auth != null && 
                          ((resource.data.isSuperAdminFAQ == true && 
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin') ||
                           (resource.data.isSuperAdminFAQ == false && 
                            resource.data.clinicId == request.auth.uid && 
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
}
```

## Usage Guide

### For Super Admins

1. **Navigate** to Support Center
2. **Click** on "FAQ Management" tab
3. **Click** "Add FAQ" button
4. **Fill in**:
   - Category (dropdown)
   - Question (minimum 10 characters)
   - Answer (minimum 20 characters)
5. **Click** "Create FAQ"

Your FAQ will be visible to all users across all clinics.

### For Clinic Admins

1. **Navigate** to Support Center
2. **Click** on "FAQ Management" tab
3. **Click** "Add FAQ" button
4. **Fill in**:
   - Category (dropdown)
   - Question (minimum 10 characters)
   - Answer (minimum 20 characters)
5. **Click** "Create FAQ"

Your FAQ will be visible only to your clinic's patients.

### Editing FAQs

1. **Expand** the FAQ you want to edit
2. **Click** the "Edit" button
3. **Modify** the fields as needed
4. **Toggle** "Published" status if you want to unpublish
5. **Click** "Update FAQ"

### Deleting FAQs

1. **Expand** the FAQ you want to delete
2. **Click** the "Delete" button
3. **Confirm** deletion in the dialog
4. FAQ will be permanently removed

## For End Users (Mobile App)

To display FAQs to end users in the mobile app, use:

```dart
// Get both super admin and clinic-specific FAQs
final faqs = await FAQService.getPublicFAQs(clinicId: currentClinicId);

// Or just super admin FAQs
final generalFAQs = await FAQService.getSuperAdminFAQs();

// Or just clinic FAQs
final clinicFAQs = await FAQService.getClinicFAQs(clinicId);
```

## Benefits

### 1. **Scalability**
- Each clinic can maintain their own FAQ library
- No hardcoded FAQ data
- Easy to add new FAQs without app updates

### 2. **Flexibility**
- Clinic-specific answers to common questions
- Super admin can provide general guidance
- Categories keep FAQs organized

### 3. **User Experience**
- Users see relevant FAQs for their clinic
- Plus general app FAQs for overall guidance
- Helpful voting helps surface best answers

### 4. **Management**
- Simple interface for admins
- No technical knowledge required
- Real-time updates reflected immediately

### 5. **Analytics Ready**
- View counts help identify popular questions
- Helpful votes show FAQ quality
- Can be extended with user feedback

## Future Enhancements

### Potential Features
- 🔍 **Search Functionality**: Search through FAQ questions and answers
- 📊 **Analytics Dashboard**: View FAQ engagement metrics
- 🌐 **Multi-language Support**: Translate FAQs for different languages
- 📱 **Mobile Management**: Allow FAQ management from mobile app
- 💬 **User Suggestions**: Let users suggest new FAQ topics
- 🏷️ **Tags**: Add tags for better organization
- 📧 **Email Integration**: Email FAQ links to users
- 📱 **Push Notifications**: Notify users of new FAQs
- 🔔 **User Feedback**: Collect detailed feedback on FAQs
- 📈 **Trending FAQs**: Surface most viewed/helpful FAQs

## Testing Checklist

### Super Admin Tests
- [ ] Create a super admin FAQ
- [ ] Edit super admin FAQ
- [ ] Delete super admin FAQ
- [ ] Verify super admin FAQs show "General App FAQs" header
- [ ] Confirm clinic admins cannot edit super admin FAQs

### Clinic Admin Tests
- [ ] Create a clinic-specific FAQ
- [ ] Edit clinic FAQ
- [ ] Delete clinic FAQ
- [ ] Verify clinic FAQs show "Clinic FAQs" header
- [ ] Confirm other clinic admins cannot see/edit your FAQs
- [ ] Confirm clinic admins cannot create super admin FAQs

### End User Tests
- [ ] View super admin FAQs
- [ ] View clinic-specific FAQs
- [ ] Expand/collapse FAQ items
- [ ] Verify view count increments
- [ ] Mark FAQ as helpful

### Security Tests
- [ ] Unauthenticated users cannot create FAQs
- [ ] Users cannot edit FAQs they don't own
- [ ] Users cannot delete FAQs they don't own
- [ ] Role validation works correctly

## Troubleshooting

### FAQs Not Loading

1. **Check Firestore connection**
   ```dart
   // Enable Firestore debug logging
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

2. **Verify user authentication**
   ```dart
   final user = await AuthGuard.getCurrentUser();
   print('Current user: ${user?.uid}, role: ${user?.role}');
   ```

3. **Check Firestore indexes**
   - Look for index creation links in console
   - Click links to create required indexes

### Cannot Create FAQ

1. **Verify user role**
   - Super admin for super admin FAQs
   - Admin role for clinic FAQs

2. **Check form validation**
   - Question minimum 10 characters
   - Answer minimum 20 characters

3. **Review Firestore rules**
   - Ensure rules are deployed
   - Check for syntax errors

### FAQs Not Showing for Users

1. **Check `isPublished` field**
   - Must be `true` for FAQ to be visible

2. **Verify `clinicId` matching**
   - For clinic FAQs, ensure correct clinic ID

3. **Check security rules**
   - Published FAQs should be publicly readable

## Deployment

1. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Create Firestore Indexes**
   - Go to Firebase Console
   - Navigate to Firestore > Indexes
   - Create composite indexes as specified above
   - Or wait for auto-generated index links in console

3. **Test in Production**
   - Create test FAQs
   - Verify visibility
   - Test all CRUD operations

## Summary

The dynamic FAQ system provides a powerful, flexible solution for managing frequently asked questions. Super admins can maintain general app guidance, while each clinic can provide personalized answers to their patients' specific questions. The system is secure, scalable, and easy to use, with a clean interface that requires no technical knowledge to operate.

---

**Created**: 2025-01-07  
**Last Updated**: 2025-01-07  
**Version**: 1.0.0
