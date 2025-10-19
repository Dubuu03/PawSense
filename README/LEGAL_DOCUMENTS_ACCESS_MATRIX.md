# Legal Documents Access Matrix

## Quick Reference: Who Can Do What?

| Action | Super Admin | Clinic Admin | Mobile User |
|--------|-------------|--------------|-------------|
| **View Active Documents** | ✅ Yes | ✅ Yes | ✅ Yes |
| **View Inactive Documents** | ✅ Yes | ❌ No | ❌ No |
| **Create Documents** | ✅ Yes | ❌ No | ❌ No |
| **Edit Documents** | ✅ Yes | ❌ No | ❌ No |
| **Delete Documents** | ❌ No* | ❌ No | ❌ No |
| **Activate/Deactivate** | ✅ Yes | ❌ No | ❌ No |
| **View Version History** | ✅ Yes | ❌ No | ❌ No |
| **Search Documents** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Accept Terms (Sign-up)** | N/A | N/A | ✅ Required |

*Delete removed by design for data integrity

---

## Access Locations

### **Super Admin**
📍 **Location:** System Settings → Legal Documents Tab
- Full management interface
- Create, edit, activate/deactivate
- Version history tracking
- Manage all document types

### **Clinic Admin (Web)**
📍 **Location:** Settings → Legal Documents
- Read-only viewer
- Active documents only
- Document search
- View content in modal

### **Mobile Users**
📍 **Locations:**
1. Sign-up flow (Terms & Conditions - required acceptance)
2. Legal Documents Page (all active documents)
3. Settings menu (quick access)
- View and accept
- Scroll detection
- Version info displayed

---

## Document Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      FIRESTORE                               │
│                 legal_documents collection                   │
└─────────────────────────────────────────────────────────────┘
                            ↑ ↓
              ┌─────────────┴──────────────┐
              │                             │
    ┌─────────▼─────────┐       ┌──────────▼──────────┐
    │   SUPER ADMIN      │       │   CLINIC ADMIN      │
    │                    │       │                     │
    │  • Create ✏️       │       │  • View 👁️         │
    │  • Edit ✏️         │       │  • Read 📖         │
    │  • Activate ✅     │       │  • Search 🔍       │
    │  • Deactivate ⏸️   │       │                     │
    │  • View All 📋     │       │  (Active Only)      │
    └────────────────────┘       └─────────────────────┘
                                           │
                                           ↓
                                 ┌─────────────────┐
                                 │  MOBILE USERS   │
                                 │                 │
                                 │  • View 👁️     │
                                 │  • Accept ✅    │
                                 │  • Read 📖     │
                                 │                 │
                                 │  (Active Only)  │
                                 └─────────────────┘
```

---

## UI Comparison

### **Super Admin - Legal Documents Tab**
```
┌──────────────────────────────────────────────────────────┐
│ Legal Documents                    [Search] [+ Create]   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ ● Terms and Conditions [ACTIVE]                 │    │
│  │   Version 1.0                                    │    │
│  │   Last updated: Oct 17, 2025          [🕐][✏️][⏯️] │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ ● Privacy Policy [INACTIVE]                     │    │
│  │   Version 2.3                                    │    │
│  │   Last updated: Oct 10, 2025          [🕐][✏️][⏯️] │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└──────────────────────────────────────────────────────────┘

Actions Available:
🕐 = View History
✏️ = Edit Document  
⏯️ = Toggle Active/Inactive
```

### **Clinic Admin - Legal Documents Settings**
```
┌──────────────────────────────────────────────────────────┐
│ Legal Documents                             [Search]     │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ℹ️ These documents are managed by Super Admin.          │
│     You can view active versions that apply to clinic.   │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ ● Terms and Conditions [ACTIVE]                 │    │
│  │   Version 1.0                                    │    │
│  │   Last updated: Oct 17, 2025                [👁️] │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  (Only ACTIVE documents shown)                           │
│                                                           │
└──────────────────────────────────────────────────────────┘

Actions Available:
👁️ = View Document (Read-only)
```

### **Mobile - Legal Documents Page**
```
┌─────────────────────────────────────┐
│ ← Legal Documents                   │
├─────────────────────────────────────┤
│                                     │
│  ℹ️ Legal Information               │
│     View our policies               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🐾 Terms and Conditions    → │ │
│  │    Review our terms...         │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🔒 Privacy Policy          → │ │
│  │    Learn how we protect...     │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📋 User Agreement          → │ │
│  │    Understand your rights...   │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘

