# Specializations Super Admin - Quick Testing Checklist

## ✅ Pre-Test Setup
- [ ] Have super admin account ready
- [ ] Have regular admin account ready
- [ ] Clear any existing specializations in Firestore (optional)

---

## 🔐 Super Admin Tests

### Test 1: Access Screen
- [ ] Log in as super admin
- [ ] Click "Specializations" in sidebar (should be between "Skin Diseases" and "Model Training")
- [ ] Screen loads with title "Specializations Management"
- [ ] See 3 statistics cards: Total, Active, Inactive (all showing 0 if fresh)

### Test 2: Seed Button - First Time
- [ ] Click green "Seed Defaults" button
- [ ] Confirmation dialog appears with warning icon
- [ ] Dialog shows: "15 default veterinary specializations"
- [ ] Click "Seed Data"
- [ ] Button shows "Seeding..." with spinner
- [ ] Green success snackbar: "Successfully seeded default specializations"
- [ ] List shows 15 specializations
- [ ] Statistics: Total=15, Active=15, Inactive=0

### Test 3: Seed Button - Duplicate Prevention
- [ ] Click "Seed Defaults" again
- [ ] Confirm seeding
- [ ] Success message appears
- [ ] Total still shows 15 (no duplicates)
- [ ] Check Firestore: Collection `predefinedSpecializations` has exactly 15 docs

### Test 4: Search Functionality
- [ ] Type "surgery" in search box
- [ ] Only "Surgery" specialization appears
- [ ] Clear search box
- [ ] All 15 specializations appear again
- [ ] Try "derma" → Shows "Dermatology"
- [ ] Try "xyz" → Shows empty state message

### Test 5: Add New Specialization
- [ ] Click blue "Add Specialization" button
- [ ] Dialog opens with form
- [ ] Try submitting empty → Validation errors
- [ ] Enter name: "Behavioral Medicine"
- [ ] Enter description: "Animal behavior and psychology"
- [ ] Click "Add"
- [ ] Success snackbar appears
- [ ] New specialization appears in list
- [ ] Statistics: Total=16, Active=16
- [ ] Badge shows "Active" (green)

### Test 6: Edit Specialization
- [ ] Find "Behavioral Medicine" 
- [ ] Click blue edit icon
- [ ] Dialog opens with pre-filled values
- [ ] Change description to "Veterinary behavioral science"
- [ ] Click "Update"
- [ ] Success snackbar appears
- [ ] Description updated in list

### Test 7: Toggle Active/Inactive
- [ ] Find "Behavioral Medicine"
- [ ] Switch is ON (green)
- [ ] Click toggle switch
- [ ] Badge changes to "Inactive" (orange/yellow)
- [ ] Statistics: Active=15, Inactive=1
- [ ] Toggle back ON
- [ ] Badge changes to "Active" (green)
- [ ] Statistics: Active=16, Inactive=0

### Test 8: Delete Specialization
- [ ] Find "Behavioral Medicine"
- [ ] Click red delete icon
- [ ] Confirmation dialog appears
- [ ] Click "Cancel" → Nothing happens
- [ ] Click delete again
- [ ] Click "Delete"
- [ ] Success snackbar appears
- [ ] Specialization removed from list
- [ ] Statistics: Total=15, Active=15

---

## 👨‍⚕️ Regular Admin Tests

### Test 9: Cannot Access Management
- [ ] Log in as regular admin
- [ ] Check sidebar → "Specializations" NOT present
- [ ] Try URL `/super-admin/specializations` directly
- [ ] Should redirect to `/admin/dashboard` (auth guard)

### Test 10: Settings No Longer Has Specializations
- [ ] Navigate to Settings
- [ ] Check sidebar navigation
- [ ] Only see: Account, Clinic, Security, Legal Documents
- [ ] "Specializations" tab is gone

### Test 11: Can Still Add to Vet Profile
- [ ] Navigate to Vet Profile
- [ ] Scroll to Specializations section
- [ ] Click "Add Specialization"
- [ ] Modal opens
- [ ] Dropdown has all 15 default specializations
- [ ] Select "Small Animal Medicine"
- [ ] Choose level "Advanced"
- [ ] Check "Has Certification"
- [ ] Upload certificate UI appears
- [ ] Choose certificate image
- [ ] Preview shows
- [ ] Click "Add"
- [ ] Loading state appears
- [ ] Badge appears in profile with certificate

### Test 12: Active/Inactive Filter Works
- [ ] As super admin, mark "Surgery" as Inactive
- [ ] Log in as regular admin
- [ ] Go to Vet Profile → Add Specialization
- [ ] Open dropdown
- [ ] "Surgery" should NOT appear in list
- [ ] Only active specializations (14) visible

---

## 🐛 Edge Cases

### Test 13: Error Handling
- [ ] Disconnect internet
- [ ] Try adding specialization
- [ ] Error snackbar appears
- [ ] Reconnect internet
- [ ] Try again → Works

### Test 14: Empty State
- [ ] As super admin, delete all specializations
- [ ] See empty state with icon and message
- [ ] Message suggests seeding or adding custom
- [ ] Click "Seed Defaults"
- [ ] 15 specializations restored

### Test 15: Long Names
- [ ] Add specialization with very long name (50+ chars)
- [ ] Verify card layout doesn't break
- [ ] Text wraps properly

---

## 📊 Verification Checklist

### Firestore Database
- [ ] Collection `predefinedSpecializations` exists
- [ ] Each document has: id, name, description, isActive, createdAt, updatedAt
- [ ] All default specializations have isActive: true
- [ ] Timestamps are ISO strings

### UI Components
- [ ] Statistics cards update in real-time
- [ ] Search is case-insensitive
- [ ] Buttons have proper loading states
- [ ] Confirmation dialogs work
- [ ] Snackbars show/hide correctly
- [ ] Icons display properly

### Navigation
- [ ] Super admin sidebar shows "Specializations"
- [ ] Regular admin sidebar does NOT show "Specializations"
- [ ] Direct URL access blocked for regular admins
- [ ] Routes work without page reload

---

## ✅ Success Criteria

All tests pass if:
1. ✅ Super admin can manage specializations (CRUD + seed)
2. ✅ Regular admin can select specializations (read-only)
3. ✅ Seeding works from UI (no terminal needed)
4. ✅ Active/inactive toggle affects admin dropdown
5. ✅ No duplicate data created
6. ✅ Error handling works
7. ✅ Navigation properly restricted
8. ✅ UI is responsive and bug-free

---

## 🚨 Common Issues

### Issue: Dropdown Empty in Admin
**Cause**: All specializations marked inactive  
**Fix**: Super admin marks at least one as active

### Issue: Seeding Button Doesn't Work
**Cause**: Firestore permissions or network error  
**Fix**: Check Firestore rules, check console errors

### Issue: Can't Access Super Admin Screen
**Cause**: Not logged in as super admin  
**Fix**: Check user role in Firebase Authentication custom claims

### Issue: Duplicates After Seeding
**Cause**: Should not happen (duplicate check exists)  
**Fix**: Report as bug, clear Firestore and re-seed

---

**Testing Complete When**: All 15 tests pass ✅