Tap card to view in modal
```

---

## Permission Logic

### **Super Admin**
```typescript
if (role === 'superadmin') {
  permissions = {
    view: ALL_DOCUMENTS,    // Active + Inactive
    create: true,
    edit: true,
    delete: false,          // Removed by design
    toggleStatus: true,
    viewHistory: true,
  };
}
```

### **Clinic Admin**
```typescript
if (role === 'admin') {
  permissions = {
    view: ACTIVE_ONLY,      // Active documents only
    create: false,
    edit: false,
    delete: false,
    toggleStatus: false,
    viewHistory: false,
  };
}
```

### **Mobile User**
```typescript
if (role === 'user') {
  permissions = {
    view: ACTIVE_ONLY,      // Active documents only
    accept: true,           // Can accept during sign-up
    create: false,
    edit: false,
    delete: false,
    toggleStatus: false,
    viewHistory: false,
  };
}
```

---

## Implementation Files

### **Super Admin**
```
lib/core/widgets/super_admin/system_settings/
├── legal_documents_tab.dart          (Full management)
└── edit_legal_document_modal.dart    (Create/Edit)
```

### **Clinic Admin**
```
lib/core/widgets/admin/settings/
└── legal_documents_settings.dart     (Read-only viewer)
```

### **Mobile**
```
lib/core/widgets/mobile/
└── legal_document_viewer.dart        (Reusable viewer)

lib/pages/mobile/auth/
└── legal_document_modal.dart         (Modal with acceptance)

lib/pages/mobile/
└── legal_documents_page.dart         (Standalone page)
```

---

## Data Structure (Shared)

All roles use the same data model:

```dart
class LegalDocumentModel {
  final String id;
  final String title;
  final String content;          // HTML content
  final String version;
  final DateTime lastUpdated;
  final String updatedBy;
  final bool isActive;           // Only active shown to non-super-admins
  final DocumentType type;       // termsAndConditions, privacyPolicy, etc.
}
```

---

## Search Capabilities

### **Super Admin**
Searches across:
- ✅ Document title
- ✅ Document type
- ✅ Version number
- ✅ Content text
- ✅ Active AND Inactive documents

### **Clinic Admin**
Searches across:
- ✅ Document title
- ✅ Document type
- ✅ Version number
- ✅ Active documents ONLY

### **Mobile**
Searches across:
- ✅ Document title
- ✅ Document type
- ✅ Active documents ONLY

---

## Version Control

### **Who Sees What Version?**

| Scenario | Super Admin | Clinic Admin | Mobile User |
|----------|-------------|--------------|-------------|
| Document has v1.0 (active) | ✅ Sees v1.0 | ✅ Sees v1.0 | ✅ Sees v1.0 |
| Document has v2.0 (inactive) | ✅ Sees v2.0 | ❌ Doesn't see | ❌ Doesn't see |
| v1.0 deactivated, v2.0 activated | ✅ Sees both | ✅ Sees v2.0 only | ✅ Sees v2.0 only |
| Version history | ✅ Full history | ❌ No access | ❌ No access |

---

## Update Workflow

### **When Super Admin Updates Terms:**

1. Super Admin creates new version (v2.0)
2. Sets new version as active
3. Old version (v1.0) auto-deactivates
4. **Clinic Admins** immediately see v2.0 in their settings
5. **Mobile Users** see v2.0 next time they access
6. Old version still in database for audit trail

```
Timeline:
09:00 AM → Super Admin creates v2.0
09:01 AM → Super Admin activates v2.0
09:01 AM → v1.0 automatically deactivated
09:02 AM → Clinic Admin refreshes, sees v2.0
09:05 AM → Mobile user opens app, sees v2.0
```

---

## Best Practice: When to Use Each View

### **Use Super Admin Legal Documents When:**
- Creating new platform-wide policies
- Updating existing terms
- Managing multiple versions
- Activating specific versions
- Reviewing version history
- Compliance audits

### **Use Clinic Admin Legal Documents When:**
- Reference current platform terms
- Training new staff on policies
- Answering policy questions
- Understanding clinic obligations
- Checking for policy updates

### **Use Mobile Legal Documents When:**
- User sign-up (required acceptance)
- Viewing policies from app
- Checking terms before actions
- Understanding user rights
- Quick reference access

---

## Summary

**One Source, Three Views:**

1. **Super Admin** = Management Interface (Full Control)
2. **Clinic Admin** = Information Interface (Read-Only)
3. **Mobile User** = Acceptance Interface (View + Accept)

**Same Data, Different Purposes:**
- Super Admin: Creates and manages
- Clinic Admin: Stays informed
- Mobile User: Views and accepts

**Result:**
- ✅ No content duplication
- ✅ Single source of truth
- ✅ Consistent across platform
- ✅ Role-appropriate access
- ✅ Easy to maintain
